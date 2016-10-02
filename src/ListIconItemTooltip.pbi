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

EnableExplicit


DeclareModule ListIconItemTooltip


#TTF_TRACK       =  $20
#TTF_ABSOLUTE    =  $80
#TTF_TRANSPARENT = $100


Declare.i Set(gadget.i)
Declare.i Remove(gadget.i)


EndDeclareModule ; ListIconItemTooltip


Module ListIconItemTooltip


Structure LIITContext
	gadget.i
	oldCallback.i
	lastColumn.i
	lastItem.i
	hToolTip.i
EndStructure


Global NewMap ctx.LIITContext()


Declare.i WindowCallback(hWnd.i, uMsg.i, wParam.i, lParam.i)
Declare.i Show(hWnd.i, text.s, posX.i, posY.i, show.i = #True)


; Adds auto tooltip functionality to the given gadget.
;
; @param[in] gadget - add auto tooltip to this ListIconGadget
Procedure.i Set(gadget.i)
	Protected hToolTip.i, hWnd.i = GadgetID(gadget)
	Protected *ctx.LIITContext, ti.TOOLINFO
	If Not FindMapElement(ctx(), StrU(hWnd))
		*ctx = AddMapElement(ctx(), StrU(hWnd))
		*ctx\gadget = gadget
		*ctx\oldCallback = GetWindowLong_(hWnd, #GWL_WNDPROC)
		SetWindowLong_(hWnd, #GWL_WNDPROC, @WindowCallback())
		ti\cbSize = SizeOf(TOOLINFO)
		hToolTip = CreateWindowEx_(#WS_EX_TOPMOST, "ToolTips_Class32","", #WS_POPUP | #TTS_NOPREFIX | #TTS_ALWAYSTIP, 0, 0, 0, 0, hWnd, 0, GetModuleHandle_(0), 0)
		SendMessage_(hToolTip, #WM_SETFONT, SendMessage_(hWnd, #WM_GETFONT, 0, 0), #True)
		ti\uFlags = #TTF_IDISHWND | #TTF_TRACK | #TTF_ABSOLUTE | #TTF_TRANSPARENT
		ti\hwnd = hWnd
		ti\hInst = GetModuleHandle_(0)
		ti\uId = 0
		ti\lpszText = @""
		GetClientRect_(hWnd, @ti\rect)
		SendMessage_(hToolTip, #TTM_ADDTOOL, 0, @ti)
		SendMessage_(hToolTip, #TTM_TRACKACTIVATE, #False, @ti)
		*ctx\hToolTip = hToolTip
		ProcedureReturn #True
	EndIf
	ProcedureReturn #False
EndProcedure


; Removes the auto tooltip functionality from the given gadget.
;
; @param[in] gadget - remove from this gadget
Procedure.i Remove(gadget.i)
	Protected hWnd.i = GadgetID(gadget), *ctx.LIITContext
	*ctx = FindMapElement(ctx(), StrU(hWnd))
	If *ctx <> #Null
		SetWindowLong_(hWnd, #GWL_WNDPROC, *ctx\oldCallback)
		CloseWindow_(*ctx\hToolTip)
		DeleteMapElement(ctx())
	EndIf
EndProcedure


; Window callback called when changes are applied to a ListIconGadget.
; 
; @param[in] hWnd - window handle
; @param[in] uMsg - message to process
; @param[in] wParam - wParam value
; @param[in] lParam - lParam value
; @return #PB_ProcessPureBasicEvents to pass the value to its original handler
Procedure.i WindowCallback(hWnd.i, uMsg.i, wParam.i, lParam.i)
	Protected result.i = #PB_ProcessPureBasicEvents
	Protected *ctx.LIITContext, pInfo.LVHITTESTINFO, rc.RECT, hDC.i, text.s, sPart.SIZE, mouse.POINT
	*ctx = @ctx(StrU(hWnd))
	result = CallWindowProc_(*ctx\oldCallback, hWnd, uMsg, wParam, lParam)
	Select uMsg
	Case #WM_MOUSEMOVE
		If GetForegroundWindow_() = GetParent_(hWnd)
			pInfo\pt\x = lParam & $FFFF
			pInfo\pt\y = (lParam >> 16) & $FFFF
			SendMessage_(hWnd, #LVM_SUBITEMHITTEST, 0, pInfo)
			If *ctx\lastColumn <> pInfo\iSubItem Or *ctx\lastItem <> pInfo\iItem
				rc\top = pInfo\iSubItem
				rc\left = #LVIR_BOUNDS
				SendMessage_(hWnd, #LVM_GETSUBITEMRECT, pInfo\iItem, rc)
				rc\left  + 2
				rc\right - 2
				If pInfo\iItem >= 0
					text = GetGadgetItemText(*ctx\gadget, pInfo\iItem, pInfo\iSubItem)
					hDC = GetDC_(hWnd)
					If hDC <> #Null
						SelectObject_(hDC, SendMessage_(hWnd, #WM_GETFONT, 0, 0))
						GetTextExtentPoint32_(hDC, @text, Len(text), @sPart)
						ReleaseDC_(hWnd, hDC)
						If sPart\cx >= rc\right - rc\left
							Select OSVersion()
							Case #PB_OS_Windows_Vista, #PB_OS_Windows_Server_2008, #PB_OS_Windows_7
								Show(hWnd, text, rc\left + 4, rc\top + 3)
							Default
								Show(hWnd, text, rc\left + 3, rc\top + 2)
							EndSelect
						Else
							Show(hWnd, "", 0, 0, #False)
						EndIf
					EndIf
				Else
					Show(hWnd, "", 0, 0, #False)
				EndIf
			EndIf
		EndIf
		*ctx\lastColumn = pInfo\iSubItem
		*ctx\lastItem   = pInfo\iItem
	Case #WM_LBUTTONDOWN, #WM_MBUTTONDOWN, #WM_RBUTTONDOWN
		GetCursorPos_(@mouse)
		GetWindowRect_(hWnd, @rc)
		If PtInRect_(@rc, @mouse) = #False
			Show(hWnd, "", 0, 0, #False)
		EndIf
	EndSelect
	ProcedureReturn result
EndProcedure


; Displays the ListIconGadget item tooltip.
;
; @param[in] hWnd - ListIconGadget handle
; @param[in] text - display with this text
; @param[in] posX - display at this x coordinate
; @param[in] posY - display at this y coordinate
; @param[in] show - show or hide tooltip
; @return tooltip handle
Procedure.i Show(hWnd.i, text.s, posX.i, posY.i, show.i = #True)
	Protected *ctx.LIITContext
	Protected hToolTip.i, ti.TOOLINFO, wndRect.RECT
	*ctx = @ctx(StrU(hWnd))
	hToolTip = *ctx\hToolTip
	ti\cbSize = SizeOf(TOOLINFO)
	If hToolTip = #Null
		hToolTip = CreateWindowEx_(#WS_EX_TOPMOST, "ToolTips_Class32","", #WS_POPUP | #TTS_NOPREFIX | #TTS_ALWAYSTIP, 0, 0, 0, 0, hWnd, 0, GetModuleHandle_(0), 0)
		SendMessage_(hToolTip, #WM_SETFONT, SendMessage_(hWnd, #WM_GETFONT, 0, 0), #True)
		ti\uFlags = #TTF_IDISHWND | #TTF_TRACK | #TTF_ABSOLUTE | #TTF_TRANSPARENT
		ti\hwnd = hWnd
		ti\hInst = GetModuleHandle_(0)
		ti\uId = 0
		ti\lpszText = @text
		GetClientRect_(hWnd, @ti\rect)
		SendMessage_(hToolTip, #TTM_ADDTOOL, 0, @ti)
		SendMessage_(hToolTip, #TTM_TRACKACTIVATE, #False, @ti)
	EndIf
	If show
		ti\hwnd = hWnd
		ti\uId = 0
		ti\lpszText = @text
		SendMessage_(hToolTip, #TTM_UPDATETIPTEXT, 0, @ti)
		SendMessage_(hToolTip, #TTM_TRACKACTIVATE, #True, @ti)
		GetWindowRect_(hWnd, @wndRect)
		posX = posX + wndRect\left
		posY = posY + wndRect\top
		SendMessage_(hToolTip, #TTM_TRACKPOSITION, 0, posX | posY <<16)
	Else
		SendMessage_(hToolTip, #TTM_TRACKACTIVATE, #False, @ti)
	EndIf
	ProcedureReturn hToolTip
EndProcedure


EndModule  ; ListIconItemTooltip
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 68
; FirstLine = 19
; Folding = --
; EnableUnicode
; EnableXP
; HideErrorLog