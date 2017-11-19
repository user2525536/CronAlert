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
XIncludeFile "ITextParser.pbi"
XIncludeFile "IIteratorC.pbi"


DeclareModule CTextParser
UseModule IIteratorC


; *start and *end will be managed by CTextParser and are invalid after calling this function
; use \GetStartIterator and \GetEndIterator to access the current iterator
; each call to a parsing function may invalidate these iterators again
Declare.i Create(*start.IIteratorC, *end.IIteratorC)


EndDeclareModule ; CTextParser


Module CTextParser
UseModule IIteratorC
UseModule ITextParser


; Checks whether the parser has reached the end-of-input.
; The function will return with false in this case.
Macro CheckEnd
 If *obj\Start\Equal(*obj\End)
 	ProcedureReturn #False
 EndIf
EndMacro


EnumerationBinary
	#CharIsCntrl
	#CharIsWSpace
	#CharIsBlank
	#CharIsPrintC
	#CharIsGraph
	#CharIsPunct
	#CharIsAlphaC
	#CharIsAlNum
	#CharIsUpper
	#CharIsLower
	#CharIsDigit
	#CharIsXDigit
EndEnumeration


Structure CTextParserAttributes
	VTablePtr.i
	*Start.IIteratorC
	*End.IIteratorC
	Comma.u
	NumSep.u
EndStructure


; Creates a new CTextParser instance conforming the ITextParser interface.
;
; @param[in] *start - start character iterator
; @param[in] *end - end character iterator
; @return created CTextParser instance or null on error
Procedure.i Create(*start.IIteratorC, *end.IIteratorC)
	*obj.CTextParserAttributes = AllocateMemory(SizeOf(CTextParserAttributes))
	If *obj = #Null
		ProcedureReturn #Null
	EndIf
	*obj\VTablePtr = ?CTextParserVTable
	*obj\Start = *start
	*obj\End = *end
	*obj\Comma = '.'
	*obj\NumSep = ','
	ProcedureReturn *obj
EndProcedure


; Consumes a single character and outputs its value.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. on end-of-input)
Procedure.i Char(*obj.CTextParserAttributes, *out.Unicode = #Null)
	CheckEnd
	If *out <> #Null
		*out\u = *obj\Start\GetValue()
	EndIf
	*obj\Start\Forward()
	ProcedureReturn #True
EndProcedure


; Consumes a single character and outputs its value if the character matches the given value.
;
; @param[in,out] *obj - object
; @param[in] check - compare against this character value
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. on end-of-input)
Procedure.i CharVal(*obj.CTextParserAttributes, check.u, *out.Unicode = #Null)
	CheckEnd
	If *obj\Start\GetValue() <> check
		ProcedureReturn #False
	EndIf
	If *out <> #Null
		*out\u = *obj\Start\GetValue()
	EndIf
	*obj\Start\Forward()
	ProcedureReturn #True
EndProcedure


; Macro to define character class parsers.
; The resulting functions work like Char() but limit the possible input by the given
; character class.
;
; @param[in] Type - character class type
Macro DefineCharTypeProcedure(Type)
	Procedure.i Type(*obj.CTextParserAttributes, *out.Unicode = #Null)
		Protected.u value
		CheckEnd
		value = *obj\Start\GetValue()
		If value > 127
			ProcedureReturn #False
		EndIf
		If PeekW(?CTextParserAsciiClass + (SizeOf(Word) * value)) & #CharIs#Type <> #CharIs#Type
			ProcedureReturn #False
		EndIf
		If *out <> #Null
			*out\u = value
		EndIf
		*obj\Start\Forward()
		ProcedureReturn #True
	EndProcedure
EndMacro

DefineCharTypeProcedure(Cntrl) ;- CTextParser::Cntrl
DefineCharTypeProcedure(PrintC) ;- CTextParser::PrintC
DefineCharTypeProcedure(WSpace) ;- CTextParser::WSpace
DefineCharTypeProcedure(Blank) ;- CTextParser::Blank
DefineCharTypeProcedure(Graph) ;- CTextParser::Graph
DefineCharTypeProcedure(Punct) ;- CTextParser::Punct
DefineCharTypeProcedure(AlNum) ;- CTextParser::AlNum
DefineCharTypeProcedure(AlphaC) ;- CTextParser::AlphaC
DefineCharTypeProcedure(Upper) ;- CTextParser::Upper
DefineCharTypeProcedure(Lower) ;- CTextParser::Lower
DefineCharTypeProcedure(Digit) ;- CTextParser::Digit
DefineCharTypeProcedure(XDigit) ;- CTextParser::XDigit

UndefineMacro DefineCharTypeProcedure


; Consumes a single character and outputs its value if the
; callback function returns true For the given character value.
;
; @param[in,out] *obj - object
; @param[in] check - callback function which checks the given character value
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. on end-of-input)
Procedure.i CharCall(*obj.CTextParserAttributes, check.ITextParserCharCallback, *out.Unicode = #Null)
	Protected.u value
	CheckEnd
	If check = #Null
		ProcedureReturn #False
	EndIf
	value = *obj\Start\GetValue()
	If check(value) <> #True
		ProcedureReturn #False
	EndIf
	If *out <> #Null
		*out\u = value
	EndIf
	*obj\Start\Forward()
	ProcedureReturn #True
EndProcedure


; Consumes a single character and outputs its value if the character is within the given range.
;
; @param[in,out] *obj - object
; @param[in] checkFrom - compare against this lower bound
; @param[in] checkTo - compare against this upper bound
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. on end-of-input)
Procedure.i CharRange(*obj.CTextParserAttributes, checkFrom.u, checkTo.u, *out.Unicode = #Null)
	Protected.u value
	CheckEnd
	value = *obj\Start\GetValue()
	If value < checkFrom Or value > checkTo
		ProcedureReturn #False
	EndIf
	If *out <> #Null
		*out\u = value
	EndIf
	*obj\Start\Forward()
	ProcedureReturn #True
EndProcedure


; Consumes a single character and outputs its value if the character is in the given set.
;
; @param[in,out] *obj - object
; @param[in] check - test against this set of characters
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. on end-of-input)
Procedure.i CharSet(*obj.CTextParserAttributes, check.s, *out.Unicode = #Null)
	Protected.u value
	CheckEnd
	value = *obj\Start\GetValue()
	If FindString(check, Chr(value)) = 0
		ProcedureReturn #False
	EndIf
	If *out <> #Null
		*out\u = value
	EndIf
	*obj\Start\Forward()
	ProcedureReturn #True
EndProcedure


; Consumes a single character and outputs its value if the character is in the given set.
; The comparison is done case-insensitive.
;
; @param[in,out] *obj - object
; @param[in] check - test against this set of characters
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. on end-of-input)
Procedure.i CharSetI(*obj.CTextParserAttributes, check.s, *out.Unicode = #Null)
	Protected.u value
	CheckEnd
	value = *obj\Start\GetValue()
	If FindString(LCase(check), LCase(Chr(value))) = 0
		ProcedureReturn #False
	EndIf
	If *out <> #Null
		*out\u = value
	EndIf
	*obj\Start\Forward()
	ProcedureReturn #True
EndProcedure


; Consumes a string and outputs its value if the string matches the given one.
;
; @param[in,out] *obj - object
; @param[in] check - compare against this string
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. on end-of-input)
Procedure.i String(*obj.CTextParserAttributes, check.s, *out.String = #Null)
	Protected.i match, pos, maxPos
	Protected *checkPtr.Character
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	match = #True
	maxPos = Len(check)
	*checkPtr = @check
	For pos = 1 To maxPos
		If *obj\Start\Equal(*obj\End)
			match = #False
			Break
		EndIf
		If *obj\Start\GetValue() <> *checkPtr\c
			match = #False
			Break
		EndIf
		*checkPtr + SizeOf(Character)
		*obj\Start\Forward()
	Next
	If match <> #True
		Swap *oldStart, *obj\Start
	ElseIf *out <> #Null
		*out\s = check
	EndIf
	*oldStart\Delete()
	ProcedureReturn match
EndProcedure


; Consumes a string and outputs its value if the string matches the given one.
; The comparison is done case-insensitive.
;
; @param[in,out] *obj - object
; @param[in] check - compare against this string
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. on end-of-input)
Procedure.i StringI(*obj.CTextParserAttributes, check.s, *out.String = #Null)
	Protected.i match, pos, maxPos
	Protected *checkPtr.Character
	Protected.s result
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	match = #True
	maxPos = Len(check)
	*checkPtr = @check
	result = ""
	For pos = 1 To maxPos
		If *obj\Start\Equal(*obj\End)
			match = #False
			Break
		EndIf
		If LCase(Chr(*obj\Start\GetValue())) <> LCase(Chr(*checkPtr\c))
			match = #False
			Break
		EndIf
		result + Chr(*checkPtr\c)
		*checkPtr + SizeOf(Character)
		*obj\Start\Forward()
	Next
	If match <> #True
		Swap *oldStart, *obj\Start
	ElseIf *out <> #Null
		*out\s = result
	EndIf
	*oldStart\Delete()
	ProcedureReturn match
EndProcedure


; Consumes a string and outputs its value. All characters until the given string are consumed.
;
; @param[in,out] *obj - object
; @param[in] check - end condition as string
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if the end condition did not trigger)
Procedure.i StringUntil(*obj.CTextParserAttributes, string.s, *out.String = #Null)
	Protected.i result
	Protected.s resultStr
	Protected.IIteratorC *oldStart, *savedIt
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = #False
	While Not *obj\Start\Equal(*obj\End)
		*savedIt = *obj\Start\Clone()
		If String(*obj, string) = #True
			result = #True
			Swap *savedIt, *obj\Start
			*savedIt\Delete()
			Break
		EndIf
		*savedIt\Delete()
		resultStr + Chr(*obj\Start\GetValue())
		*obj\Start\Forward()
	Wend
	If result
		If *out <> #Null
			*out\s = resultStr
		EndIf
	Else
		Swap *oldStart, *obj\Start
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a string and outputs its value. All characters until the given string are consumed.
; The comparison is done case-insensitive.
;
; @param[in,out] *obj - object
; @param[in] check - end condition as string
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if the end condition did not trigger)
Procedure.i StringUntilI(*obj.CTextParserAttributes, string.s, *out.String = #Null)
	Protected.i result
	Protected.s resultStr
	Protected.IIteratorC *oldStart, *savedIt
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = #False
	While Not *obj\Start\Equal(*obj\End)
		*savedIt = *obj\Start\Clone()
		If StringI(*obj, string) = #True
			result = #True
			Swap *savedIt, *obj\Start
			*savedIt\Delete()
			Break
		EndIf
		*savedIt\Delete()
		resultStr + Chr(*obj\Start\GetValue())
		*obj\Start\Forward()
	Wend
	If result
		If *out <> #Null
			*out\s = resultStr
		EndIf
	Else
		Swap *oldStart, *obj\Start
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a string and outputs its value. All characters until the given character set is consumed.
;
; @param[in,out] *obj - object
; @param[in] check - end condition as character set
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if the end condition did not trigger)
Procedure.i StringUntilChar(*obj.CTextParserAttributes, string.s, *out.String = #Null)
	Protected.i result
	Protected.s resultStr
	Protected.IIteratorC *oldStart, *savedIt
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = #False
	While Not *obj\Start\Equal(*obj\End)
		*savedIt = *obj\Start\Clone()
		If CharSet(*obj, string) = #True
			result = #True
			Swap *savedIt, *obj\Start
			*savedIt\Delete()
			Break
		EndIf
		*savedIt\Delete()
		resultStr + Chr(*obj\Start\GetValue())
		*obj\Start\Forward()
	Wend
	If result
		If *out <> #Null
			*out\s = resultStr
		EndIf
	Else
		Swap *oldStart, *obj\Start
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a string and outputs its value. All characters until the given character set is consumed.
; The comparison is done case-insensitive.
;
; @param[in,out] *obj - object
; @param[in] check - end condition as character set
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if the end condition did not trigger)
Procedure.i StringUntilCharI(*obj.CTextParserAttributes, string.s, *out.String = #Null)
	Protected.i result
	Protected.s resultStr
	Protected.IIteratorC *oldStart, *savedIt
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = #False
	While Not *obj\Start\Equal(*obj\End)
		*savedIt = *obj\Start\Clone()
		If CharSetI(*obj, string) = #True
			result = #True
			Swap *savedIt, *obj\Start
			*savedIt\Delete()
			Break
		EndIf
		*savedIt\Delete()
		resultStr + Chr(*obj\Start\GetValue())
		*obj\Start\Forward()
	Wend
	If result
		If *out <> #Null
			*out\s = resultStr
		EndIf
	Else
		Swap *oldStart, *obj\Start
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a string and outputs its value. All characters until end-of-line or end-of-input.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if the end condition did not trigger)
Procedure.i StringUntilEol(*obj.CTextParserAttributes, *out.String = #Null)
	Protected.i result
	Protected.s resultStr
	Protected.IIteratorC *oldStart, *savedIt
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = #False
	While Not *obj\Start\Equal(*obj\End)
		Select *obj\Start\GetValue()
		Case 10, 13 ; '\n', '\r'
			Break
		EndSelect
		result = #True
		resultStr + Chr(*obj\Start\GetValue())
		*obj\Start\Forward()
	Wend
	If result
		If *out <> #Null
			*out\s = resultStr
		EndIf
	Else
		Swap *oldStart, *obj\Start
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes any of the characters in the given character set.
;
; @param[in,out] *obj - object
; @param[in] string - character set
; @return true on success, else false (e.g. if no character was skipped)
Procedure.i Skip(*obj.CTextParserAttributes, string.s)
	Protected.i result
	CheckEnd
	result = #False
	While Not *obj\Start\Equal(*obj\End) And FindString(string, Chr(*obj\Start\GetValue())) <> 0
		result = #True
		*obj\Start\Forward()
	Wend
	ProcedureReturn result
EndProcedure


; Consumes any until a character of the given character set was found or end-of-input.
;
; @param[in,out] *obj - object
; @param[in] string - character set
; @return true on success, else false (e.g. if no character was skipped)
Procedure.i SkipUntil(*obj.CTextParserAttributes, string.s)
	Protected.i result
	Protected.IIteratorC *it
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	result = #False
	While Not *it\Equal(*obj\End)
		If FindString(string, Chr(*it\GetValue())) <> 0
			result = #True
			Break
		EndIf
		*it\Forward()
	Wend
	If result
		Swap *it, *obj\Start
	EndIf
	*it\Delete()
	ProcedureReturn result
EndProcedure


; Consumes the shortest match of the given map.
; The elements of the given array/map are assumed to be sorted by key.
;
; @param[in,out] *obj - object
; @param[in] value - possible matches
; @param[in] count - number of possible matches
; @param[in] *out - outputs the associated value of the matched element (disabled by default)
; @return true on success, else false (e.g. if no match was found)
Procedure.i Match(*obj.CTextParserAttributes, Array value.MapItem(1), count.i, *out.Integer = #Null)
	Protected.s expr
	Protected.i result, i, found
	Protected.IIteratorC *it
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	i = 0
	expr = Chr(*it\GetValue())
	found = #False
	While i < count And Not *it\Equal(*obj\End)
		Select CompareMemoryString(@expr, @value(i)\key, #PB_String_CaseSensitive)
		Case #PB_String_Lower
			If CompareMemoryString(@expr, @value(i)\key, #PB_String_CaseSensitive, Len(expr)) = #PB_String_Equal
				*it\Forward()
				expr + Chr(*it\GetValue())
			Else
				Break
			EndIf
		Case #PB_String_Equal
			found = #True
			If *out <> #Null
				*out\i = value(i)\value
			EndIf
			Break
		Case #PB_String_Greater
			i + 1
		EndSelect
	Wend
	If found = #True
		*it\Forward()
		Swap *it, *obj\Start
	EndIf
	*it\Delete()
	ProcedureReturn found
EndProcedure


; Consumes the shortest match of the given map.
; The elements of the given array/map are assumed to be sorted by key.
; The comparison is done case-insensitive.
;
; @param[in,out] *obj - object
; @param[in] value - possible matches
; @param[in] count - number of possible matches
; @param[in] *out - outputs the associated value of the matched element (disabled by default)
; @return true on success, else false (e.g. if no match was found)
Procedure.i MatchI(*obj.CTextParserAttributes, Array value.MapItem(1), count.i, *out.Integer = #Null)
	Protected.s expr
	Protected.i result, i, found
	Protected.IIteratorC *it
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	i = 0
	expr = Chr(*it\GetValue())
	found = #False
	While i < count And Not *it\Equal(*obj\End)
		Select CompareMemoryString(@expr, @value(i)\key, #PB_String_NoCase)
		Case #PB_String_Lower
			If CompareMemoryString(@expr, @value(i)\key, #PB_String_NoCase, Len(expr)) = #PB_String_Equal
				*it\Forward()
				expr + Chr(*it\GetValue())
			Else
				Break
			EndIf
		Case #PB_String_Equal
			found = #True
			If *out <> #Null
				*out\i = value(i)\value
			EndIf
			Break
		Case #PB_String_Greater
			i + 1
		EndSelect
	Wend
	If found = #True
		*it\Forward()
		Swap *it, *obj\Start
	EndIf
	*it\Delete()
	ProcedureReturn found
EndProcedure


; Consumes the end-of-line.
;
; @param[in,out] *obj - object
; @return true on success, else false (e.g. if no end-of-line was found)
Procedure.i Eol(*obj.CTextParserAttributes)
	Protected.i result
	Protected.IIteratorC *it
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	result = #True
	Select *it\GetValue()
	Case 10 ; '\n'
		*it\Forward()
	Case 13 ; '\r'
		*it\Forward()
		If Not *it\Equal(*obj\End) And *it\GetValue() = 10 ; '\n'
			*it\Forward()
		EndIf
	Default
		result = #False
	EndSelect
	If result
		Swap *it, *obj\Start
	EndIf
	*it\Delete()
	ProcedureReturn result
EndProcedure


; Consumes the end-of-input.
;
; @param[in,out] *obj - object
; @return true on success, else false (e.g. if no end-of-input was found)
Procedure.i Eoi(*obj.CTextParserAttributes)
	If *obj\Start\Equal(*obj\End)
		ProcedureReturn #True
	EndIf
	ProcedureReturn #False
EndProcedure


; Consumes a boolean value. This can be "true" or "false" in any case form.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if parsing failed)
Procedure.i Boolean(*obj.CTextParserAttributes, *out.Integer = #Null)
	Protected Dim matching.MapItem(1)
	matching(0)\key = "false"
	matching(0)\value = #False
	matching(1)\key = "true"
	matching(1)\value = #True
	ProcedureReturn MatchI(*obj, matching(), 2, *out)
EndProcedure


; Consumes a boolean value. This can be "true" or "false" in any case form.
; The input is only consumed if the parsed value matches the given one.
;
; @param[in,out] *obj - object
; @param[in] check - compare against this value
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if parsing failed)
Procedure.i BooleanVal(*obj.CTextParserAttributes, check.i, *out.Integer = #Null)
	Protected Dim matching.MapItem(1)
	Protected.i resultValue, result
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	matching(0)\key = "false"
	matching(0)\value = #False
	matching(1)\key = "true"
	matching(1)\value = #True
	result = MatchI(*obj, matching(), 2, @resultValue)
	If result = #True And resultValue = check
		If *out <> #Null
			*out\i = resultValue
		EndIf
	Else
		Swap *oldStart, *obj\Start
		result = #False
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a number (signed integer) value.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @param[in] signed - set true to allow signed numbers (enabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i Num(*obj.CTextParserAttributes, *out.Integer = #Null, signed.i = #True)
	Protected.i numSign, numVal
	Protected.i result
	Protected.IIteratorC *it
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	; parse sign
	numSign = 1
	If signed
		Select *it\GetValue()
		Case '+'
			numSign = 1
			*it\Forward()
		Case '-'
			numSign = -1
			*it\Forward()
		EndSelect
	EndIf
	; parse leading zeros
	result = #False
	While Not *it\Equal(*obj\End) And *it\GetValue() = '0'
		result = #True
		*it\Forward()
	Wend
	; parse number
	numVal = 0
	While Not *it\Equal(*obj\End)
		If *it\GetValue() >= '0' And *it\GetValue() <= '9'
			numVal = (numVal * 10) + (*it\GetValue() - '0')
			result = #True
			*it\Forward()
		ElseIf *obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep
			*it\Forward()
		Else
			Break
		EndIf
	Wend
	If result
		If *out <> #Null
			*out\i = numSign * numVal
		EndIf
		Swap *it, *obj\Start
	EndIf
	*it\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a number (signed integer) value.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @param[in] signed - set true to allow signed numbers (enabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumQ(*obj.CTextParserAttributes, *out.Quad = #Null, signed.i = #True)
	Protected.q numSign, numVal
	Protected.i result
	Protected.IIteratorC *it
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	; parse sign
	numSign = 1
	If signed
		Select *it\GetValue()
		Case '+'
			numSign = 1
			*it\Forward()
		Case '-'
			numSign = -1
			*it\Forward()
		EndSelect
	EndIf
	; parse leading zeros
	result = #False
	While Not *it\Equal(*obj\End) And (*it\GetValue() = '0' Or (*obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep))
		result = #True
		*it\Forward()
	Wend
	; parse number
	numVal = 0
	While Not *it\Equal(*obj\End)
		If *it\GetValue() >= '0' And *it\GetValue() <= '9'
			numVal = (numVal * 10) + (*it\GetValue() - '0')
			result = #True
			*it\Forward()
		ElseIf *obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep
			*it\Forward()
		Else
			Break
		EndIf
	Wend
	If result
		If *out <> #Null
			*out\q = numSign * numVal
		EndIf
		Swap *it, *obj\Start
	EndIf
	*it\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a floating number value with single precision.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @param[in] signed - set true to allow signed numbers (enabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumF(*obj.CTextParserAttributes, *out.Float = #Null, signed.i = #True)
	Protected.i numSign, numVal, numDigits, digits, expSign, expVal
	Protected.i result, hasExp
	Protected.IIteratorC *it, *expIt
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	; parse sign
	numSign = 1
	numDigits = 0
	expSign = 1
	expVal = 0
	hasExp = #False
	If signed
		Select *it\GetValue()
		Case '+'
			numSign = 1
			*it\Forward()
		Case '-'
			numSign = -1
			*it\Forward()
		EndSelect
	EndIf
	; parse leading zeros
	result = #False
	While Not *it\Equal(*obj\End) And (*it\GetValue() = '0' Or (*obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep))
		result = #True
		*it\Forward()
	Wend
	; parse integer part
	numVal = 0
	While Not *it\Equal(*obj\End)
		If *it\GetValue() >= '0' And *it\GetValue() <= '9'
			numVal = (numVal * 10) + (*it\GetValue() - '0')
			numDigits + 1
			result = #True
			*it\Forward()
		ElseIf *obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep
			*it\Forward()
		Else
			Break
		EndIf
	Wend
	digits = numDigits
	; parse fraction part
	If Not *it\Equal(*obj\End) And *it\GetValue() = *obj\Comma
		*it\Forward()
		While Not *it\Equal(*obj\End) And digits < 19
			If *it\GetValue() >= '0' And *it\GetValue() <= '9'
				numVal = (numVal * 10) + (*it\GetValue() - '0')
				digits + 1
				result = #True
				*it\Forward()
			ElseIf *obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep
				*it\Forward()
			Else
				Break
			EndIf
		Wend
	EndIf
	; parse exponent part (only if we had a number)
	If result
		*expIt = *it\Clone()
		If *expIt = #Null
			*it\Delete()
			ProcedureReturn #False
		EndIf
		If Not *it\Equal(*obj\End) And (*it\GetValue() = 'e' Or *it\GetValue() = 'E')
			*it\Forward()
			; parse sign
			expSign = 1
			Select *it\GetValue()
			Case '+'
				expSign = 1
				*it\Forward()
			Case '-'
				expSign = -1
				*it\Forward()
			EndSelect
			; parse leading zeros
			While Not *it\Equal(*obj\End) And *it\GetValue() = '0'
				*it\Forward()
			Wend
			; parse integer part
			expVal = 0
			While Not *it\Equal(*obj\End) And *it\GetValue() >= '0' And *it\GetValue() <= '9'
				expVal = (expVal * 10) + (*it\GetValue() - '0')
				hasExp = #True
				*it\Forward()
			Wend
		EndIf
		If Not hasExp
			Swap *expIt, *it
		EndIf
		*expIt\Delete()
	EndIf
	If result
		If *out <> #Null
			*out\f = numSign * numVal * Pow(10, (numDigits - digits) + (expSign * expVal))
		EndIf
		Swap *it, *obj\Start
	EndIf
	*it\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a floating number value with double precision.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @param[in] signed - set true to allow signed numbers (enabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumD(*obj.CTextParserAttributes, *out.Double = #Null, signed.i = #True)
	Protected.q numSign, numVal, numDigits, digits, expSign, expVal
	Protected.i result, hasExp
	Protected.IIteratorC *it, *expIt
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	; parse sign
	numSign = 1
	numDigits = 0
	expSign = 1
	expVal = 0
	hasExp = #False
	If signed
		Select *it\GetValue()
		Case '+'
			numSign = 1
			*it\Forward()
		Case '-'
			numSign = -1
			*it\Forward()
		EndSelect
	EndIf
	; parse leading zeros
	result = #False
	While Not *it\Equal(*obj\End) And (*it\GetValue() = '0' Or (*obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep))
		result = #True
		*it\Forward()
	Wend
	; parse integer part
	numVal = 0
	While Not *it\Equal(*obj\End)
		If *it\GetValue() >= '0' And *it\GetValue() <= '9'
			numVal = (numVal * 10) + (*it\GetValue() - '0')
			numDigits + 1
			result = #True
			*it\Forward()
		ElseIf *obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep
			*it\Forward()
		Else
			Break
		EndIf
	Wend
	digits = numDigits
	; parse fraction part
	If Not *it\Equal(*obj\End) And *it\GetValue() = *obj\Comma
		*it\Forward()
		While Not *it\Equal(*obj\End) And digits < 19
			If *it\GetValue() >= '0' And *it\GetValue() <= '9'
				numVal = (numVal * 10) + (*it\GetValue() - '0')
				digits + 1
				result = #True
				*it\Forward()
			ElseIf *obj\NumSep <> 0 And *it\GetValue() = *obj\NumSep
				*it\Forward()
			Else
				Break
			EndIf
		Wend
	EndIf
	; parse exponent part (only if we had a number)
	If result
		*expIt = *it\Clone()
		If *expIt = #Null
			*it\Delete()
			ProcedureReturn #False
		EndIf
		If Not *it\Equal(*obj\End) And (*it\GetValue() = 'e' Or *it\GetValue() = 'E')
			*it\Forward()
			; parse sign
			expSign = 1
			Select *it\GetValue()
			Case '+'
				expSign = 1
				*it\Forward()
			Case '-'
				expSign = -1
				*it\Forward()
			EndSelect
			; parse leading zeros
			While Not *it\Equal(*obj\End) And *it\GetValue() = '0'
				*it\Forward()
			Wend
			; parse integer part
			expVal = 0
			While Not *it\Equal(*obj\End) And *it\GetValue() >= '0' And *it\GetValue() <= '9'
				expVal = (expVal * 10) + (*it\GetValue() - '0')
				hasExp = #True
				*it\Forward()
			Wend
		EndIf
		If Not hasExp
			Swap *expIt, *it
		EndIf
		*expIt\Delete()
	EndIf
	If result
		If *out <> #Null
			*out\d = numSign * numVal * Pow(10, (numDigits - digits) + (expSign * expVal))
		EndIf
		Swap *it, *obj\Start
	EndIf
	*it\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a number (signed integer) value.
; The number is only consumed if it matches the given value
;
; @param[in,out] *obj - object
; @param[in] check - compare against this value
; @param[out] *out - pointer to the output variable (disabled by default)
; @param[in] signed - set true to allow signed numbers (enabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumVal(*obj.CTextParserAttributes, check.i, *out.Integer = #Null, signed.i = #True)
	Protected.i resultValue
	Protected.i result
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = Num(*obj, @resultValue, signed)
	If result = #True And resultValue = check
		If *out <> #Null
			*out\i = resultValue
		EndIf
	Else
		Swap *oldStart, *obj\Start
		result = #False
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a number (signed integer) value.
; The number is only consumed if it matches the given value
;
; @param[in,out] *obj - object
; @param[in] check - compare against this value
; @param[out] *out - pointer to the output variable (disabled by default)
; @param[in] signed - set true to allow signed numbers (enabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumQVal(*obj.CTextParserAttributes, check.q, *out.Quad = #Null, signed.i = #True)
	Protected.q resultValue
	Protected.i result
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = NumQ(*obj, @resultValue, signed)
	If result = #True And resultValue = check
		If *out <> #Null
			*out\q = resultValue
		EndIf
	Else
		Swap *oldStart, *obj\Start
		result = #False
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a floating number value with single precision.
; The number is only consumed if it matches the given value
;
; @param[in,out] *obj - object
; @param[in] check - compare against this value
; @param[out] *out - pointer to the output variable (disabled by default)
; @param[in] signed - set true to allow signed numbers (enabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumFVal(*obj.CTextParserAttributes, check.f, *out.Float = #Null, signed.i = #True)
	Protected.f resultValue
	Protected.i result
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = NumF(*obj, @resultValue, signed)
	If result = #True And Abs(resultValue - check) < 0.0000001
		If *out <> #Null
			*out\f = resultValue
		EndIf
	Else
		Swap *oldStart, *obj\Start
		result = #False
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a floating number value with double precision.
; The number is only consumed if it matches the given value
;
; @param[in,out] *obj - object
; @param[in] check - compare against this value
; @param[out] *out - pointer to the output variable (disabled by default)
; @param[in] signed - set true to allow signed numbers (enabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumDVal(*obj.CTextParserAttributes, check.d, *out.Double = #Null, signed.i = #True)
	Protected.d resultValue
	Protected.i result
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = NumD(*obj, @resultValue, signed)
	If result = #True And Abs(resultValue - check) < 0.0000001
		If *out <> #Null
			*out\d = resultValue
		EndIf
	Else
		Swap *oldStart, *obj\Start
		result = #False
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a hexadecimal coded integer value.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumHex(*obj.CTextParserAttributes, *out.Integer = #Null)
	Protected.i numVal
	Protected.i result
	Protected.IIteratorC *it
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	; parse leading zeros
	While Not *it\Equal(*obj\End) And *it\GetValue() = '0'
		*it\Forward()
	Wend
	; parse number
	result = #False
	numVal = 0
	While Not *it\Equal(*obj\End)
		Select *it\GetValue()
		Case '0' To '9'
			numVal = (numVal * 16) + (*it\GetValue() - '0')
		Case 'A' To 'F'
			numVal = (numVal * 16) + (*it\GetValue() + 10 - 'A')
		Case 'a' To 'f'
			numVal = (numVal * 16) + (*it\GetValue() + 10 - 'a')
		Default
			Break
		EndSelect
		result = #True
		*it\Forward()
	Wend
	If result
		If *out <> #Null
			*out\i = numVal
		EndIf
		Swap *it, *obj\Start
	EndIf
	ProcedureReturn result
EndProcedure


; Consumes a hexadecimal coded integer value.
;
; @param[in,out] *obj - object
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumQHex(*obj.CTextParserAttributes, *out.Quad = #Null)
	Protected.q numVal
	Protected.i result
	Protected.IIteratorC *it
	CheckEnd
	*it = *obj\Start\Clone()
	If *it = #Null
		ProcedureReturn #False
	EndIf
	; parse leading zeros
	While Not *it\Equal(*obj\End) And *it\GetValue() = '0'
		*it\Forward()
	Wend
	; parse number
	result = #False
	numVal = 0
	While Not *it\Equal(*obj\End)
		Select *it\GetValue()
		Case '0' To '9'
			numVal = (numVal * 16) + (*it\GetValue() - '0')
		Case 'A' To 'F'
			numVal = (numVal * 16) + (*it\GetValue() + 10 - 'A')
		Case 'a' To 'f'
			numVal = (numVal * 16) + (*it\GetValue() + 10 - 'a')
		Default
			Break
		EndSelect
		result = #True
		*it\Forward()
	Wend
	If result
		If *out <> #Null
			*out\q = numVal
		EndIf
		Swap *it, *obj\Start
	EndIf
	ProcedureReturn result
EndProcedure


; Consumes a hexadecimal coded integer value.
; The number is only consumed if it matches the given value
;
; @param[in,out] *obj - object
; @param[in] check - compare against this value
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumHexVal(*obj.CTextParserAttributes, check.i, *out.Integer = #Null)
	Protected.i resultValue
	Protected.i result
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = NumHex(*obj, @resultValue)
	If result = #True And resultValue = check
		If *out <> #Null
			*out\i = resultValue
		EndIf
	Else
		Swap *oldStart, *obj\Start
		result = #False
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Consumes a hexadecimal coded integer value.
; The number is only consumed if it matches the given value
;
; @param[in,out] *obj - object
; @param[in] check - compare against this value
; @param[out] *out - pointer to the output variable (disabled by default)
; @return true on success, else false (e.g. if parsing failed)
; @remarks The function does not handle number overflows.
Procedure.i NumQHexVal(*obj.CTextParserAttributes, check.i, *out.Quad = #Null)
	Protected.q resultValue
	Protected.i result
	Protected.IIteratorC *oldStart
	CheckEnd
	*oldStart = *obj\Start\Clone()
	If *oldStart = #Null
		ProcedureReturn #False
	EndIf
	result = NumQHex(*obj, @resultValue)
	If result = #True And resultValue = check
		If *out <> #Null
			*out\q = resultValue
		EndIf
	Else
		Swap *oldStart, *obj\Start
		result = #False
	EndIf
	*oldStart\Delete()
	ProcedureReturn result
EndProcedure


; Returns the used decimal comma character.
;
; @param[in] *obj - object
; @return decimal comma character
Procedure.u GetComma(*obj.CTextParserAttributes)
	ProcedureReturn *obj\Comma
EndProcedure


; Sets the decimal comma character.
;
; @param[in,out] *obj - object
; @param[in] value - set the decimal comma character to this value
Procedure SetComma(*obj.CTextParserAttributes, value.u)
	*obj\Comma = value
EndProcedure


; Returns the used number separater character.
;
; @param[in] *obj - object
; @return number separater character
Procedure.u GetNumSep(*obj.CTextParserAttributes)
	ProcedureReturn *obj\NumSep
EndProcedure


; Sets the number separater character.
;
; @param[in,out] *obj - object
; @param[in] value - set the number separater character to this value
Procedure SetNumSep(*obj.CTextParserAttributes, value.u = 0)
	*obj\NumSep = value
EndProcedure


; Clones the internal start iterator and returns it to the caller.
; The caller needs to call Delete() to free the returned iterator instance.
;
; @param[in,out] *obj - object
; @return cloned start iterator instance
Procedure.i CloneStartIterator(*obj.CTextParserAttributes)
	ProcedureReturn *obj\Start\Clone()
EndProcedure


; Returns the internal start iterator.
; A reference to the used iterator is returned.
; The actual iterator is still handled by this class
; and shall not be deleted outside of it
;
; @param[in,out] *obj - object
; @return the internal start iterator
Procedure.i GetStartIterator(*obj.CTextParserAttributes)
	ProcedureReturn *obj\Start
EndProcedure


; Sets the internal start iterator.
; The passed iterator will be managed by this class.
; Do not call Delete() for the passed iterator.
; 
; @param[in,out] *obj - object
; @param[in,out] *newPos - new start iterator
Procedure SetStartIterator(*obj.CTextParserAttributes, *newPos.IIteratorC)
	If *obj\Start <> #Null
		*obj\Start\Delete()
	EndIf
	*obj\Start = *newPos
EndProcedure


; Returns the internal end iterator.
; A reference to the used iterator is returned.
; The actual iterator is still handled by this class
; and shall not be deleted outside of it
;
; @param[in,out] *obj - object
; @return the internal end iterator
Procedure.i GetEndIterator(*obj.CTextParserAttributes)
	ProcedureReturn *obj\End
EndProcedure


; Sets the internal end iterator.
; The passed iterator will be managed by this class.
; Do not call Delete() for the passed iterator.
; 
; @param[in,out] *obj - object
; @param[in,out] *newPos - new end iterator
Procedure SetEndIterator(*obj.CTextParserAttributes, *newPos.IIteratorC)
	If *obj\End <> #Null
		*obj\End\Delete()
	EndIf
	*obj\End = *newPos
EndProcedure


; Deletes the parser instance together with its internal
; iterators.
;
; @param[in,out] *obj - object
Procedure Delete(*obj.CTextParserAttributes)
	If *obj <> #Null
		*obj\Start\Delete()
		*obj\End\Delete()
		FreeMemory(*obj)
	EndIf
EndProcedure


DataSection
	CTextParserVTable: ;- virtual function table
		Data.i @Char()
		Data.i @CharVal()
		Data.i @Cntrl()
		Data.i @PrintC()
		Data.i @WSpace()
		Data.i @Blank()
		Data.i @Graph()
		Data.i @Punct()
		Data.i @AlNum()
		Data.i @AlphaC()
		Data.i @Upper()
		Data.i @Lower()
		Data.i @Digit()
		Data.i @XDigit()
		Data.i @CharCall()
		Data.i @CharRange()
		Data.i @CharSet()
		Data.i @CharSetI()
		Data.i @String()
		Data.i @StringI()
		Data.i @StringUntil()
		Data.i @StringUntilI()
		Data.i @StringUntilChar()
		Data.i @StringUntilCharI()
		Data.i @StringUntilEol()
		Data.i @Skip()
		Data.i @SkipUntil()
		Data.i @Match()
		Data.i @MatchI()
		Data.i @Eol()
		Data.i @Eoi()
		Data.i @Boolean()
		Data.i @BooleanVal()
		Data.i @Num()
		Data.i @NumQ()
		Data.i @NumF()
		Data.i @NumD()
		Data.i @NumVal()
		Data.i @NumQVal()
		Data.i @NumFVal()
		Data.i @NumDVal()
		Data.i @NumHex()
		Data.i @NumQHex()
		Data.i @NumHexVal()
		Data.i @NumQHexVal()
		Data.i @GetComma()
		Data.i @SetComma()
		Data.i @GetNumSep()
		Data.i @SetNumSep()
		Data.i @CloneStartIterator()
		Data.i @GetStartIterator()
		Data.i @SetStartIterator()
		Data.i @GetEndIterator()
		Data.i @SetEndIterator()
		Data.i @Delete()
	CTextParserAsciiClass:
		Data.w #CharIsCntrl ; 0 ^@
		Data.w #CharIsCntrl ; 1 ^A
		Data.w #CharIsCntrl ; 2 ^B
		Data.w #CharIsCntrl ; 3 ^C
		Data.w #CharIsCntrl ; 4 ^D
		Data.w #CharIsCntrl ; 5 ^E
		Data.w #CharIsCntrl ; 6 ^F
		Data.w #CharIsCntrl ; 7 ^G
		Data.w #CharIsCntrl ; 8 ^H
		Data.w #CharIsWSpace|#CharIsBlank|#CharIsCntrl ; 9 ^I
		Data.w #CharIsWSpace|#CharIsCntrl ; 10 ^J
		Data.w #CharIsWSpace|#CharIsCntrl ; 11 ^K
		Data.w #CharIsWSpace|#CharIsCntrl ; 12 ^L
		Data.w #CharIsWSpace|#CharIsCntrl ; 13 ^M
		Data.w #CharIsCntrl ; 14 ^N
		Data.w #CharIsCntrl ; 15 ^O
		Data.w #CharIsCntrl ; 16 ^P
		Data.w #CharIsCntrl ; 17 ^Q
		Data.w #CharIsCntrl ; 18 ^R
		Data.w #CharIsCntrl ; 19 ^S
		Data.w #CharIsCntrl ; 20 ^T
		Data.w #CharIsCntrl ; 21 ^U
		Data.w #CharIsCntrl ; 22 ^V
		Data.w #CharIsCntrl ; 23 ^W
		Data.w #CharIsCntrl ; 24 ^X
		Data.w #CharIsCntrl ; 25 ^Y
		Data.w #CharIsCntrl ; 26 ^Z
		Data.w #CharIsCntrl ; 27 ^[
		Data.w #CharIsCntrl ; 28 ^\
		Data.w #CharIsCntrl ; 29 ^]
		Data.w #CharIsCntrl ; 30 ^^
		Data.w #CharIsCntrl ; 31 ^_
		Data.w #CharIsWSpace|#CharIsPrintC|#CharIsBlank ; 32  
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 33 !
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 34 "
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 35 #
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 36 $
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 37 %
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 38 &
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 39 '
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 40 (
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 41 )
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 42 *
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 43 +
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 44 ,
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 45 -
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 46 .
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 47 /
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 48 0
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 49 1
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 50 2
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 51 3
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 52 4
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 53 5
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 54 6
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 55 7
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 56 8
		Data.w #CharIsDigit|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 57 9
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 58 :
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 59 ;
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 60 <
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 61 =
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 62 >
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 63 ?
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 64 @
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 65 A
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 66 B
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 67 C
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 68 D
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 69 E
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 70 F
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 71 G
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 72 H
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 73 I
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 74 J
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 75 K
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 76 L
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 77 M
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 78 N
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 79 O
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 80 P
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 81 Q
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 82 R
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 83 S
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 84 T
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 85 U
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 86 V
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 87 W
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 88 X
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 89 Y
		Data.w #CharIsUpper|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 90 Z
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 91 [
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 92 \
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 93 ]
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 94 ^
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 95 _
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 96 `
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 97 a
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 98 b
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 99 c
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 100 d
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 101 e
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsXDigit|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 102 f
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 103 g
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 104 h
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 105 i
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 106 j
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 107 k
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 108 l
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 109 m
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 110 n
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 111 o
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 112 p
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 113 q
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 114 r
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 115 s
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 116 t
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 117 u
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 118 v
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 119 w
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 120 x
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 121 y
		Data.w #CharIsLower|#CharIsAlphaC|#CharIsPrintC|#CharIsGraph|#CharIsAlNum ; 122 z
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 123 {
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 124 |
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 125 }
		Data.w #CharIsPrintC|#CharIsGraph|#CharIsPunct ; 126 ~
		Data.w #CharIsCntrl ; 127 ^?
EndDataSection


EndModule ; CTextParser
; IDE Options = PureBasic 5.45 LTS (Windows - x64)
; CursorPosition = 3
; Folding = ---------
; EnableUnicode
; EnableXP
; HideErrorLog