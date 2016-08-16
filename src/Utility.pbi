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

XIncludeFile "CFileIteratorC.pbi"
XIncludeFile "CTextParser.pbi"


UseModule IIteratorC
UseModule ITextParser


Enumeration ; Alert Types
	#AlertType_Audio
	#AlertType_Command
EndEnumeration


Enumeration ; Alert States
	#AlertState_Init
	#AlertState_Idle
	#AlertState_PreTriggered
	#AlertState_Triggered
EndEnumeration


Enumeration ; Date Time Number Types
	#DTNT_Number
	#DTNT_Month
	#DTNT_Weekday
EndEnumeration


#UserConfig = "CronAlert\settings.dat"
#PreTriggerTime = 2 ; in seconds


Structure CronAlert
	type.i ; alert type
	timezone.i ; in minutes offset to UTC
	eta.i ; in seconds
	preAlert.i ; in seconds
	preTrigger.i ; in seconds
	nextTrigger.i ; date time
	List mins.i()
	List hours.i()
	List wdays.i()
	List days.i()
	List months.i()
	name.s
	text.s
	state.i ; alert state
	enabled.i ; boolean
	line.i
EndStructure


Prototype SHGetKnownFolderPathProto(rfid.i, dwFlags.l, hToken.i, *ppszPath)
Prototype AtExitCallback()


Declare.l BSwap32(value.l)
Declare.i WriteStringL(fileId.i, string.s, format.i = #PB_UTF8)
Declare.s ReadStringL(fileId.i, format.i = #PB_UTF8)
Declare.s GetUserConfigPath()
Declare.s StrTime(Seconds.q)
Declare.s TrimSingle(string.s, ch.c)
Declare.s RemoveXml(string.s)
Declare.i FileIcon(file.s, small.i = #False)
Declare.i SetStatusBarWidth(statusBar.i, item.i, width.i)
Declare.i PointInRect(*rect.RECT, *point.POINT)
Declare.i CheckWindowPosition(window.i)
Declare.i SkipBlanks(parser.ITextParser)
Declare.i SkipComment(parser.ITextParser)
Declare.i ParseCharSkipped(parser.ITextParser, char.u, *error.String)
Declare.i ParseNumberGroup(parser.ITextParser, List numGroup.i(), minVal.i, maxVal.i, *error.String, type.i = #DTNT_Number)
Declare.i ParseString(parser.ITextParser, *out.String, *error.String)
Declare.s GetLineInfo(parser.ITextParser)
Declare.s LoadCronAlertFile(file.s)
Declare.i AtExit(callback.AtExitCallback)
Declare.i ExitProgram()


Global NewList alerts.CronAlert()
Global NewList exitCallbacks.i()
Global Dim weekdays.MapItem(6)
Global Dim months.MapItem(11)


Macro SetMapItem(arr, index, _key, _value)
	arr(index)\key = _key
	arr(index)\value = _value
EndMacro


SetMapItem(weekdays, 0, "mon", 1)
SetMapItem(weekdays, 1, "tue", 2)
SetMapItem(weekdays, 2, "wed", 3)
SetMapItem(weekdays, 3, "thu", 4)
SetMapItem(weekdays, 4, "fri", 5)
SetMapItem(weekdays, 5, "sat", 6)
SetMapItem(weekdays, 6, "sun", 0)
SortStructuredArray(weekdays(), #PB_Sort_Ascending | #PB_Sort_NoCase, OffsetOf(MapItem\key), #PB_String)
SetMapItem(months,  0, "jan",  1)
SetMapItem(months,  1, "feb",  2)
SetMapItem(months,  2, "mar",  3)
SetMapItem(months,  3, "apr",  4)
SetMapItem(months,  4, "may",  5)
SetMapItem(months,  5, "jun",  6)
SetMapItem(months,  6, "jul",  7)
SetMapItem(months,  7, "aug",  8)
SetMapItem(months,  8, "sep",  9)
SetMapItem(months,  9, "oct", 10)
SetMapItem(months, 10, "nov", 11)
SetMapItem(months, 11, "dec", 12)
SortStructuredArray(months(), #PB_Sort_Ascending | #PB_Sort_NoCase, OffsetOf(MapItem\key), #PB_String)


UndefineMacro SetMapItem


WinComApi::DefineGuid(FOLDERID_RoamingAppData, $3EB685DB, $65F9, $4CF6, $A0, $3A, $E3, $EF, $65, $72, $9F, $3D)


;- Functions
; Togles big-endian and little-endian for the given
; 32-bit value.
;
; @param[in] value - byte-swap this value
; @return byte-swapped value
Procedure.l BSwap32(value.l)
	CompilerIf #PB_Compiler_Processor = #PB_Processor_x86 Or #PB_Compiler_Processor = #PB_Processor_x64
		!MOV eax, dword [p.v_value]
		!BSWAP eax
		ProcedureReturn
	CompilerElse
		ProcedureReturn (value << 24) | ((value & $FF00) << 8) | ((value >> 8) & $FF00) | (value >> 24)
	CompilerEndIf
EndProcedure


; Outputs the given string to the specific file with length information
; to make it possible to mix strings and binary data.
; 
; @param[in,out] fileId - file handle to use
; @param[in] string - output this string
; @param[in] format - string encoding (default is UTF8)
; @return non-zero on success and zero on error
Procedure.i WriteStringL(fileId.i, string.s, format.i = #PB_UTF8)
	WriteLong(fileId, StringByteLength(string, format))
	ProcedureReturn WriteString(fileId, string, format)
EndProcedure


; Reads a string from the specific file with length information
; to make it possible to mix strings and binary data.
; 
; @param[in,out] fileId - file handle to use
; @param[in] format - string encoding (default is UTF8)
; @return the string read or an empty string on error
Procedure.s ReadStringL(fileId.i, format.i = #PB_UTF8)
	Protected buffer.i, length.l
	Protected string.s
	length = ReadLong(fileId)
	If length > 0
		buffer = AllocateMemory(length + 2)
		If buffer <> #Null
			ReadData(fileId, buffer, length)
			string = PeekS(buffer, -1, format)
			FreeMemory(buffer)
			ProcedureReturn string
		EndIf
	EndIf
	ProcedureReturn ""
EndProcedure


; Returns the path for application specific user configuration files.
;
; @return application configuration path
Procedure.s GetUserConfigPath()
	Protected result.s
	Protected library.i, strPtr.i
	Protected SHGetKnownFolderPath.SHGetKnownFolderPathProto
	result = GetEnvironmentVariable("APPDATA")
	If result = ""
		library = OpenLibrary(#PB_Any, "shell32.dll")
		If IsLibrary(library)
			SHGetKnownFolderPath = GetFunction(library, "SHGetKnownFolderPath")
			If SHGetKnownFolderPath(?FOLDERID_RoamingAppData, 0, 0, @strPtr) = #S_OK
				result = PeekS(strPtr, -1, #PB_Unicode)
				CoTaskMemFree_(strPtr)
			EndIf
			CloseLibrary(library)
		EndIf
	EndIf
	If result <> "" And Right(result, 1) <> "\"
		result + "\"
	EndIf
	ProcedureReturn result
EndProcedure


; Converts the given duration in seconds into a string.
;
; @param[in] Seconds - duration in seconds to convert
; @return string representation of the given duration
; @remarks Negative values and 0 are converted to "now".
Procedure.s StrTime(Seconds.q)
	Protected Result$ = ""
	If Seconds <= 0
		Result$ = "now"
	ElseIf Seconds <= 60
		Result$ = Str(Seconds) + "s"
	ElseIf Seconds <= 3600
		Result$ = Str(Seconds / 60) + "m"
		If Seconds % 60
			Result$ + " " + Str(Seconds % 60) + "s"
		EndIf
	ElseIf Seconds <= 86400
		Seconds = Seconds / 60
		Result$ = Str(Seconds / 60) + "h"
		If Seconds % 60
			Result$ + " " + Str(Seconds % 60) + "m"
		EndIf
	Else
		Seconds = Seconds / 3600
		Result$ = StrU(Seconds / 24, #PB_Quad) + "d"
		If Seconds % 60
			Result$ + " " + Str(Seconds % 24) + "h"
		EndIf
	EndIf
	ProcedureReturn Result$
EndProcedure


; Removed the given character from both ends of the
; passed string if both ends as equal to that character.
;
; @param[in] string - string to trim
; @param[in] ch - character to remove from both ends
; @return trimmed string or original string if criteria did not match
Procedure.s TrimSingle(string.s, ch.c)
	If Asc(Left(string, 1)) = ch And Asc(Right(string, 1)) = ch
		ProcedureReturn Mid(string, 2, Len(string) - 2)
	EndIf
	ProcedureReturn string
EndProcedure


; Removes XML tags from the given string.
;
; @param[in] string  - string to clean-up
; @return passed string without XML tags
Procedure.s RemoveXml(string.s)
	Protected.s result = string
	Protected.CHARACTER *in, *out
	Protected.i hasTagOpen, hasStringOpen
	*in = @string
	*out = @result
	hasTagOpen = #False
	hasStringOpen = #False
	While *in\c <> 0
		Select *in\c
		Case '<'
			hasTagOpen = #True
		Case '>'
			If Not hasStringOpen
				hasTagOpen = #False
			EndIf
		Case '"', 39 ; '
			If hasStringOpen
				hasStringOpen = #False
			Else
				hasStringOpen = #True
			EndIf
		Default
			If Not hasTagOpen
				*out\c = *in\c
				*out + SizeOf(CHARACTER)
			EndIf
		EndSelect
		*in + SizeOf(CHARACTER)
	Wend
	*out\c = 0
	ProcedureReturn PeekS(@result)
EndProcedure


; Gets the handle to the icon the explorer would display
; the given file as. The given file needs to exist.
; 
; @param[in] file - obtain icon from this file
; @param[in] small - set to true for small icon and false for large icon (default is false)
; @return file icon handle
Procedure.i FileIcon(file.s, small.i = #False)
	Protected shFileInfo.SHFILEINFO
	If small
		SHGetFileInfo_(file, 0, @shFileInfo, SizeOf(SHFILEINFO), #SHGFI_ICON | #SHGFI_SMALLICON)
	Else
		SHGetFileInfo_(file, 0, @shFileInfo, SizeOf(SHFILEINFO), #SHGFI_ICON)
	EndIf
	ProcedureReturn shFileInfo\hIcon
EndProcedure


; Changes the width of a given status bar element.
; All following items need to be updated as well.
; 
; @param[in,out] statusBar - status bar ID
; @param[in] item - item index
; @param[in] width - new item width
; @return non-zero on success, else zero
Procedure.i SetStatusBarWidth(statusBar.i, item.i, width.i)
	Protected nParts.i, leftField.l, result.i
	If IsStatusBar(statusBar)
		nParts = SendMessage_(StatusBarID(StatusBar), #SB_GETPARTS, 0, 0)
		*dwFields = AllocateMemory(nParts * 4)
		If *dwFields <> #Null
			SendMessage_(StatusBarID(statusBar), #SB_GETPARTS, nParts, *dwFields)
			If Item < 1
				leftField = 0
			Else
				leftField = PeekL(*dwFields + ((item - 1) * 4))
			EndIf
			PokeL(*dwFields + (Item * 4), leftField + width)
			result = SendMessage_(StatusBarID(statusBar), #SB_SETPARTS, nParts, *dwFields)
			FreeMemory(*dwFields)
			ProcedureReturn result
		EndIf
	EndIf
	ProcedureReturn #False
EndProcedure


; Checks if the given point is within the passed rectangle.
; 
; @param[in] *rect - rectangle to be in
; @param[in] *point - point to check
; @return true if within, else false
Procedure.i PointInRect(*rect.RECT, *point.POINT)
	If *point\x < *rect\left Or *point\x > *rect\right Or *point\y < *rect\top Or *point\y > *rect\bottom
		ProcedureReturn #False
	EndIf
	ProcedureReturn #True
EndProcedure


; Checks if the given window is off-screen and corrects its
; position.
;
; @param[in] window - window ID
Procedure.i CheckWindowPosition(window.i)
	Protected.i i, count, isWithin = #False, needAdjustment = #False
	Protected.i winWidth, winHeight
	Protected.RECT win, desktop, desktop0
	Protected.POINT winTop, winBottom
	winWidth = WindowWidth(window, #PB_Window_FrameCoordinate)
	winHeight = WindowHeight(window, #PB_Window_FrameCoordinate)
	win\left = WindowX(window)
	win\top = WindowY(window)
	win\right = win\left + winWidth
	win\bottom = win\top + winHeight
	winTop\x = win\left
	winTop\y = win\top
	winBottom\x = win\right
	winBottom\y = win\bottom
	count = ExamineDesktops()
	For i = 0 To count - 1
		desktop\left = DesktopX(i)
		desktop\top = DesktopY(i)
		desktop\right = desktop\left + DesktopWidth(i)
		desktop\bottom = desktop\top + DesktopHeight(i)
		If i = 0
			CopyStructure(@desktop, @desktop0, RECT)
		EndIf
		If PointInRect(@desktop, @winTop)
			If PointInRect(@desktop, @winBottom)
				isWithin = #True
				Break
			Else
				needAdjustment = #True
			EndIf
		ElseIf PointInRect(@desktop, @winBottom)
			needAdjustment = #True
		EndIf
		If needAdjustment
			If desktop\right < win\right
				win\left = desktop\right - winWidth
			ElseIf desktop\left > win\left
				win\left = desktop\left
			EndIf
			If desktop\bottom < win\bottom
				win\top = desktop\bottom - winHeight
			ElseIf desktop\top > win\top
				win\top = desktop\top
			EndIf
			ResizeWindow(window, win\left, win\top, #PB_Ignore, #PB_Ignore)
			isWithin = #True
			Break
		EndIf
	Next
	If Not isWithin
		ResizeWindow(window, ((desktop0\right - desktop0\left - winWidth) / 2) + desktop0\left, ((desktop0\bottom - desktop0\top - winHeight) / 2) + desktop0\top, #PB_Ignore, #PB_Ignore)
	EndIf
EndProcedure


; Skip all blank characters in the given parser instance.
; 
; @param[in,out] parser - parser object handle
; @return true on success, else false
Procedure.i SkipBlanks(parser.ITextParser)
	Protected.i result = #False
	While parser\Blank()
		result = #True
	Wend
	ProcedureReturn result
EndProcedure


; Skip a comment in the given parser instance.
; A comment is all starting at a hashmark or semicolon
; until the end-of-line or end-of-input.
; 
; @param[in,out] parser - parser object handle
; @return true on success, else false
Procedure.i SkipComment(parser.ITextParser)
	Protected it.IIteratorC
	SkipBlanks(parser)
	If parser\CharSet("#;")
		ProcedureReturn parser\SkipUntil(~"\n\r")
	EndIf
	it = parser\GetStartIterator()
	If it <> #Null
		Select it\GetValue()
		Case 10, 13
			ProcedureReturn #True
		EndSelect
	EndIf
	ProcedureReturn parser\Eoi()
EndProcedure


; Parses a specific character. All blanks around it
; are also consumed. Rewinds to the original position
; if no match was found.
; 
; @param[in,out] parser - parser object handle
; @param[in] char - match this character
; @param[out] *error - output an possible error
; @return true on success, else false
Procedure.i ParseCharSkipped(parser.ITextParser, char.u, *error.String)
	Protected result.i = #False
	Protected savedIt.IIteratorC
	savedIt = parser\CloneStartIterator()
	If savedIt = #Null
		*error\s = "Failed to allocate memory."
		ProcedureReturn #False
	EndIf
	SkipBlanks(parser)
	If parser\CharVal(char)
		result = #True
		SkipBlanks(parser)
	Else
		parser\SetStartIterator(savedIt)
		savedIt = #Null
	EndIf
	If savedIt <> #Null
		savedIt\Delete()
	EndIf
	ProcedureReturn result
EndProcedure


; Parses a crontab-like time element.
; 
; @param[in,out] parser - parser object handle
; @param[in] numGroup() - output match to this list
; @param[in] minVal - minimal allowed value
; @param[in] maxVal - maximal allowed value
; @param[out] *error - output an possible error
; @param[in] type - number type to support specific string values
; @return true on success, else false
; @see https://en.wikipedia.org/wiki/Cron
; @remarks Only the special characters ',', '-', '/' and '*' are allowed.
Procedure.i ParseNumberGroup(parser.ITextParser, List numGroup.i(), minVal.i, maxVal.i, *error.String, type.i = #DTNT_Number)
	Protected result.i = #False
	Protected i.i, lastNumber.i, number.i, steps.i, parseMore.i
	ClearList(numGroup())
	SkipBlanks(parser)
	Repeat
		If parser\CharVal('*')
			result = #True
			If ParseCharSkipped(parser, '/', *error)
				If parser\Num(@steps, #False)
					If steps < minVal Or steps > maxVal Or steps < 1
						result = #False
						If minVal < 1
							*error\s = GetLineInfo(parser) + ": Given number is out of range. Allowed interval is [" + Str(1) + "; " + Str(maxVal) + "]."
						Else
							*error\s = GetLineInfo(parser) + ": Given number is out of range. Allowed interval is [" + Str(minVal) + "; " + Str(maxVal) + "]."
						EndIf
					Else
						i = minVal
						While i <= maxVal
							AddElement(numGroup())
							numGroup() = i
							i + steps
						Wend
					EndIf
				Else
					*error\s = GetLineInfo(parser) + ": Expected <unsigned number> here."
				EndIf
			Else
				If *error\s <> ""
					Break
				EndIf
			EndIf
		ElseIf parser\Num(@number, #False) Or (type = #DTNT_Month And parser\MatchI(months(), 12, @number)) Or (type = #DTNT_Weekday And parser\MatchI(weekdays(), 7, @number))
			If number < minVal Or number > maxVal
				*error\s = GetLineInfo(parser) + ": Given number is out of range. Allowed interval is [" + Str(minVal) + "; " + Str(maxVal) + "]."
				Break
			EndIf
			result = #True
			parseMore = #True
			AddElement(numGroup())
			numGroup() = number
			Repeat
				If ParseCharSkipped(parser, '-', *error)
					lastNumber = number
					If parser\Num(@number, #False) Or (type = #DTNT_Month And parser\MatchI(months(), 12, @number)) Or (type = #DTNT_Weekday And parser\MatchI(weekdays(), 7, @number))
						If number < minVal Or number > maxVal
							result = #False
							parseMore = #False
							*error\s = GetLineInfo(parser) + ": Given number is out of range. Allowed interval is [" + Str(minVal) + "; " + Str(maxVal) + "]."
						Else
							If ParseCharSkipped(parser, '/', *error)
								If parser\Num(@steps, #False)
									If steps < minVal Or steps > maxVal Or steps < 1
										result = #False
										parseMore = #False
										If minVal < 1
											*error\s = GetLineInfo(parser) + ": Given number is out of range. Allowed interval is [" + Str(1) + "; " + Str(maxVal) + "]."
										Else
											*error\s = GetLineInfo(parser) + ": Given number is out of range. Allowed interval is [" + Str(minVal) + "; " + Str(maxVal) + "]."
										EndIf
									Else
										i = lastNumber
										While i <= number
											AddElement(numGroup())
											numGroup() = i
											i + steps
										Wend
									EndIf
								Else
									*error\s = GetLineInfo(parser) + ": Expected <unsigned number> here."
								EndIf
							Else
								If *error\s <> ""
									Break 2
								EndIf
								While lastNumber <= number
									AddElement(numGroup())
									numGroup() = lastNumber
									lastNumber + 1
								Wend
							EndIf
						EndIf
					Else
						result = #False
						parseMore = #False
						*error\s = GetLineInfo(parser) + ": Expected <unsigned number> here."
					EndIf
				Else
					If *error\s <> ""
						Break 2
					EndIf
					parseMore = #False
				EndIf
			Until Not parseMore
		Else
			*error\s = GetLineInfo(parser) + ": Expected '*' or <unsigned number> here."
		EndIf
	Until Not ParseCharSkipped(parser, ',', *error)
	; remove duplicates
	SortList(numGroup(), #PB_Sort_Ascending)
	lastNumber = minVal - 1
	ForEach numGroup()
		If numGroup() = lastNumber
			DeleteElement(numGroup())
		Else
			lastNumber = numGroup()
		EndIf
	Next
	ProcedureReturn result
EndProcedure


; Parses a string which includes all characters after the first
; double-quote just before the next double-quote.
; 
; @param[in,out] parser - parser object handle
; @param[out] *out - output the parsed string to this variable
; @param[out] *error - output an possible error
; @return true on success, else false
Procedure.i ParseString(parser.ITextParser, *out.String, *error.String)
	Protected result.i = #False
	Protected string.String
	Protected savedIt.IIteratorC
	savedIt = parser\CloneStartIterator()
	If savedIt = #Null
		*error\s = "Failed to allocate memory."
		ProcedureReturn #False
	EndIf
	Repeat
		string\s = ""
		If Not parser\CharVal('"')
			*error\s = GetLineInfo(parser) + ": Expected <string> here."
			Break
		EndIf
		If Not parser\StringUntilChar(~"\"\n\r", @string)
			*error\s = GetLineInfo(parser) + ~": Expected '\"' here."
			Break
		EndIf
		If Not parser\CharVal('"')
			*error\s = GetLineInfo(parser) + ~": Expected '\"' here."
			Break
		EndIf
		result = #True
	Until #True
	If result = #True
		If *out <> #Null
			*out\s = string\s
		EndIf
	Else
		parser\SetStartIterator(savedIt)
		savedIt = #Null
	EndIf
	If savedIt <> #Null
		savedIt\Delete()
	EndIf
	ProcedureReturn result
EndProcedure


; Returns the current file position of the given parser.
; 
; @param[in] parser - parser object handle
; @return current file position or an empty string on error
Procedure.s GetLineInfo(parser.ITextParser)
	Protected.s result = ""
	Protected *it.IIteratorC
	Protected *pos.IteratorPos
	If parser <> #Null
		*it = parser\GetStartIterator()
		If *it <> #Null
			*pos = *it\GetPos()
			If *pos <> #Null
				result + *pos\File + ":" + *pos\Line + ":" + *pos\Column
			EndIf
		EndIf
	EndIf
	ProcedureReturn result
EndProcedure


; Loads the given CronAlert file.
; The global list alerts() will be filled with the results on success.
; Nothing will be changed on error.
; 
; @param[in] file - full path to the CronAlert file
; @return an empty string on success or an error message
Procedure.s LoadCronAlertFile(file.s)
	Protected result.String, lineInfo.s
	Protected NewList newAlerts.CronAlert()
	Protected item.CronAlert
	Protected localTimezone.TIME_ZONE_INFORMATION
	Protected timezone.i, number.i, preAlert.i = 0, preTrigger.i = #PreTriggerTime, aStr.String
	Protected *pos.IteratorPos
	Protected it.IIteratorC, first.IIteratorC, last.IIteratorC, savedIt.IIteratorC
	Protected parser.ITextParser
	result\s = ""
	GetTimeZoneInformation_(@localTimezone)
	timezone = -(localTimezone\Bias)
	; open file
	If file = "" Or FileSize(file) <= 0
		ProcedureReturn "Failed to read file."
	EndIf
	first = CFileIteratorC::Create(file)
	If first = #Null
		ProcedureReturn "Failed to read file."
	EndIf
	last = CFileIteratorC::Create()
	parser = CTextParser::Create(first, last)
	If parser = #Null
		first\Delete()
		last\Delete()
		ProcedureReturn "Failed to create parser instance."
	EndIf
	; parse file
	parser\SetNumSep() ; disable number separator parsing
	Repeat
		SkipBlanks(parser)
		If SkipComment(parser)
			; ignore line
		ElseIf parser\CharVal('@')
			; pragma
			If parser\String("timezone")
				SkipBlanks(parser)
				If parser\String("local")
					timezone = -(localTimezone\Bias)
				ElseIf parser\Num(@timezone)
					; set timezone in minutes or try to get as 00:00
					savedIt = parser\CloneStartIterator()
					If savedIt = #Null
						result\s = "Failed to allocate memory."
						Break
					EndIf
					If parser\CharVal(':')
						If parser\Num(@number, #False)
							timezone = (timezone * 60) + number
						Else
							parser\SetStartIterator(savedIt)
							result\s = GetLineInfo(parser) + ~": Expected <unsigned number> after ':'."
						EndIf
						savedIt\Delete()
					Else
						parser\SetStartIterator(savedIt)
						If result\s <> ""
							Break
						EndIf
					EndIf
				Else
					result\s = GetLineInfo(parser) + ~": Expected 'local' or timezone as <number> here.\nNote: Value in minutes offset to UTC."
					Break
				EndIf
			ElseIf parser\String("preAlert")
				SkipBlanks(parser)
				If parser\String("off") Or parser\NumVal(0, #False)
					; disable preAlert
					preAlert = 0
				ElseIf parser\Num(@preAlert, #False)
					; set preAlert in seconds or try to get as 00:00
					savedIt = parser\CloneStartIterator()
					If savedIt = #Null
						result\s = "Failed to allocate memory."
						Break
					EndIf
					If parser\CharVal(':')
						If parser\Num(@number, #False)
							preAlert = (preAlert * 60) + number
						Else
							parser\SetStartIterator(savedIt)
							result\s = GetLineInfo(parser) + ~": Expected <unsigned number> after ':'."
						EndIf
						savedIt\Delete()
					Else
						parser\SetStartIterator(savedIt)
						If result\s <> ""
							Break
						EndIf
					EndIf
				Else
					result\s = GetLineInfo(parser) + ~": Expected 'off' or <unsigned number> here.\nNote: Value in seconds to be triggered before the actual event."
					Break
				EndIf
			ElseIf parser\String("preTrigger")
				SkipBlanks(parser)
				If parser\String("off") Or parser\NumVal(0, #False)
					; disable preTrigger
					preTrigger = 0
				ElseIf parser\String("default")
					; default preTrigger
					preTrigger = #PreTriggerTime
				ElseIf parser\Num(@preTrigger, #False)
					; set preTrigger in seconds or try to get as 00:00
					savedIt = parser\CloneStartIterator()
					If savedIt = #Null
						result\s = "Failed to allocate memory."
						Break
					EndIf
					If parser\CharVal(':')
						If parser\Num(@number, #False)
							preTrigger = (preTrigger * 60) + number
						Else
							parser\SetStartIterator(savedIt)
							result\s = GetLineInfo(parser) + ~": Expected <unsigned number> after ':'."
						EndIf
						savedIt\Delete()
					Else
						parser\SetStartIterator(savedIt)
						If result\s <> ""
							Break
						EndIf
					EndIf
				Else
					result\s = GetLineInfo(parser) + ~": Expected 'off', 'default' or <unsigned number> here.\nNote: Value in seconds to be triggered before the actual event."
					Break
				EndIf
			Else
				result\s = GetLineInfo(parser) + ": Unknown pragma. Expected 'timezone', 'preAlert' or 'preTrigger' here."
				Break
			EndIf
		Else
			; actual event
			lineInfo = GetLineInfo(parser)
			ClearStructure(@item, CronAlert)
			InitializeStructure(@item, CronAlert)
			item\preAlert = preAlert
			item\preTrigger = preTrigger
			item\timezone = timezone
			item\state = #AlertState_Init
			item\nextTrigger = -1
			item\enabled = #True
			item\line = -1
			aStr\s = "" ; initialize string
			; get line number
			it = parser\GetStartIterator()
			If it <> #Null
				*pos = it\GetPos()
				If *pos <> #Null
					item\line = *pos\Line
				EndIf
			EndIf
			; parse minutes
			If parser\CharVal('-')
				item\enabled = #False
			EndIf
			If Not ParseNumberGroup(parser, item\mins(), 0, 59, @result)
				Break
			EndIf
			If Not SkipBlanks(parser)
				result\s = GetLineInfo(parser) + ": Expected space here."
				Break
			EndIf
			; parse hours
			If Not ParseNumberGroup(parser, item\hours(), 0, 23, @result)
				Break
			EndIf
			If Not SkipBlanks(parser)
				result\s = GetLineInfo(parser) + ": Expected space here."
				Break
			EndIf
			; parse days
			If Not ParseNumberGroup(parser, item\days(), 1, 31, @result)
				Break
			EndIf
			If Not SkipBlanks(parser)
				result\s = GetLineInfo(parser) + ": Expected space here."
				Break
			EndIf
			; parse months
			If Not ParseNumberGroup(parser, item\months(), 1, 12, @result, #DTNT_Month)
				Break
			EndIf
			If Not SkipBlanks(parser)
				result\s = GetLineInfo(parser) + ": Expected space here."
				Break
			EndIf
			; parse wdays
			If Not ParseNumberGroup(parser, item\wdays(), 0, 7, @result, #DTNT_Weekday)
				Break
			EndIf
			; allow 0 and 7 for Sunday
			ForEach item\wdays()
				item\wdays() = item\wdays() % 7
			Next
			If Not SkipBlanks(parser)
				result\s = GetLineInfo(parser) + ": Expected space here."
				Break
			EndIf
			; parse name
			If Not ParseString(parser, @aStr, @result)
				Break
			EndIf
			item\name = aStr\s
			If Not SkipBlanks(parser)
				result\s = GetLineInfo(parser) + ": Expected space here."
				Break
			EndIf
			; parse text
			If parser\CharVal('!')
				If parser\StringUntilEol(@aStr)
					item\type = #AlertType_Command
					item\text = aStr\s
				Else
					result\s = GetLineInfo(parser) + ": Expected <command> here."
					Break
				EndIf
			ElseIf ParseString(parser, @aStr, @result)
				item\type = #AlertType_Audio
				item\text = aStr\s
			Else
				Break
			EndIf
			; add item to alert list
			AddElement(newAlerts())
			CopyStructure(@item, @newAlerts(), CronAlert)
		EndIf
		SkipComment(parser)
		If Not parser\Eol() And Not parser\Eoi()
			result\s = GetLineInfo(parser) + ": Expected <end-of-line> or <end-of-input> here."
			Break
		EndIf
	Until parser\Eoi()
	; overwrite results on success
	If result\s = ""
		ClearList(alerts())
		CopyList(newAlerts(), alerts())
	EndIf
	; clean-up
	ClearStructure(@item, CronAlert)
	parser\Delete()
	ProcedureReturn result\s
EndProcedure


; Register a callback which shall be executed on program termination.
; The callback shall be without any parameters (not even defaulted ones).
; 
; @param[in] callback - register this callback function
Procedure.i AtExit(callback.AtExitCallback)
	AddElement(exitCallbacks())
	exitCallbacks() = callback
	ProcedureReturn
EndProcedure


; Terminates the application. All registered at exit functions
; will be called before final program termination.
Procedure.i ExitProgram()
	Protected callback.AtExitCallback
	ForEach exitCallbacks()
		callback = exitCallbacks()
		callback()
	Next
	End
EndProcedure
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 96
; FirstLine = 51
; Folding = ----
; EnableUnicode
; EnableXP
; HideErrorLog