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

XIncludeFile "WinComApi.pbi"


DeclareModule TextToSpeech


EnumerationBinary
	#SPF_DEFAULT
	#SPF_ASYNC
	#SPF_PURGEBEFORESPEAK
	#SPF_IS_FILENAME
	#SPF_IS_XML
	#SPF_IS_NOT_XML
	#SPF_PERSIST_XML
	#SPF_NLP_SPEAK_PUNC
	#SPF_PARSE_SAPI
	#SPF_PARSE_SSML
EndEnumeration


#SPDUI_EngineProperties = "EngineProperties"
#SPDUI_AddRemoveWord = "AddRemoveWord"
#SPDUI_UserTraining = "UserTraining"
#SPDUI_MicTraining = "MicTraining"
#SPDUI_RecoProfileProperties = "RecoProfileProperties"
#SPDUI_AudioProperties = "AudioProperties"
#SPDUI_AudioVolume = "AudioVolume"
#SPDUI_UserEnrollment = "UserEnrollment"
#SPDUI_ShareData = "ShareData"
#SPDUI_Tutorial = "Tutorial"


Interface ISpNotifySource Extends IUnknown
	SetNotifySink.i(*pNotifySink)
	SetNotifyWindowMessage.i(hWnd.i, Msg.i, wParam.i, lParam.i)
	SetNotifyCallbackFunction.i(*pfnCallback, wParam.i, lParam.i)
	SetNotifyCallbackInterface.i(*pSpCallback, wParam.i, lParam.i)
	SetNotifyWin32Event.i()
	WaitForNotifyEvent.i(dwMilliseconds.l)
	GetNotifyEventHandle.i()
EndInterface


Interface ISpEventSource Extends ISpNotifySource
	SetInterest(ullEventInterest.q, ullQueuedInterest.q)
	GetEvents(ulCount.l, *pEventArray, *pulFetched.Long)
	GetInfo(*pInfo)
EndInterface


Interface ISpVoice Extends ISpEventSource
	SetOutput.i(*pUnkOutput, fAllowFormatChanges.i)
	GetOutputObjectToken.i(*ppObjectToken)
	GetOutputStream.i(*ppStream)
	Pause.i()
	Resume.i()
	SetVoice.i(*pToken)
	GetVoice.i(*ppToken)
	Speak.i(pwcs.p-unicode, dwFlags.l, *pulStreamNumber)
	SpeakStream.i(*pStream, dwFlags.l, *pulStreamNumber)
	GetStatus.i(*pStatus, ppszLastBookmark.p-unicode)
	Skip.i(pItemType.p-unicode, lNumItems.l, *pulNumSkipped)
	SetPriority.i(*ePriority)
	GetPriority.i(*pePriority)
	SetAlertBoundary.i(*eBoundary)
	GetAlertBoundary.i(*peBoundary)
	SetRate.i(RateAdjust.l)
	GetRate.i(*pRateAdjust)
	SetVolume.i(usVolume.w)
	GetVolume.i(*pusVolume.Word)
	WaitUntilDone.i(msTimeout.l)
	SetSyncSpeakTimeout.i(msTimeout.l)
	GetSyncSpeakTimeout.i(*pmsTimeout.Long)
	SpeakCompleteEvent.i()
	IsUISupported.i(pszTypeOfUI.p-unicode, *pvExtraData, cbExtraData.l, *pfSupported)
	DisplayUI.i(hwndParent.i, pszTitle.p-unicode, pszTypeOfUI.p-unicode, *pvExtraData, cbExtraData.l)
EndInterface


Declare.i Initialize()
Declare.i DeInitialize()
Declare.i GetClassId()
Declare.i GetInterfaceId()
Declare.i Speak(text.s, async.i = #False)
Declare.i GetVolume()
Declare.i SetVolume(value.i)

EndDeclareModule ; TextToSpeech


Module TextToSpeech
UseModule WinComApi


Global pVoice.ISpVoice
Global pVoiceInitialized.i
Global pClassId.i = ?CLSID_SpVoice53, pInterfaceId.i = ?IID_ISpVoice53


; Initializes the text-to-speech interface.
; Call DeInitialize() at the end of execution to free memory again.
;
; @return #True on success, #False if Text-To-Speech API could not be initialized.
Procedure.i Initialize()
	Protected.i result = #True
	If pVoiceInitialized = #False
		result = #False
		If CoCreateInstance_(?CLSID_SpVoice53, #Null, #CLSCTX_ALL, ?IID_ISpVoice53, @pVoice) = #S_OK
			result = #True
		ElseIf CoCreateInstance_(?CLSID_SpVoice51, #Null, #CLSCTX_ALL, ?IID_ISpVoice51, @pVoice) = #S_OK
			result = #True
		EndIf
	EndIf
	pVoiceInitialized = result
	ProcedureReturn result
EndProcedure


; Frees the instantiated text-to-speech interface.
; It is safe to call this function any number of times.
Procedure.i DeInitialize()
	If pVoice <> #Null
		pVoice\Release()
		pVoice = #Null
	EndIf
	ProcedureReturn #True
EndProcedure


; Returns the text-to-speech class ID.
;
; @return SAPI class ID
Procedure.i GetClassId()
	ProcedureReturn pClassId
EndProcedure


; Returns the text-to-speech interface ID.
;
; @return SAPI interface ID
Procedure.i GetInterfaceId()
	ProcedureReturn pInterfaceId
EndProcedure


; Outputs the given English string as acoustic voice.
; 
; @param[in] text - text to output
; @param[in] async - set true to dispatch the voice output (default: false)
; @return #True on success, #False if Text-To-Speech API could not be initialized.
Procedure.i Speak(text.s, async.i = #False)
	If Not Initialize()
		ProcedureReturn #False
	EndIf
	If async = #False ; seems that it is only asynchronous if set to default 
		pVoice\Speak(text, #SPF_ASYNC, #Null)
	Else
		pVoice\Speak(text, #SPF_DEFAULT, #Null)
	EndIf
	ProcedureReturn #True
EndProcedure


; Returns the currently set volume.
; 
; @return volume or -1 on error
Procedure.i GetVolume()
	Protected.u val
	If Not Initialize()
		ProcedureReturn -1
	EndIf
	If pVoice\GetVolume(@val) <> #S_OK
		ProcedureReturn -1
	EndIf
	ProcedureReturn val & $FFFF
EndProcedure


; Sets a new volume value.
; 
; @param[in] value - new volume
; @return #True on success, #False on error
Procedure.i SetVolume(value.i)
	If Not Initialize()
		ProcedureReturn #False
	EndIf
	If pVoice\SetVolume(value) <> #S_OK
		ProcedureReturn #False
	EndIf
	ProcedureReturn #True
EndProcedure


; SAPI 5.1
DefineGuid(CLSID_SpVoice51, $96749377, $3391, $11D2, $9E, $E3, $00, $C0, $4F, $79, $73, $09)
DefineGuid(IID_ISpVoice51, $6C44DF74, $72B9, $4992, $A1,$EC, $EF, $99, $6E, $04, $22, $D4)
; SAPI 5.3
DefineGuid(CLSID_SpVoice53, $96749377, $3391, $11D2, $9E, $E3, $00, $C0, $4F, $79, $73, $96)
DefineGuid(IID_ISpVoice53, $6C44DF74, $72B9, $4992, $A1, $EC, $EF, $99, $6E, $04, $22, $D4)
; SAPI 5.4 (same as 5.3)
; DefineGuid(CLSID_SpVoice54, $96749377, $3391, $11D2, $9E, $E3, $00, $C0, $4F, $79, $73, $96)
; DefineGuid(IID_ISpVoice54, $6C44DF74, $72B9, $4992, $A1, $EC, $EF, $99, $6E, $04, $22, $D4)


EndModule ; TextToSpeech
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 233
; FirstLine = 175
; Folding = --
; EnableUnicode
; EnableXP
; HideErrorLog