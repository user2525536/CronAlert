﻿; COPYRIGHT
; ---------
; 
; CronAlert Copyright (c) 2016-2019 pcfreak
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
DeclareModule IIteratorC


; iterator position valid field constants
#IteratorPos_None = 0
EnumerationBinary
	#IteratorPos_HasFile
	#IteratorPos_HasLine
	#IteratorPos_HasColumn
	#IteratorPos_HasCharacter
EndEnumeration
#IteratorPos_All = #IteratorPos_HasFile | #IteratorPos_HasLine | #IteratorPos_HasColumn | #IteratorPos_HasCharacter


; iterator position information structure
Structure IteratorPos
	ValidFields.i
	File.s
	Line.i
	Column.i
	Character.i
EndStructure


; Unicode character iterator
Interface IIteratorC
	Forward() ; next character
	GetValue.u() ; return current value
	GetPos.i() ; return current iterator position
	Equal.i(rhs.i) ; compares this iterator with another iterator
	Clone.i() ; create a clone of the iterator
	Delete() ; delete this iterator
EndInterface


EndDeclareModule ; IIteratorC


Module IIteratorC
EndModule ; IIteratorC
; IDE Options = PureBasic 5.45 LTS (Windows - x64)
; CursorPosition = 3
; Folding = -
; EnableUnicode
; EnableXP
; HideErrorLog