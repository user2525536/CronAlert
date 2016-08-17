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


DeclareModule ITextParser
UseModule IIteratorC


Structure MapItem
	key.s
	value.i
EndStructure


Prototype.i ITextParserCharCallback(check.u)


; Unicode character parser
Interface ITextParser
	Char.i(*out.Unicode = #Null)
	CharVal.i(check.u, *out.Unicode = #Null)
	Cntrl.i(*out.Unicode = #Null)
	PrintC.i(*out.Unicode = #Null)
	WSpace.i(*out.Unicode = #Null)
	Blank.i(*out.Unicode = #Null)
	Graph.i(*out.Unicode = #Null)
	Punct.i(*out.Unicode = #Null)
	AlNum.i(*out.Unicode = #Null)
	AlphaC.i(*out.Unicode = #Null)
	Upper.i(*out.Unicode = #Null)
	Lower.i(*out.Unicode = #Null)
	Digit.i(*out.Unicode = #Null)
	XDigit.i(*out.Unicode = #Null)
	CharCall.i(check.ITextParserCharCallback, *out.Unicode = #Null)
	CharRange.i(checkFrom.u, checkTo.u, *out.Unicode = #Null)
	CharSet.i(set.s, *out.Unicode = #Null)
	CharSetI.i(set.s, *out.Unicode = #Null)
	String.i(check.s, *out.String = #Null)
	StringI.i(check.s, *out.String = #Null)
	StringUntil.i(string.s, *out.String = #Null)
	StringUntilI.i(string.s, *out.String = #Null)
	StringUntilChar.i(string.s, *out.String = #Null)
	StringUntilCharI.i(string.s, *out.String = #Null)
	StringUntilEol.i(*out.String = #Null)
	Skip.i(string.s)
	SkipUntil.i(string.s)
	Match.i(Array value.MapItem(1), count.i, *out.Integer = #Null)
	MatchI.i(Array value.MapItem(1), count.i, *out.Integer = #Null)
	Eol.i()
	Eoi.i()
	Boolean.i(*out.Integer = #Null)
	BooleanVal.i(check.i, *out.Integer = #Null)
	Num.i(*out.Integer = #Null, signed.i = #True)
	NumQ.i(*out.Quad = #Null, signed.i = #True)
	NumF.i(*out.Float = #Null, signed.i = #True)
	NumD.i(*out.Double = #Null, signed.i = #True)
	NumVal.i(check.i, *out.Integer = #Null, signed.i = #True)
	NumQVal.i(check.q, *out.Quad = #Null, signed.i = #True)
	NumFVal.i(check.f, *out.Float = #Null, signed.i = #True)
	NumDVal.i(check.d, *out.Double = #Null, signed.i = #True)
	NumHex.i(*out.Integer = #Null)
	NumQHex.i(*out.Quad = #Null)
	NumHexVal.i(check.i, *out.Integer = #Null)
	NumQHexVal.i(check.q, *out.Quad = #Null)
	GetComma.u()
	SetComma(value.u)
	GetNumSep.u()
	SetNumSep(value.u = 0)
	CloneStartIterator.i()
	GetStartIterator.i()
	SetStartIterator(*newPos.IIteratorC)
	GetEndIterator.i()
	SetEndIterator(*newPos.IIteratorC)
	Delete()
EndInterface


EndDeclareModule ; ITextParser


Module ITextParser
EndModule ; ITextParser
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 69
; FirstLine = 44
; Folding = -
; EnableUnicode
; EnableXP
; HideErrorLog