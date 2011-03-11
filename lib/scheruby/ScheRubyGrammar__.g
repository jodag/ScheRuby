lexer grammar ScheRubyGrammar;
options {
  language=Ruby;

}

// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 80
SINGLE_QUOTE	: '\''	;	
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 81
LPAREN	:	'('	;
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 82
RPAREN	:	')'	;
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 83
WS	:	(' ' | '\t' | '\r' | '\n' )+ {$channel = 99 # HIDDEN } 	;
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 84
COMMENT	:	';' ~('\r'|'\n')* {$channel = 99 # HIDDEN } 	;


//R5RS:  <identifier> --> <initial> <subsequent>*
//R5RS:       | <peculiar identifier>
//R5RS:  <initial> --> <letter> | <special initial>
//R5RS:  <letter> --> a | b | c | ... | z
//R5RS:  
//R5RS:  <special initial> --> ! | $ | % | & | * | / | : | < | =
//R5RS:       | > | ? | ^ | _ | ~
//R5RS:  <subsequent> --> <initial> | <digit>
//R5RS:       | <special subsequent>
//R5RS:  <digit> --> 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
//R5RS:  <special subsequent> --> + | - | . | @
//R5RS:  <peculiar identifier> --> + | - | ...
/* This doesn't match up to R5RS exactly, but seems to work fine in practice.
Also note we allow symbols to begin with . which is a convention to indicate they refer to a Ruby method.*/
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 101
SYMBOL	:	('.'|'::'|'@')?('a'..'z'|'A'..'Z'|'-'|'%'|'^'|'&'|'*'|'_'|'+'|'='|'/'|'<'|'>'|'?'|'!'|'['|']'|'$'|'~')('0'..'9'|'a'..'z'|'A'..'Z'|'-'|'%'|'^'|'&'|'*'|'_'|'+'|'='|'/'|'<'|'>'|'?'|'!'|'['|']'|'::'|'@')*
	;

//R5RS:  <boolean> --> #t | #f
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 105
TRUE		: 	'#t'	;
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 106
FALSE	:	'#f'	;
/* Not part of standard Scheme, #nil reperesent's Ruby's nil value */
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 108
NIL		:	'#nil'	;


//R5RS:  <character> --> #\ <any character>
//R5RS:       | #\ <character name>
//R5RS:  <character name> --> space | newline
//R5RS:  
//R5RS:  <string> --> " <string element>* "
//R5RS:  <string element> --> <any character other than " or \>
//R5RS:       | \" | \\ 
//R5RS:  
//R5RS:  
/* Characters are currently unimplemented.
String literals are handled slightly differently than R5RS.  Again, we use YAML for the parsing. */
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 122
STRING	:	'"' ( ~('\\'|'"')|('\\'.)  )* '"'	;


//R5RS:  <number> --> <num 2>| <num 8>
//R5RS:       | <num 10>| <num 16>
//R5RS:  
//R5RS:  
//R5RS:  
//R5RS:  The following rules for <num R>, <complex R>, <real R>, <ureal R>, <uinteger R>, and <prefix R> should be replicated for R = 2, 8, 10, and 16. There are no rules for <decimal 2>, <decimal 8>, and <decimal 16>, which means that numbers containing decimal points or exponents must be in decimal radix. 
//R5RS:  
//R5RS:  <num R> --> <prefix R> <complex R>
//R5RS:  <complex R> --> <real R> | <real R> @ <real R>
//R5RS:      | <real R> + <ureal R> i | <real R> - <ureal R> i
//R5RS:      | <real R> + i | <real R> - i
//R5RS:      | + <ureal R> i | - <ureal R> i | + i | - i
//R5RS:  <real R> --> <sign> <ureal R>
//R5RS:  <ureal R> --> <uinteger R>
//R5RS:      | <uinteger R> / <uinteger R>
//R5RS:      | <decimal R>
//R5RS:  <decimal 10> --> <uinteger 10> <suffix>
//R5RS:      | . <digit 10>+ #* <suffix>
//R5RS:      | <digit 10>+ . <digit 10>* #* <suffix>
//R5RS:      | <digit 10>+ #+ . #* <suffix>
//R5RS:  <uinteger R> --> <digit R>+ #*
//R5RS:  <prefix R> --> <radix R> <exactness>
//R5RS:      | <exactness> <radix R>
//R5RS:  
//R5RS:  
//R5RS:  
//R5RS:  <suffix> --> <empty> 
//R5RS:      | <exponent marker> <sign> <digit 10>+
//R5RS:  <exponent marker> --> e | s | f | d | l
//R5RS:  <sign> --> <empty>  | + |  -
//R5RS:  <exactness> --> <empty> | #i | #e
//R5RS:  <radix 2> --> #b
//R5RS:  <radix 8> --> #o
//R5RS:  <radix 10> --> <empty> | #d
//R5RS:  <radix 16> --> #x
//R5RS:  <digit 2> --> 0 | 1
//R5RS:  <digit 8> --> 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
//R5RS:  <digit 10> --> <digit>
//R5RS:  <digit 16> --> <digit 10> | a | b | c | d | e | f 
//R5RS:  
/* For literal numbers, we follow a  simplified format than R5RS, and just let YAML do the parsing */
// $ANTLR src "C:\Documents and Settings\Jonathan Grier\workspace\scheruby\lib\scheruby\ScheRubyGrammar.g" 166
NUMBER 	:	'-'?(('0x'('0'..'9'|'a'..'f'|'A'..'F')+)|('0'..'9')('0'..'9'|'.')*)
	;
