XIncludeFile "CTextParser.pbi"
XIncludeFile "CFileIteratorC.pbi"
XIncludeFile "CStringIteratorC.pbi"
XIncludeFile "TextToSpeech.pbi"


UseModule IIteratorC
UseModule ITextParser


Global.i Count = 0, Passed = 0
Global.s MatchString = ""
Global Dim Keyword.MapItem(1)
Global Dim KeywordI.MapItem(1)

Keyword(0)\key = "ab"
Keyword(0)\value = 1
Keyword(1)\key = "AB"
Keyword(1)\value = 2

CopyArray(Keyword(), KeywordI())
SortStructuredArray(Keyword(), #PB_Sort_Ascending, OffsetOf(MapItem\key), #PB_String)
SortStructuredArray(KeywordI(), #PB_Sort_Ascending | #PB_Sort_NoCase, OffsetOf(MapItem\key), #PB_String)


Macro TestID
	MacroExpandedCount
EndMacro


Procedure.s StringFromRange(*start.IIteratorC, *end.IIteratorC)
	Protected.s result
	While Not *start\Equal(*end)
		result + Chr(*start\GetValue())
		*start\Forward()
	Wend
	ProcedureReturn result
EndProcedure


Procedure.i IsA(check.u)
	If check = 'a' Or check = 'A'
		ProcedureReturn #True
	EndIf
	ProcedureReturn #False
EndProcedure


Macro TestParserTrueId(ID, Function, TestString)
	Procedure.i TestParserTrue_#ID()
		Protected.i result
		Protected.s testStr = TestString
		*start.IIteratorC = CStringIteratorC::Create(@testStr)
		*end.IIteratorC = CStringIteratorC::Create()
		*parser.ITextParser = CTextParser::Create(*start, *end)
		result = *parser\Function
		*start = CStringIteratorC::Create(@testStr)
		*end = *parser\GetStartIterator()
		MatchString = StringFromRange(*start, *parser\GetStartIterator())
		*start\Delete()
		*parser\Delete()
		ProcedureReturn result
	EndProcedure
	Count + 1
	If TestParserTrue_#ID()
		PrintN(#PB_Compiler_Filename + ":" + Str(#PB_Compiler_Line) + ": Test Case #" + Str(ID) + ": PASSED (matched '" + MatchString + "')")
		Passed + 1
	Else
		PrintN(#PB_Compiler_Filename + ":" + Str(#PB_Compiler_Line) + ": Test Case #" + Str(ID) + ": FAILED (matched '" + MatchString + "')")
	EndIf
EndMacro


Macro TestParserTrue(Function, String)
	TestParserTrueId(TestID, Function, String)
EndMacro


Macro TestParserFalseId(ID, Function, TestString)
	Procedure.i TestParserFalse_#ID()
		Protected.i result
		Protected.s testStr = TestString
		*start.IIteratorC = CStringIteratorC::Create(@testStr)
		*end.IIteratorC = CStringIteratorC::Create()
		*parser.ITextParser = CTextParser::Create(*start, *end)
		result = *parser\Function
		*start = CStringIteratorC::Create(@testStr)
		*end = *parser\GetStartIterator()
		MatchString = StringFromRange(*start, *parser\GetStartIterator())
		*start\Delete()
		*parser\Delete()
		ProcedureReturn result
	EndProcedure
	Count + 1
	If TestParserFalse_#ID() = #False And MatchString = ""
		PrintN(#PB_Compiler_Filename + ":" + Str(#PB_Compiler_Line) + ": Test Case #" + Str(ID) + ": PASSED")
		Passed + 1
	Else
		PrintN(#PB_Compiler_Filename + ":" + Str(#PB_Compiler_Line) + ": Test Case #" + Str(ID) + ": FAILED (matched '" + MatchString + "')")
	EndIf
EndMacro


Macro TestParserFalse(Function, String)
	TestParserFalseId(TestID, Function, String)
EndMacro


OpenConsole()


;- CTextParser
TestParserTrue(Char(), "abc")
TestParserTrue(CharVal('a'), "abc")
TestParserTrue(Cntrl(), ~"\t")
TestParserTrue(PrintC(), "abc")
TestParserTrue(WSpace(), ~"\t")
TestParserTrue(Blank(), ~"\t")
TestParserTrue(Graph(), "+-*")
TestParserTrue(Punct(), "+-*")
TestParserTrue(AlNum(), "abc")
TestParserTrue(AlNum(), "123")
TestParserTrue(AlphaC(), "abc")
TestParserTrue(Upper(), "ABC")
TestParserTrue(Lower(), "abc")
TestParserTrue(Digit(), "123")
TestParserTrue(XDigit(), "abc")
TestParserTrue(CharCall(@IsA()), "abc")
TestParserTrue(CharRange('a', 'z'), "abc")
TestParserTrue(CharSet("abc"), "abc")
TestParserTrue(CharSetI("aBc"), "AbC")
TestParserTrue(String("lit"), "lit")
TestParserTrue(StringI("LiT"), "lit")
TestParserTrue(StringUntil("c"), "abc")
TestParserTrue(StringUntilI("C"), "abc")
TestParserTrue(StringUntilChar("c"), "abc")
TestParserTrue(StringUntilCharI("C"), "abc")
TestParserTrue(StringUntilEol(), "abc")
TestParserTrue(Skip("ab"), "abc")
TestParserTrue(SkipUntil("c"), "abc")
TestParserTrue(Match(Keyword(), 2), "abc")
TestParserTrue(MatchI(KeywordI(), 2), "abc")
TestParserTrue(Eol(), ~"\n")
TestParserTrue(Eoi(), "")
TestParserTrue(Boolean(), "true")
TestParserTrue(Boolean(), "false")
TestParserTrue(BooleanVal(#True), "true")
TestParserTrue(BooleanVal(#False), "false")
TestParserTrue(Num(), "123")
TestParserTrue(Num(), "0")
TestParserTrue(NumQ(), "123456789123456")
TestParserTrue(NumQ(), "0")
TestParserTrue(NumF(), "123.456")
TestParserTrue(NumF(), "0.0")
TestParserTrue(NumD(), "123.456789123456")
TestParserTrue(NumD(), "0.0")
TestParserTrue(NumVal(123), "123")
TestParserTrue(NumQVal(123456789123456), "123,456,789,123,456")
TestParserTrue(NumFVal(123.456E-2), "123.456E-2")
TestParserTrue(NumDVal(123.456E10), "123.456E10")
TestParserTrue(NumHex(), "1234ABCD")
TestParserTrue(NumQHex(), "1234456789ABCDEF")
TestParserTrue(NumHexVal($1234ABCD), "1234ABCD")
TestParserTrue(NumQHexVal($123456789ABCDEF0), "123456789ABCDEF0")

TestParserFalse(Char(), "")
TestParserFalse(CharVal('a'), "123")
TestParserFalse(Cntrl(), "abc")
TestParserFalse(PrintC(), Chr(3))
TestParserFalse(WSpace(), "abc")
TestParserFalse(Blank(), "abc")
TestParserFalse(Graph(), ~"\t")
TestParserFalse(Punct(), "abc")
TestParserFalse(AlNum(), "+-*")
TestParserFalse(AlphaC(), "123")
TestParserFalse(Upper(), "abc")
TestParserFalse(Lower(), "ABC")
TestParserFalse(Digit(), "abc")
TestParserFalse(XDigit(), "xyz")
TestParserFalse(CharCall(@IsA()), "cba")
TestParserFalse(CharRange('a', 'z'), "ABC")
TestParserFalse(CharSet("abc"), "ABC")
TestParserFalse(CharSetI("abc"), "DABC")
TestParserFalse(String("lit"), "LIT")
TestParserFalse(StringI("LiT"), "lat")
TestParserFalse(StringUntil("c"), "")
TestParserFalse(StringUntilI("C"), "")
TestParserFalse(StringUntilChar("c"), "")
TestParserFalse(StringUntilCharI("C"), "")
TestParserFalse(StringUntilEol(), "")
TestParserFalse(Skip("ab"), "cba")
TestParserFalse(SkipUntil("d"), "abc")
TestParserFalse(Match(Keyword(), 2), "Ab")
TestParserFalse(MatchI(KeywordI(), 2), "cb")
TestParserFalse(Eol(), " ")
TestParserFalse(Eoi(), " ")
TestParserFalse(Boolean(), "1")
TestParserFalse(Boolean(), "0")
TestParserFalse(BooleanVal(#True), "false")
TestParserFalse(BooleanVal(#False), "true")
TestParserFalse(Num(), "a123")
TestParserFalse(NumQ(), "a123456789123456")
TestParserFalse(NumF(), "a123.456")
TestParserFalse(NumD(), "a123.456789123456")
TestParserFalse(NumVal(123), "321")
TestParserFalse(NumQVal(123456789123456), "321,456,789,123,456")
TestParserFalse(NumFVal(123.456E-2), "321.456E-2")
TestParserFalse(NumDVal(123.456E10), "321.456E10")
TestParserFalse(NumHex(), "$1234ABCD")
TestParserFalse(NumQHex(), "$1234456789ABCDEF")
TestParserFalse(NumHexVal($1234ABCD), "4321ABCD")
TestParserFalse(NumQHexVal($123456789ABCDEF0), "432156789ABCDEF0")


;- TextToSpeech
TextToSpeech::Speak("This text should be hearable.")


PrintN("")
PrintN("Count: " + Str(Count))
PrintN("PASSED: " + Str(Passed))
PrintN("FAILED: " + Str(Count - Passed))
PrintN("")
PrintN("Press ENTER to exit.")
Input()
CloseConsole()

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 188
; FirstLine = 137
; Folding = --
; EnableUnicode
; EnableXP
; UseMainFile = UnitTests.pb
; HideErrorLog