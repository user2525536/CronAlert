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

XIncludeFile "IIteratorC.pbi"


DeclareModule CFileIteratorC


Declare.i Create(File.s = "")


EndDeclareModule ; CFileIteratorC


Module CFileIteratorC
UseModule IIteratorC


Structure CFileIteratorCAttributes
	VTablePtr.i
	FileId.i
	Pos.IteratorPos
	BytePos.q
	Encoding.i
	Value.u
	*RefCounter.Integer
EndStructure


; Creates a new CFileIteratorC instance which conforms to the IIteratorC interface.
;
; @param[in] File - optional source file (no file for end iterator)
; @return CFileIteratorC instance
Procedure.i Create(File.s = "")
	*obj.CFileIteratorCAttributes = AllocateMemory(SizeOf(CFileIteratorCAttributes))
	If *obj = #Null
		ProcedureReturn #Null
	EndIf
	*refCounter.Integer = AllocateMemory(SizeOf(Integer))
	If *refCounter = #Null
		FreeMemory(*obj)
		ProcedureReturn #Null
	EndIf
	*obj\VTablePtr = ?CFileIteratorCVTable
	If File = ""
		; end of file iterator
		*obj\Pos\ValidFields = #IteratorPos_None
		*obj\FileId = 0
		*obj\BytePos = -1
	Else
		*obj\FileId = ReadFile(#PB_Any, File)
		If Not *obj\FileId
			FreeMemory(*obj)
			FreeMemory(*refCounter)
			ProcedureReturn #Null
		EndIf
		*obj\Pos\ValidFields = #IteratorPos_All
		*obj\Pos\File = File
		*obj\Pos\Line = 1
		*obj\Pos\Column = 1
		*obj\Pos\Character = 1
		*obj\BytePos = 0
		*obj\Encoding = ReadStringFormat(*obj\FileId)
		; default encoding to UTF8
		If *obj\Encoding = #PB_Ascii
			*obj\Encoding = #PB_UTF8
		EndIf
		*obj\Value = ReadCharacter(*obj\FileId, *obj\Encoding)
	EndIf
	*obj\RefCounter = *refCounter
	*obj\RefCounter\i = 1
	ProcedureReturn *obj
EndProcedure


; Moves the iterator one element towards the end.
; Bound checks are not performed.
;
; @param[in,out] *obj - object
Procedure Forward(*obj.CFileIteratorCAttributes)
	Protected LastValue.u
	If Loc(*obj\FileId) <> *obj\BytePos
		; correct file position to match iterator position
		FileSeek(*obj\FileId, *obj\BytePos, #PB_Absolute)
		ReadCharacter(*obj\FileId, *obj\Encoding)
	EndIf
	LastValue = *obj\Value
	*obj\BytePos = Loc(*obj\FileId)
	If Eof(*obj\FileId)
		*obj\BytePos = -1
	EndIf
	*obj\Value = ReadCharacter(*obj\FileId, *obj\Encoding)
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
Procedure.u GetValue(*obj.CFileIteratorCAttributes)
	ProcedureReturn *obj\Value
EndProcedure


; Returns the current position.
;
; @param[in,out] *obj - object
; @return current position
Procedure.i GetPos(*obj.CFileIteratorCAttributes)
	ProcedureReturn *obj + OffsetOf(CFileIteratorCAttributes\Pos)
EndProcedure


; Checks whether the left-hand and right-hand iterator are equal.
;
; @param[in] *lhs - left-hand statement
; @param[in] *lhs - right-hand statement
; @return true if equal, else false
Procedure.i Equal(*lhs.CFileIteratorCAttributes, *rhs.CFileIteratorCAttributes)
	If *lhs = *rhs
		ProcedureReturn #True
	ElseIf *lhs\BytePos = -1
		If *rhs\BytePos = -1
			ProcedureReturn #True
		Else
			ProcedureReturn #False
		EndIf
	ElseIf *rhs\BytePos = -1
		If *lhs\BytePos = -1
			ProcedureReturn #True
		Else
			ProcedureReturn #False
		EndIf
	ElseIf *lhs\BytePos = *rhs\BytePos And *lhs\Pos\File = *rhs\Pos\File
		ProcedureReturn #True
	Else
		ProcedureReturn #False
	EndIf
EndProcedure


; Clones the operator and returns the cloned instance.
;
; @param[in,out] *obj - object
; @return cloned instance
Procedure.i Clone(*obj.CFileIteratorCAttributes)
	*clone.CFileIteratorCAttributes = AllocateMemory(SizeOf(CFileIteratorCAttributes))
	If *clone = #Null
		ProcedureReturn #Null
	EndIf
	CopyMemory(*obj, *clone, SizeOf(CFileIteratorCAttributes))
	*clone\RefCounter\i + 1
	ProcedureReturn *clone
EndProcedure


; Deletes the iterator instance.
;
; @param[in,out] *obj - object
Procedure Delete(*obj.CFileIteratorCAttributes)
	If *obj <> #Null
		*obj\RefCounter\i - 1
		If *obj\RefCounter\i <= 0
			If *obj\FileId <> 0
				CloseFile(*obj\FileId)
			EndIf
			FreeMemory(*obj\RefCounter)
		EndIf
		FreeMemory(*obj)
	EndIf
EndProcedure


DataSection
	CFileIteratorCVTable: ;- virtual function table
		Data.i @Forward()
		Data.i @GetValue()
		Data.i @GetPos()
		Data.i @Equal()
		Data.i @Clone()
		Data.i @Delete()
EndDataSection


EndModule ; CFileIteratorC
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 34
; Folding = --
; EnableUnicode
; EnableXP
; HideErrorLog