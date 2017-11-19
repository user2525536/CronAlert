; COPYRIGHT
; ---------
; 
; CronAlert Copyright (c) 2016-2017 pcfreak
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


CoInitialize_(#Null) ; may be already initialized by PureBasic (e.g. when using MessageRequester)


DeclareModule WinComApi


; Defines the given GUID with the ID as label.
; Use ?ID to refer to the given GUID via its memory address.
Macro DefineGuid(ID, Long, Word1, Word2, Byte1, Byte2, Byte3, Byte4, Byte5, Byte6, Byte7, Byte8)
	DataSection
		ID:
			Data.l Long
			Data.w Word1, Word2
			Data.b Byte1, Byte2, Byte3, Byte4, Byte5, Byte6, Byte7, Byte8
	EndDataSection
EndMacro


EnumerationBinary 1
	#CLSCTX_INPROC_SERVER
	#CLSCTX_INPROC_HANDLER
	#CLSCTX_LOCAL_SERVER
	#CLSCTX_INPROC_SERVER16
	#CLSCTX_REMOTE_SERVER
	#CLSCTX_INPROC_HANDLER16
	#CLSCTX_RESERVED1
	#CLSCTX_RESERVED2
	#CLSCTX_RESERVED3
	#CLSCTX_RESERVED4
	#CLSCTX_NO_CODE_DOWNLOAD
	#CLSCTX_RESERVED5
	#CLSCTX_NO_CUSTOM_MARSHAL
	#CLSCTX_ENABLE_CODE_DOWNLOAD
	#CLSCTX_NO_FAILURE_LOG
	#CLSCTX_DISABLE_AAA
	#CLSCTX_ENABLE_AAA
	#CLSCTX_FROM_DEFAULT_CONTEXT
	#CLSCTX_ACTIVATE_32_BIT_SERVER
	#CLSCTX_ACTIVATE_64_BIT_SERVER
	#CLSCTX_ENABLE_CLOAKING
	#CLSCTX_APPCONTAINER = $400000
	#CLSCTX_ACTIVATE_AAA_AS_IU = $800000
	#CLSCTX_PS_DLL = $80000000
EndEnumeration


#CLSCTX_INPROC = #CLSCTX_INPROC_SERVER | #CLSCTX_INPROC_HANDLER
#CLSCTX_ALL  = #CLSCTX_INPROC_SERVER | #CLSCTX_INPROC_HANDLER | #CLSCTX_LOCAL_SERVER | #CLSCTX_REMOTE_SERVER
#CLSCTX_SERVER = #CLSCTX_INPROC_SERVER | #CLSCTX_LOCAL_SERVER | #CLSCTX_REMOTE_SERVER


EndDeclareModule ; WinComApi


Module WinComApi
EndModule  ; WinComApi
; IDE Options = PureBasic 5.45 LTS (Windows - x64)
; CursorPosition = 3
; Folding = -
; EnableUnicode
; EnableXP
; HideErrorLog