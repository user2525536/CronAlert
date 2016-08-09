; COPYRIGHT
; ---------
; 
; CronAlert Copyright (c) 2016 pcfreak
; 
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in
;    the documentation and/or other materials provided with the
;    distribution.
; 3. Free for personal and educational use only.
; 4. Contact pcfreak for commercial use.
;    This includes but is not limited to the use in or with advertises.
; 5. The names of the contributors may not be used to endorse or promote
;    products derived from this software without specific prior written
;    permission.
; 
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS, AUTHORS, AND
;  CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
;  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
;  IN NO EVENT SHALL PCFREAK OR ANY AUTHORS OR CONTRIBUTORS BE
;  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
;  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
;  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

XIncludeFile "TextToSpeech.pbi"
XIncludeFile "Utility.pbi"


Enumeration ; Windows
	#WID_Main
EndEnumeration


Enumeration ; Gadgets
 	#GID_CurrentTimeLabel
 	#GID_CurrentTimeValue
 	#GID_AlertList
EndEnumeration


Enumeration ; AlertList columns
	#CID_AlertList_Checked
	#CID_AlertList_ETA
	#CID_AlertList_Name
	#CID_AlertList_Text
EndEnumeration


Enumeration ; Statusbars
 	#SBID_Main
EndEnumeration


Enumeration ; Menus
 	#MID_Main
 	#MID_SysTray
EndEnumeration


Enumeration ; Menu Items
 	#MIID_Open
 	#MIID_Close
 	#MIID_OpenLastFile
 	#MIID_OpenLastFileOnStart
 	#MIID_ReloadOnChange
 	#MIID_Exit
 	#MIID_VolumeCheck
 	#MIID_Mute
 	#MIID_About
EndEnumeration


Enumeration 1 ; Timers
 	#TID_Refresh
EndEnumeration


Enumeration ; SysTray Icons
 	#STID_Main
EndEnumeration


EnumerationBinary ; User Configuration Window States
	#UCWS_Normal
	#UCWS_Maximized
	#UCWS_Hidden
EndEnumeration


#PathSep = "\"
#WinMinWidth = 320
#WinMinHeight = 240
#MinUpdateInterval = 5 ; seconds
#ConfigFileVersion1 = $CA000001
#ConfigFileVersion = #ConfigFileVersion1
#Version = "1.1.3"


Declare.i MainWindowLoadUserConfig()
Declare.i MainWindowSaveUserConfig()
Declare.i MainWindowUpdateSizes()
Declare.i MainWindowUpdateMenus()
Declare.i MainWindowResizeGadgets()
Declare.i MainWindowUpdateAlertMaskToTime(now.i, offset.i, wday.i, month.i, day.i, hour.i, min.i)
Declare.i MainWindowUpdateAlertEta(now.i, limit.i, wday.i, month.i, day.i, hour.i, min.i)
Declare.i MainWindowUpdateAlertEtaMins(now.i, limit.i, wday.i, month.i, day.i, hour.i)
Declare.i MainWindowUpdateAlertEtaHours(now.i, limit.i, wday.i, month.i, day.i)
Declare.i MainWindowUpdateAlertEtaDays(now.i, limit.i, wday.i, month.i)
Declare.i MainWindowUpdateAlertEtaMonths(now.i, limit.i, wday.i)
Declare.i MainWindowUpdateAlertEtaWDays(now.i)
Declare.i MainWindowRefresh()
Declare.i MainWindowCallback(hWnd.i, uMsg.i, wParam.i, lParam.i)
Declare.i MainWindowUpdateCronAlert(force.i = #False)
Declare.i MainWindowLoadCronAlert(file.s)
Declare.i MainWindowCloseCronAlert()
Declare.i MainWindowCleanUp()


Global.i windowXDif, windowYDif, lastWinX, lastWinY, lastWinW, lastWinH
Global.i WM_TASKBARCREATED
Global.s mainWindowTitle = "CronAlert"
Global.s nextEvent = "", nextEta = "", clParam
Global.i icon = FileIcon(ProgramFilename(), #True)
Global.i isMuted = #False, mainWindowIsHidden = #False, loadLastFile = #False
Global.s openFile = ProgramFilename(), openFileMd5 = ""
Global.s lastOpenFile = ""
Global.i hasOpenFile = #False, openFileModDate = 0, hasLastFile = #False, reloadOnChange = #True, fileWasChanged = #False
Global.i iconAudio, iconAudioAlert, iconCommand
Define.s file
Define.i i


iconAudio = CatchImage(#PB_Any, ?IconDataAudio)
iconAudioAlert = CatchImage(#PB_Any, ?IconDataAudioAlert)
iconCommand = CatchImage(#PB_Any, ?IconDataCommand)
UseMD5Fingerprint()


;- Main
If OpenWindow(#WID_Main, 0, 0, 320, 240, mainWindowTitle, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered | #PB_Window_Invisible)
	If CreateMenu(#MID_Main, WindowID(#WID_Main))
		MenuTitle("&File")
		MenuItem(#MIID_Open, "&Open")
		MenuItem(#MIID_OpenLastFile, "Open l&ast file")
		MenuItem(#MIID_Close, "&Close")
		MenuBar()
		MenuItem(#MIID_OpenLastFileOnStart, "Open &last file on start")
		MenuItem(#MIID_ReloadOnChange, "&Reload on change")
		MenuBar()
		MenuItem(#MIID_Exit, "&Exit")
		MenuTitle("&Sound")
		MenuItem(#MIID_VolumeCheck, "&Volume check")
		MenuItem(#MIID_Mute, "&Mute")
		MenuTitle("&Help")
		MenuItem(#MIID_About, "&About")
	EndIf
	If CreatePopupMenu(#MID_SysTray)
		MenuItem(#MIID_Mute, "&Mute")
		MenuBar()
		MenuItem(#MIID_Exit, "&Exit")
	EndIf
	If CreateStatusBar(#SBID_Main, WindowID(#WID_Main))
		AddStatusBarField(80)
		AddStatusBarField(100)
		AddStatusBarField(40)
		AddStatusBarField(100)
		StatusBarText(#SBID_Main, 0, "Next events:", #PB_StatusBar_BorderLess)
		StatusBarText(#SBID_Main, 2, "ETA:", #PB_StatusBar_BorderLess)
	EndIf
	TextGadget(#GID_CurrentTimeLabel, 10, 13, 80, 14, "Current Time:")
	StringGadget(#GID_CurrentTimeValue, 90, 13, 120, 14, "", #PB_String_BorderLess | #PB_String_ReadOnly)
	ListIconGadget(#GID_AlertList, 0, 40, 320, 200 - MenuHeight() - StatusBarHeight(#SBID_Main), "Type", 40, #PB_ListIcon_CheckBoxes | #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #LVS_EX_FLATSB)
	AddGadgetColumn(#GID_AlertList, #CID_AlertList_ETA, "ETA", 60)
	AddGadgetColumn(#GID_AlertList, #CID_AlertList_Name, "name", 70)
	AddGadgetColumn(#GID_AlertList, #CID_AlertList_Text, "text", 130)
	AddSysTrayIcon(#STID_Main, WindowID(#WID_Main), icon)
Else
	MessageRequester("Error", "Failed to create window.", #PB_MessageRequester_Ok | #MB_ICONERROR)
	ExitProgram()
EndIf


GetWindowRect_(WindowID(#WID_Main), winRect.rect)
windowXDif = winRect\right - winRect\left - WindowWidth(#WID_Main)
windowYDif = winRect\bottom - winRect\top - WindowHeight(#WID_Main)

EnableWindowDrop(#WID_Main, #PB_Drop_Files, #PB_Drag_Copy)
SetWindowCallback(@MainWindowCallback())
MainWindowResizeGadgets()
MainWindowRefresh()
; AddWindowTimer() does not work while we are processing window events
SetTimer_(WindowID(#WID_Main), #TID_Refresh, 500, #Null)

WM_TASKBARCREATED = RegisterWindowMessage_("TaskbarCreated")

TextToSpeech::Initialize()

; handle user settings
MainWindowLoadUserConfig()

;- Command-line processor
For i = 0 To CountProgramParameters() - 1
	clParam = ProgramParameter(i)
	Select LCase(clParam)
	Case "-h", "/h", "/?", "--help", "/help"
		clParam = ~"CronAlert -ht [file]\n\n"
		clParam + ~" -h, --help\n"
		clParam + ~"     Display this help.\n"
		clParam + ~" -m, --mute\n"
		clParam + ~"     Mute audio outputs.\n"
		clParam + ~" -t, --tray\n"
		clParam + ~"     Start hidden in systray mode.\n"
		clParam + ~"\n"
		clParam + ~"file\n"
		clParam + ~"     Open this file on start-up.\n"
		MessageRequester("Command-line options", clParam, #PB_MessageRequester_Ok | #MB_ICONINFORMATION)
		ExitProgram()
	Case "-m", "/m", "--mute", "/mute"
		isMuted = #True
	Case "-t", "/t", "--tray", "/tray"
		mainWindowIsHidden = #True
	Default
		If i >= CountProgramParameters() - 1
			If Mid(clParam, 1, 1) = ~"\""
				clParam = Mid(clParam, 2, Len(clParam) - 2)
			EndIf
			openFile = clParam
			hasOpenFile = #True
		Else
			MessageRequester("Error", "Unknown program option '" + clParam + "'.", #PB_MessageRequester_Ok | #MB_ICONERROR)
			ExitProgram()
		EndIf
	EndSelect
	clParam = ProgramParameter()
Next

If hasOpenFile And openFile <> ""
	MainWindowLoadCronAlert(openFile)
EndIf

MainWindowUpdateMenus()
CheckWindowPosition(#WID_Main)

AtExit(@MainWindowCleanUp())

HideWindow(#WID_Main, mainWindowIsHidden)


;- Event Loop
Repeat
	Select WaitWindowEvent()
	Case #PB_Event_Gadget
		Select EventGadget()
		Case #GID_AlertList
			Select EventType()                   
			Case #PB_EventType_Change
				ForEach alerts()
					If GetGadgetItemState(#GID_AlertList, ListIndex(alerts())) & #PB_ListIcon_Checked = #PB_ListIcon_Checked
						i = #True
					Else
						i = #False
					EndIf
					If i <> alerts()\enabled
						fileWasChanged = #True
						SetWindowTitle(#WID_Main, mainWindowTitle + " - " + openFile + "*")
						i = alerts()\enabled
					EndIf
				Next
			EndSelect
		EndSelect
	Case #PB_Event_Menu
		Select EventMenu()
		Case #MIID_Open
			file = OpenFileRequester("Choose CronAlert file.", GetPathPart(openFile), "CronAlert file (*.ca)|*.ca", 0)
			If FileSize(file) > 0
				MainWindowLoadCronAlert(file)
			EndIf
		Case #MIID_Close
			MainWindowCloseCronAlert()
		Case #MIID_OpenLastFile
			If lastOpenFile <> ""
				MainWindowLoadCronAlert(lastOpenFile)
			EndIf
		Case #MIID_OpenLastFileOnStart
			If loadLastFile
				loadLastFile = #False
			Else
				loadLastFile = #True
			EndIf
			SetMenuItemState(#MID_Main, #MIID_OpenLastFileOnStart, loadLastFile)
		Case #MIID_ReloadOnChange
			If reloadOnChange
				reloadOnChange = #False
			Else
				reloadOnChange = #True
			EndIf
			SetMenuItemState(#MID_Main, #MIID_ReloadOnChange, reloadOnChange)
		Case #MIID_Exit
			TextToSpeech::DeInitialize()
			ExitProgram()
		Case #MIID_VolumeCheck
			TextToSpeech::Speak("this is a volume check")
		Case #MIID_Mute
			If isMuted
				isMuted = #False
			Else
				isMuted = #True
			EndIf
			SetMenuItemState(#MID_Main, #MIID_Mute, isMuted)
			SetMenuItemState(#MID_SysTray, #MIID_Mute, isMuted)
		Case #MIID_About
			MessageRequester("About", "CronAlert " + #Version+ ~"\n\n© Copyright 2016 pcfreak", #PB_MessageRequester_Ok | #MB_ICONINFORMATION)
		EndSelect
	Case #PB_Event_WindowDrop
		Select EventDropType()
		Case #PB_Drop_Files
			file = StringField(EventDropFiles(), 1, Chr(10))
			If FileSize(file) > 0
				MainWindowLoadCronAlert(file)
			EndIf
		EndSelect
	Case #PB_Event_SysTray
		Select EventType()
		Case #PB_EventType_RightClick
			DisplayPopupMenu(#MID_SysTray, WindowID(#WID_Main))
		Case #PB_EventType_LeftClick
			If mainWindowIsHidden
				mainWindowIsHidden = #False
			Else
				mainWindowIsHidden = #True
			EndIf
			HideWindow(#WID_Main, mainWindowIsHidden)
			If Not mainWindowIsHidden
				StickyWindow(#WID_Main, #True)
				SetActiveWindow(#WID_Main)
				StickyWindow(#WID_Main, #False)
			EndIf
		EndSelect
	Case #PB_Event_CloseWindow
		ExitProgram()
	EndSelect
ForEver


;- Functions
; Loads the user configuration.
Procedure.i MainWindowLoadUserConfig()
	Protected.s lastFile
	Protected.i fileId, version, winState, winX, winY, winW, winH
	If FileSize(GetUserConfigPath() + #UserConfig) < 0
		;MessageRequester("Error", ~"User configuration file not found.\n" + GetUserConfigPath() + #UserConfig, #PB_MessageRequester_Ok | #MB_ICONERROR)
		ProcedureReturn
	EndIf
	If FileSize(GetUserConfigPath() + #UserConfig) < 25
		MessageRequester("Error", ~"Invalid user configuration file format.\n" + GetUserConfigPath() + #UserConfig, #PB_MessageRequester_Ok | #MB_ICONERROR)
		ProcedureReturn
	EndIf
	fileId = ReadFile(#PB_Any, GetUserConfigPath() + #UserConfig)
	If IsFile(fileId)
		version = BSwap32(ReadLong(fileId) & $FFFFFFFF)
		If version = #ConfigFileVersion1
			winState = ReadLong(fileId) & $FFFFFFFF
			winX = ReadLong(fileId) & $FFFFFFFF
			winY = ReadLong(fileId) & $FFFFFFFF
			winW = ReadLong(fileId) & $FFFFFFFF
			winH = ReadLong(fileId) & $FFFFFFFF
			SendMessage_(GadgetID(#GID_AlertList), #LVM_SETCOLUMNWIDTH, #CID_AlertList_Checked, ReadLong(fileId) & $FFFFFFFF)
			SendMessage_(GadgetID(#GID_AlertList), #LVM_SETCOLUMNWIDTH, #CID_AlertList_ETA, ReadLong(fileId) & $FFFFFFFF)
			SendMessage_(GadgetID(#GID_AlertList), #LVM_SETCOLUMNWIDTH, #CID_AlertList_Name, ReadLong(fileId) & $FFFFFFFF)
			SendMessage_(GadgetID(#GID_AlertList), #LVM_SETCOLUMNWIDTH, #CID_AlertList_Text, ReadLong(fileId) & $FFFFFFFF)
			loadLastFile = ReadByte(fileId) & $FF
			reloadOnChange = ReadByte(fileId) & $FF
			lastFile = ReadStringL(fileId)
			openFile = lastFile ; remember last file as open file to handle open file dialog path correctly
			ResizeWindow(#WID_Main, winX, winY, winW, winH)
			If winState & #UCWS_Hidden = #UCWS_Hidden
				mainWindowIsHidden = #True
			Else
				If winState & #UCWS_Maximized = #UCWS_Maximized
					SetWindowState(#WID_Main, #PB_Window_Maximize)
				Else
					SetWindowState(#WID_Main, #PB_Window_Normal)
				EndIf
				mainWindowIsHidden = #False
			EndIf
			HideWindow(#WID_Main, mainWindowIsHidden)
			If loadLastFile = #True And openFile <> ""
				hasOpenFile = #True
			EndIf
			MainWindowUpdateSizes()
			MainWindowResizeGadgets()
		EndIf
		CloseFile(fileId)
	Else
		MessageRequester("Error", "Failed to read user configuration file.\n" + GetUserConfigPath() + #UserConfig, #PB_MessageRequester_Ok | #MB_ICONERROR)
	EndIf
	ProcedureReturn
EndProcedure


; Saves the user configuration.
Procedure.i MainWindowSaveUserConfig()
	Protected.s path, part, item
	Protected.i fileId, winState
	path = GetUserConfigPath()
	If FileSize(path) <> -2
		; could not locate user configuration path
		ProcedureReturn
	EndIf
	; create path to user configuration file
	part = GetPathPart(#UserConfig)
	While part <> ""
		item = StringField(part, 1, #PathSep)
		If item <> ""
			path + item + #PathSep
			part = Right(part, Len(part) - Len(item) - Len(#PathSep))
		Else
			path + part
			part = ""
		EndIf
		If FileSize(path) <> -2
			If CreateDirectory(path) = 0
				MessageRequester("Error", "Failed to create path for user configuration.\n" + path, #PB_MessageRequester_Ok | #MB_ICONERROR)
				ProcedureReturn
			EndIf
		EndIf
	Wend
	; create user configuration file
	path + GetFilePart(#UserConfig)
	fileId = CreateFile(#PB_Any, path)
	If IsFile(fileId)
		winState = 0
		If GetWindowState(#WID_Main) = #PB_Window_Maximize
			winState | #UCWS_Maximized
		EndIf
		If mainWindowIsHidden = #True
			winState | #UCWS_Hidden
		EndIf
		WriteLong(fileId, BSwap32(#ConfigFileVersion))
		WriteLong(fileId, winState)
		WriteLong(fileId, lastWinX)
		WriteLong(fileId, lastWinY)
		WriteLong(fileId, lastWinW)
		WriteLong(fileId, lastWinH)
		WriteLong(fileId, SendMessage_(GadgetID(#GID_AlertList), #LVM_GETCOLUMNWIDTH, #CID_AlertList_Checked, 0))
		WriteLong(fileId, SendMessage_(GadgetID(#GID_AlertList), #LVM_GETCOLUMNWIDTH, #CID_AlertList_ETA, 0))
		WriteLong(fileId, SendMessage_(GadgetID(#GID_AlertList), #LVM_GETCOLUMNWIDTH, #CID_AlertList_Name, 0))
		WriteLong(fileId, SendMessage_(GadgetID(#GID_AlertList), #LVM_GETCOLUMNWIDTH, #CID_AlertList_Text, 0))
		WriteByte(fileId, loadLastFile)
		WriteByte(fileId, reloadOnChange)
		WriteStringL(fileId, lastOpenFile)
		CloseFile(fileId)
	Else
		MessageRequester("Error", "Failed to write user configuration file.\n" + path, #PB_MessageRequester_Ok | #MB_ICONERROR)
	EndIf
	ProcedureReturn
EndProcedure


; Updates the global variables for the window dimension.
; This is needed to store the correct values in the
; user configuration.
Procedure.i MainWindowUpdateSizes()
	If GetWindowState(#WID_Main) = #PB_Window_Normal
		lastWinX = WindowX(#WID_Main)
		lastWinY = WindowY(#WID_Main)
		lastWinW = WindowWidth(#WID_Main)
		lastWinH = WindowHeight(#WID_Main)
	EndIf
EndProcedure


; Update menu item states.
; This enables or disables item or changes their
; checked state according to the currently set
; global variables.
Procedure.i MainWindowUpdateMenus()
	If hasOpenFile
		DisableMenuItem(#MID_Main, #MIID_Close, #False)
	Else
		DisableMenuItem(#MID_Main, #MIID_Close, #True)
	EndIf
	If hasLastFile
		DisableMenuItem(#MID_Main, #MIID_OpenLastFile, #False)
	Else
		DisableMenuItem(#MID_Main, #MIID_OpenLastFile, #True)
	EndIf
	SetMenuItemState(#MID_Main, #MIID_OpenLastFileOnStart, loadLastFile)
	SetMenuItemState(#MID_Main, #MIID_ReloadOnChange, reloadOnChange)
	SetMenuItemState(#MID_Main, #MIID_Mute, isMuted)
	SetMenuItemState(#MID_SysTray, #MIID_Mute, isMuted)
EndProcedure


; Resize gadgets after the window was resized.
Procedure.i MainWindowResizeGadgets()
	ResizeGadget(#GID_CurrentTimeValue, #PB_Ignore, #PB_Ignore, WindowWidth(#WID_Main) - 100, #PB_Ignore)
	ResizeGadget(#GID_AlertList, #PB_Ignore, #PB_Ignore, WindowWidth(#WID_Main), WindowHeight(#WID_Main) - 40 - MenuHeight() - StatusBarHeight(#SBID_Main))
	SetStatusBarWidth(#SBID_Main, 0, 80)
	SetStatusBarWidth(#SBID_Main, 1, WindowWidth(#WID_Main) - 220)
	SetStatusBarWidth(#SBID_Main, 2, 40)
	SetStatusBarWidth(#SBID_Main, 3, 100)
	MainWindowUpdateSizes()
EndProcedure


; Convert the given cron alert values to a time timestamp.
; The given offset will be used to fill values that were
; defined as any. Increase offset one by one to find the
; next valid trigger.
; 
; @param[in] now - current time
; @param[in] offset - offset from now
; @param[in] month - trigger for month
; @param[in] wday - trigger for weekday
; @param[in] day - trigger for day of month
; @param[in] hour - trigger for hour
; @param[in] min - trigger for minute
; @return trigger date time or -1 on error
Procedure.i MainWindowUpdateAlertMaskToTime(now.i, offset.i, wday.i, month.i, day.i, hour.i, min.i)
	Protected.i result, year = Year(now)
	If min = -1
		min = Minute(now) + offset
		offset = Int(offset / 60)
		If min >= 60
			min % 60
			offset + 1
		EndIf
	EndIf
	If hour = -1
		hour = Hour(now) + offset
		offset = Int(offset / 24)
		If hour >= 24
			hour % 24
			offset + 1
		EndIf
	EndIf
	If day = -1
		day = Day(now) + offset
		offset = Int(offset / 31)
		If day >= 31
			day = ((day - 1) % 31) + 1
			offset + 1
		EndIf
	EndIf
	If month = -1
		month = Month(now) + offset
		offset = Int(offset / 12)
		If month >= 31
			month = ((month - 1) % 12) + 1
			offset + 1
		EndIf
	EndIf
	If offset > 0
		year + 1
	EndIf
	; result will be -1 if we passed an invalid date (e.g. day 30 for February)
	result = Date(year, month, day, hour, min, 0)
	; match against filter
	If wday <> -1 And DayOfWeek(result) <> wday
		ProcedureReturn -1
	EndIf
	ProcedureReturn result
EndProcedure


; Convert the given cron alert values to a time prediction from now.
; 
; @param[in] now - current time
; @param[in] limit - limit for offset
; @param[in] wday - trigger for weekday
; @param[in] month - trigger for month
; @param[in] day - trigger for day of month
; @param[in] hour - trigger for hour
; @param[in] min - trigger for minute
; @return time duration until next trigger
Procedure.i MainWindowUpdateAlertEta(now.i, limit.i, wday.i, month.i, day.i, hour.i, min.i)
	Protected.i offset, match, lastTime
	offset = -1
	match = -1
	lastTime = -1
	Repeat
		offset + 1
		match = MainWindowUpdateAlertMaskToTime(now, offset, wday, month, day, hour, min)
		If match > 0
			If match < lastTime
				; overflow; we will repeat outself if we try more
				ProcedureReturn #False
			EndIf
			lastTime = match
		EndIf
		If month <> -1 And wday <> -1 And day <> -1 And hour <> -1 And min <> -1
			If lastTime = -1
				; invalid trigger
				ProcedureReturn #False
			Else
				; only one choice
				Break
			EndIf
		EndIf
		If offset > limit
			; overflow; we will repeat outself if we try more
			ProcedureReturn #False
		EndIf
	Until match >= now
	match = match - now
	If match >= 0 And (match < alerts()\eta Or alerts()\eta = -1)
		alerts()\eta = match
		alerts()\nextTrigger = now + match
	EndIf
	ProcedureReturn #True
EndProcedure


; Convert the given cron alert values to a time prediction from now.
; The minutes value will be replaced accordingly.
; 
; @param[in] now - current time
; @param[in] limit - limit for offset
; @param[in] wday - trigger for weekday
; @param[in] month - trigger for month
; @param[in] day - trigger for day of month
; @param[in] hour - trigger for hour
; @return time duration until next trigger
Procedure.i MainWindowUpdateAlertEtaMins(now.i, limit.i, wday.i, month.i, day.i, hour.i)
	If ListSize(alerts()\mins()) = 0
		MainWindowUpdateAlertEta(now, limit * 60, wday, month, day, hour, -1)
	Else
		ForEach alerts()\mins()
			MainWindowUpdateAlertEta(now, limit, wday, month, day, hour, alerts()\mins())
		Next
	EndIf
EndProcedure


; Convert the given cron alert values to a time prediction from now.
; The hours value will be replaced accordingly.
; 
; @param[in] now - current time
; @param[in] limit - limit for offset
; @param[in] wday - trigger for weekday
; @param[in] month - trigger for month
; @param[in] day - trigger for day of month
; @return time duration until next trigger
Procedure.i MainWindowUpdateAlertEtaHours(now.i, limit.i, wday.i, month.i, day.i)
	If ListSize(alerts()\hours()) = 0
		MainWindowUpdateAlertEtaMins(now, limit * 24, wday, month, day, -1)
	Else
		ForEach alerts()\hours()
			MainWindowUpdateAlertEtaMins(now, limit, wday, month, day, alerts()\hours())
		Next
	EndIf
EndProcedure


; Convert the given cron alert values to a time prediction from now.
; The days value will be replaced accordingly.
; 
; @param[in] now - current time
; @param[in] limit - limit for offset
; @param[in] wday - trigger for weekday
; @param[in] month - trigger for month
; @return time duration until next trigger
Procedure.i MainWindowUpdateAlertEtaDays(now.i, limit.i, wday.i, month.i)
	If ListSize(alerts()\days()) = 0
		MainWindowUpdateAlertEtaHours(now, limit * 31, wday, month, -1)
	Else
		ForEach alerts()\days()
			MainWindowUpdateAlertEtaHours(now, limit, wday, month, alerts()\days())
		Next
	EndIf
EndProcedure


; Convert the given cron alert values to a time prediction from now.
; The months value will be replaced accordingly.
; 
; @param[in] now - current time
; @param[in] limit - limit for offset
; @param[in] wday - trigger for weekday
; @return time duration until next trigger
Procedure.i MainWindowUpdateAlertEtaMonths(now.i, limit.i, wday.i)
	If ListSize(alerts()\months()) = 0
		MainWindowUpdateAlertEtaDays(now, limit * 12, wday, -1)
	Else
		ForEach alerts()\months()
			MainWindowUpdateAlertEtaDays(now, limit, wday, alerts()\months())
		Next
	EndIf
EndProcedure


; Convert the given cron alert values to a time prediction from now.
; The weekdays value will be replaced accordingly.
; 
; @param[in] now - current time
; @return time duration until next trigger
Procedure.i MainWindowUpdateAlertEtaWDays(now.i)
	If ListSize(alerts()\wdays()) = 0
		MainWindowUpdateAlertEtaMonths(now, 7, -1)
	Else
		ForEach alerts()\wdays()
			MainWindowUpdateAlertEtaMonths(now, 1, alerts()\wdays())
		Next
	EndIf
EndProcedure


; Update values in the main window.
; Especially trigger values are updated.
Procedure.i MainWindowRefresh()
	Static.i lastTime = -1
	Protected localTimezone.TIME_ZONE_INFORMATION
	Protected.i currentTime = Date(), timezoneTime, minDiff, splitPos
	Protected.s dateTimeStr, aNextEvent, aNextEta, cmdPart, parmPart
	Protected NewList preTriggers.s()
	Protected NewList triggers.s()
	Protected textOutput.s
	; update only once per second
	If lastTime = currentTime
		ProcedureReturn
	EndIf
	lastTime = currentTime
	GetTimeZoneInformation_(@localTimezone)
	dateTimeStr = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", currentTime)
	If localTimezone\Bias > 0
		dateTimeStr + " -" + RSet(Str((localTimezone\Bias) / 60), 2, "0") + ":" + RSet(Str((localTimezone\Bias) % 60), 2, "0")
	Else
		dateTimeStr + " +" + RSet(Str((-localTimezone\Bias) / 60), 2, "0") + ":" + RSet(Str((-localTimezone\Bias) % 60), 2, "0")
	EndIf
	SetGadgetText(#GID_CurrentTimeValue, dateTimeStr)
	; update alert list
	minDiff = -1
	aNextEvent = ""
	aNextEta = ""
	ForEach alerts()
		timezoneTime = currentTime + ((localTimezone\Bias + alerts()\timezone) * 60)
		If alerts()\state = #AlertState_Init Or (alerts()\state = #AlertState_Triggered And alerts()\eta <= 0)
			alerts()\eta = -1
			alerts()\nextTrigger = -1
			alerts()\state = #AlertState_Idle
			If alerts()\type = #AlertType_Audio
				SetGadgetItemImage(#GID_AlertList, ListIndex(alerts()), ImageID(iconAudio))
			EndIf
			MainWindowUpdateAlertEtaWDays(timezoneTime)
		ElseIf alerts()\nextTrigger <> -1
			alerts()\eta = alerts()\nextTrigger - timezoneTime
		EndIf
		If alerts()\nextTrigger = -1
			SetGadgetItemText(#GID_AlertList, ListIndex(alerts()), "n/a", #CID_AlertList_ETA)
		ElseIf alerts()\eta > 604800
			SetGadgetItemText(#GID_AlertList, ListIndex(alerts()), ">1 week", #CID_AlertList_ETA)
		Else
			SetGadgetItemText(#GID_AlertList, ListIndex(alerts()), StrTime(alerts()\eta), #CID_AlertList_ETA)
		EndIf
		If alerts()\nextTrigger <> -1
			If alerts()\enabled
				If alerts()\eta < minDiff Or minDiff = -1
					minDiff = alerts()\eta
					aNextEvent = alerts()\name
					aNextEta = StrTime(alerts()\eta)
				ElseIf alerts()\eta = minDiff
					aNextEvent + ", " + alerts()\name
				EndIf
			EndIf
			If alerts()\preAlert > 0 And alerts()\eta <= alerts()\preAlert And alerts()\eta > alerts()\preTrigger And Not alerts()\state = #AlertState_PreTriggered
				If alerts()\enabled
					AddElement(preTriggers())
					preTriggers() = alerts()\name
					If alerts()\type = #AlertType_Audio
						SetGadgetItemImage(#GID_AlertList, ListIndex(alerts()), ImageID(iconAudioAlert))
					EndIf
				EndIf
				alerts()\state = #AlertState_PreTriggered
			ElseIf alerts()\eta <= alerts()\preTrigger And Not alerts()\state = #AlertState_Triggered
				If alerts()\enabled
					Select alerts()\type
					Case #AlertType_Audio
						AddElement(triggers())
						triggers() = alerts()\text
					Case #AlertType_Command
						parmPart = ""
						If Left(alerts()\text, 1) = ~"\""
							splitPos = FindString(alerts()\text, ~"\"", 2)
							If splitPos = 0
								cmdPart = Mid(alerts()\text, 2)
							 Else
							 	cmdPart = Mid(alerts()\text, 2, splitPos - 2)
							 	parmPart = Trim(Mid(alerts()\text, splitPos + 1))
							EndIf
						Else
							splitPos = FindString(alerts()\text, " ")
							If splitPos = 0
								cmdPart = alerts()\text
							 Else
							 	cmdPart = Left(alerts()\text, splitPos)
							 	parmPart = Mid(alerts()\text, splitPos + 1)
							EndIf
						EndIf
						RunProgram(cmdPart, parmPart, GetPathPart(openFile))
					EndSelect
				EndIf
				alerts()\state = #AlertState_Triggered
			EndIf
		EndIf
	Next
	If aNextEvent <> ""
		; update systray tooltip
		If aNextEvent <> nextEvent
			If IsSysTrayIcon(#STID_Main)
				SysTrayIconToolTip(#STID_Main, "Next events: " + aNextEvent)
			EndIf
		EndIf
		; update status bar
		If aNextEvent <> nextEvent
			nextEvent = aNextEvent
			StatusBarText(#SBID_Main, 1, nextEvent)
		EndIf
		If aNextEta <> nextEta
			nextEta = aNextEta
			StatusBarText(#SBID_Main, 3, nextEta)
		EndIf
	Else
		SysTrayIconToolTip(#STID_Main, "")
		StatusBarText(#SBID_Main, 1, "")
		StatusBarText(#SBID_Main, 3, "")
	EndIf
	; handle event triggers
	textOutput = ""
	ForEach triggers()
		If textOutput <> ""
			textOutput + " "
		EndIf
		textOutput + triggers()
	Next
	If ListSize(preTriggers()) > 0
		If textOutput <> ""
			textOutput + " "
		EndIf
		textOutput + "Coming soon. "
		ForEach preTriggers()
			If ListIndex(preTriggers()) <> 0
				If ListIndex(preTriggers()) + 1 = ListSize(preTriggers())
					textOutput + " and "
				Else
					textOutput + ", "
				EndIf
			EndIf
			textOutput + preTriggers()
		Next
		textOutput + "."
	EndIf
	If textOutput <> "" And Not isMuted
		TextToSpeech::Speak(textOutput)
	EndIf
EndProcedure


; Window callback called when changes are applied
; to the main window.
; 
; @param[in] hWnd - window handle
; @param[in] uMsg - message to process
; @param[in] wParam - wParam value
; @param[in] lParam - lParam value
; @return #PB_ProcessPureBasicEvents to pass the value to its original handler
Procedure.i MainWindowCallback(hWnd.i, uMsg.i, wParam.i, lParam.i)
	Protected result.i = #PB_ProcessPureBasicEvents
	Protected modDate.i
	Select uMsg
	Case WM_TASKBARCREATED
		; restore the systray icon
		AddSysTrayIcon(#STID_Main, WindowID(#WID_Main), icon)
	Case #WM_TIMER
		If wParam = #TID_Refresh
			If hasOpenFile
				modDate = GetFileDate(openFile, #PB_Date_Modified)
				If modDate <> openFileModDate And openFileMd5 <> FileFingerprint(openFile, #PB_Cipher_MD5)
					MainWindowLoadCronAlert(openFile)
				EndIf
			EndIf
			MainWindowRefresh()
			MainWindowUpdateCronAlert()
		EndIf
	Case #WM_SYSCOMMAND
		; handle iconization
		If (wParam & $FFF0) = #SC_MINIMIZE
			mainWindowIsHidden = #True
			HideWindow(#WID_Main, mainWindowIsHidden)
			result = 0
		EndIf
	Case #WM_MOVE
		; handle size updates
		MainWindowUpdateSizes()
	Case #WM_SIZE
		; handle layouting
		MainWindowResizeGadgets()
	Case #WM_SIZING
		*lprc.RECT = lParam
		If (*lprc\right - *lprc\left < #WinMinWidth + windowXDif)
			*lprc\right = *lprc\left + #WinMinWidth + windowXDif
			UpdateWindow_(hWnd)
		EndIf
		If (*lprc\bottom - *lprc\top < #WinMinHeight + windowYDif)
			*lprc\bottom = *lprc\top + #WinMinHeight + windowYDif
			UpdateWindow_(hWnd)
		EndIf
	Case #WM_DISPLAYCHANGE
		CheckWindowPosition(#WID_Main)
	EndSelect
	ProcedureReturn result
EndProcedure


; Updates the currently open cron alert file
; according to the enabled state changes made
; in the main window.
; The file is only updated if #MinUpdateInterval
; seconds have passed or the force parameter is
; set to true.
;
; @param[in] force - force update
Procedure.i MainWindowUpdateCronAlert(force.i = #False)
	Protected.i now = Date(), fileId, origBom, bom, hasMore
	Protected NewList lines.s()
	If now - lastUpdate >= #MinUpdateInterval Or force
		If ListSize(alerts()) > 0 And hasOpenFile And fileWasChanged And FileFingerprint(openFile, #PB_Cipher_MD5) = openFileMd5
			; enabled state was changed and open file is still the same -> update enabled states
			fileId = ReadFile(#PB_Any, openFile)
			If IsFile(fileId)
				origBom = ReadStringFormat(fileId)
				If origBom = #PB_Ascii
					bom = #PB_UTF8
				Else
					bom = origBom
				EndIf
				While Not Eof(fileId)
					AddElement(lines())
					lines() = ReadString(fileId, bom)
				Wend
				CloseFile(fileId)
				; recreate file
				fileId = CreateFile(#PB_Any, openFile)
				WriteStringFormat(fileId, origBom)
				FirstElement(alerts())
				hasMore = #True
				If IsFile(fileId)
					ForEach lines()
						Repeat
							If Not hasMore
								Break
							EndIf
							If ListIndex(lines()) + 1 > alerts()\line
								If NextElement(alerts())
									Continue
								Else
									hasMore = #False
								EndIf
							ElseIf ListIndex(lines()) + 1 = alerts()\line
								; apply enabled flag
								If Left(lines(), 1) = "-"
									lines() = Right(lines(), Len(lines()) - 1)
								EndIf
								If Not alerts()\enabled
									lines() = "-" + lines()
								EndIf
								If NextElement(alerts()) = 0
									hasMore = #False
								EndIf
							EndIf
							Break
						ForEver
						; write out line
						WriteStringN(fileId, lines(), bom)
					Next
					CloseFile(fileId)
					fileWasChanged = #False
					openFileMd5 = FileFingerprint(openFile, #PB_Cipher_MD5)
					openFileModDate = GetFileDate(openFile, #PB_Date_Modified)
					SetWindowTitle(#WID_Main, mainWindowTitle + " - " + openFile)
				EndIf
			EndIf
		EndIf
		lastUpdate = now
	EndIf
EndProcedure


; Load a cron alert file and display it on the main window.
;
; @param[in] file - load this file
Procedure.i MainWindowLoadCronAlert(file.s)
	Protected.s openFileError
	Protected.i itemIcon
	openFileError = LoadCronAlertFile(file)
	hasOpenFile = #False
	If openFileError = ""
		openFile = file
		openFileMd5 = FileFingerprint(file, #PB_Cipher_MD5)
		openFileModDate = GetFileDate(openFile, #PB_Date_Modified)
		hasOpenFile = #True
		lastOpenFile = openFile
		hasLastFile = #True
		fileWasChanged = #False
		SetWindowTitle(#WID_Main, mainWindowTitle + " - " + openFile)
		ClearGadgetItems(#GID_AlertList)
		ForEach alerts()
			Select alerts()\type
			Case #AlertType_Audio
				itemIcon = iconAudio
			Case #AlertType_Command
				itemIcon = iconCommand
			EndSelect
			If IsImage(itemIcon)
				AddGadgetItem(#GID_AlertList, -1, Chr(10) + Chr(10) + alerts()\name + Chr(10) + alerts()\text, ImageID(itemIcon))
			Else
				AddGadgetItem(#GID_AlertList, -1, Chr(10) + Chr(10) + alerts()\name + Chr(10) + alerts()\text)
			EndIf
			If alerts()\enabled
				SetGadgetItemState(#GID_AlertList, CountGadgetItems(#GID_AlertList) - 1, #PB_ListIcon_Checked)
			EndIf
			SetGadgetItemData(#GID_AlertList, CountGadgetItems(#GID_AlertList) - 1, @alerts())
		Next
		DisableMenuItem(#MID_Main, #MIID_Close, #False)
	Else
		MessageRequester("Error", ~"Failed loading \"" + file + ~"\".\n" + openFileError, #PB_MessageRequester_Ok | #MB_ICONERROR)
	EndIf
	MainWindowUpdateMenus()
EndProcedure


; Close the currently open cron alert file.
Procedure.i MainWindowCloseCronAlert()
	openFile = ""
	hasOpenFile = #False
	ClearList(alerts())
	ClearGadgetItems(#GID_AlertList)
	SetWindowTitle(#WID_Main, mainWindowTitle)
	MainWindowUpdateMenus()
EndProcedure


; Clean-up code for application termination.
Procedure.i MainWindowCleanUp()
	; update open cron alert file if changed
	MainWindowUpdateCronAlert(#True)
	; save user configuration
	MainWindowSaveUserConfig()
	; free text-to-speech interface
	TextToSpeech::DeInitialize()
EndProcedure


;- Data
DataSection
	IconDataAudio:
		IncludeBinary "..\etc\audio.ico"
	IconDataAudioEnd:
	IconDataAudioAlert:
		IncludeBinary "..\etc\audioAlert.ico"
	IconDataAudioAlertEnd:
	IconDataCommand:
		IncludeBinary "..\etc\command.ico"
	IconDataCommandEnd:
EndDataSection
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 367
; FirstLine = 356
; Folding = ----
; EnableUnicode
; EnableXP
; HideErrorLog