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
XIncludeFile "IIteratorC.pbi"


DeclareModule CStringIteratorC


CompilerIf #PB_Compiler_Unicode
Declare.i Create(*Ref.String = #Null, Encoding.i = #PB_Unicode, File.s = "")
CompilerElse
Declare.i Create(*Ref.String = #Null, Encoding.i = #PB_UTF8, File.s = "")
CompilerEndIf


EndDeclareModule ; CFileIteratorC


Module CStringIteratorC
UseModule IIteratorC


Structure CStringIteratorCAttributes
	VTablePtr.i
	Pos.IteratorPos
	*Ptr.String
	Encoding.i
	Value.u
EndStructure


; Creates a new CStringIteratorC instance which conforms to the IIteratorC interface.
;
; @param[in,out] *Ref - optional string pointer to start at
; @param[in] Encoding - optional set encoding to use
; @param[in] File - optional reference to a source file (for error reporting)
; @return CStringIteratorC instance
CompilerIf #PB_Compiler_Unicode
Procedure.i Create(*Ref.String = #Null, Encoding.i = #PB_Unicode, File.s = "")
CompilerElse
Procedure.i Create(*Ref.String = #Null, Encoding.i = #PB_UTF8, File.s = "")
CompilerEndIf
	*obj.CStringIteratorCAttributes = AllocateMemory(SizeOf(CStringIteratorCAttributes))
	If *obj = #Null
		ProcedureReturn #Null
	EndIf
	*obj\VTablePtr = ?CStringIteratorCVTable
	If *Ref = #Null
		; end of file iterator
		*obj\Pos\ValidFields = #IteratorPos_None
		*obj\Ptr = #Null
	Else
		*obj\Pos\ValidFields = #IteratorPos_All
		*obj\Pos\File = File
		*obj\Pos\Line = 1
		*obj\Pos\Column = 1
		*obj\Pos\Character = 1
		*obj\Ptr = *Ref
		*obj\Encoding = Encoding
		Select *obj\Encoding
		Case #PB_Ascii
			*obj\Value = PeekA(*obj\Ptr)
		Case #PB_Unicode
			*obj\Value = PeekU(*obj\Ptr)
		Case #PB_UTF8
			*obj\Value = Asc(PeekS(*obj\Ptr, 1, *obj\Encoding))
		EndSelect
	EndIf
	ProcedureReturn *obj
EndProcedure


; Moves the iterator one element towards the end.
; Bound checks are not performed.
;
; @param[in,out] *obj - object
Procedure Forward(*obj.CStringIteratorCAttributes)
	Protected LastValue.u, StrMem.q
	LastValue = *obj\Value
	Select *obj\Encoding
	Case #PB_Ascii
		*obj\Ptr + 1
		*obj\Value = PeekA(*obj\Ptr)
	Case #PB_Unicode
		*obj\Ptr + 2
		*obj\Value = PeekU(*obj\Ptr)
	Case #PB_UTF8
		StrMem = 0
		PokeS(@StrMem, Chr(*obj\Value), 1, *obj\Encoding)
		*obj\Ptr + MemoryStringLength(@StrMem, *obj\Encoding | #PB_ByteLength)
		*obj\Value = Asc(PeekS(*obj\Ptr, 1, *obj\Encoding))
	EndSelect
	Select *obj\Value
	Case 10 ; '\n'
		; handle Windows new-line
		If LastValue <> 13 ; '\r'
			*obj\Pos\Line + 1
			*obj\Pos\Column = 1
		EndIf
	Case 13 ; '\r'
		*obj\Pos\Line + 1
		*obj\Pos\Column = 1
	Default
		*obj\Pos\Column + 1
	EndSelect
	*obj\Pos\Character + 1
EndProcedure


; Returns the value at the current iterator position.
;
; @param[in,out] *obj - object
; @return value at current position
Procedure.u GetValue(*obj.CStringIteratorCAttributes)
	ProcedureReturn *obj\Value
EndProcedure


; Returns the current position.
;
; @param[in,out] *obj - object
; @return current position
Procedure.i GetPos(*obj.CStringIteratorCAttributes)
	ProcedureReturn *obj + OffsetOf(CStringIteratorCAttributes\Pos)
EndProcedure


; Checks whether the left-hand and right-hand iterator are equal.
;
; @param[in] *lhs - left-hand statement
; @param[in] *lhs - right-hand statement
; @return true if equal, else false
Procedure.i Equal(*lhs.CStringIteratorCAttributes, *rhs.CStringIteratorCAttributes)
	If *lhs = *rhs
		ProcedureReturn #True
	ElseIf *lhs\Ptr = #Null
		If *rhs\Ptr = #Null
			ProcedureReturn #True
		ElseIf *rhs\Value = 0
			ProcedureReturn #True
		Else
			ProcedureReturn #False
		EndIf
	ElseIf *rhs\Ptr = #Null
		If *lhs\Ptr = #Null
			ProcedureReturn #True
		ElseIf *lhs\Value = 0
			ProcedureReturn #True
		Else
			ProcedureReturn #False
		EndIf
	ElseIf *lhs\Ptr = *rhs\Ptr
		ProcedureReturn #True
	Else
		ProcedureReturn #False
	EndIf
EndProcedure


; Clones the operator and returns the cloned instance.
;
; @param[in,out] *obj - object
; @return cloned instance
Procedure.i Clone(*obj.CStringIteratorCAttributes)
	*clone.CStringIteratorCAttributes = AllocateMemory(SizeOf(CStringIteratorCAttributes))
	If *clone = #Null
		ProcedureReturn #Null
	EndIf
	CopyMemory(*obj, *clone, SizeOf(CStringIteratorCAttributes))
	ProcedureReturn *clone
EndProcedure


; Deletes the iterator instance.
;
; @param[in,out] *obj - object
Procedure Delete(*obj.CStringIteratorCAttributes)
	If *obj <> #Null
		FreeMemory(*obj)
	EndIf
EndProcedure


DataSection
	CStringIteratorCVTable: ;- virtual function table
		Data.i @Forward()
		Data.i @GetValue()
		Data.i @GetPos()
		Data.i @Equal()
		Data.i @Clone()
		Data.i @Delete()
EndDataSection


EndModule ; CStringIteratorC
; IDE Options = PureBasic 5.45 LTS (Windows - x64)
; CursorPosition = 3
; Folding = ---
; EnableUnicode
; EnableXP
; HideErrorLog