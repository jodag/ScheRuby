/* Grammar for Scheme, used by ScheRuby
 *
 * R5RS has been used as the reference for this, 
 * and has been interspersed into the Grammar as comments 
 * proceeded by //R5RS: 
 *
 */
 
grammar ScheRubyGrammar;

/*
 * NOTE:
 *
 * After generating the Ruby classes, you need to manually:
 *
 * 1. Add the line require 'yaml' to the Parser
 * 2. Change the require 'ScheRubyGrammarLexer' to include the proper path
 *
 */

options {
  language = Ruby;
}


/* R5RS specifies that read() reads only one datum.  
   However, for simplicity, our parser reads all datums and returns them as a list */
datums returns[val]
	:	{ $val = Cons::EMPTY_LIST }
		(datum { $val = Cons.adjoin!($val, $datum.val) })+
	;

//R5RS:  7.1.2 External representations
//R5RS:  
//R5RS:  <Datum> is what the read procedure (section see section 6.6.2 Input) successfully parses. Note that any string that parses as an <expression> will also parse as a <datum>. 
//R5RS:  
//R5RS:  <datum> --> <simple datum> | <compound datum>
//R5RS:  <simple datum> --> <boolean> | <number>
//R5RS:       | <character> | <string> |  <symbol>
//R5RS:  <symbol> --> <identifier>
//R5RS:  <compound datum> --> <list> | <vector>
//R5RS:  <list> --> (<datum>*) | (<datum>+ . <datum>)
//R5RS:         | <abbreviation>
//R5RS:  <abbreviation> --> <abbrev prefix> <datum>
//R5RS:  <abbrev prefix> --> ' | ` | , | ,@
//R5RS:  <vector> --> #(<datum>*) 
/* Abbreviations (other than ' ) and vectors are currently unimplemented */
datum returns[val]
	:	atom { $val = $atom.val }
	|	list { $val = $list.val }
	;

atom returns[val]
	:	NUMBER { $val = YAML::load($NUMBER.text) }
	|	SYMBOL { $val = $SYMBOL.text.to_sym }
	|	TRUE { $val = true }
	|	FALSE { $val = false }
	|	NIL { $val = nil } 
	|	STRING { $val = YAML::load($STRING.text) }
	;

list returns[val]
	:	{ $val = Cons::EMPTY_LIST }
		LPAREN (datum { $val = Cons.adjoin!($val, $datum.val) })* RPAREN
	|	
		SINGLE_QUOTE datum { $val = Cons.list(:quote, $datum.val) }
	;


//R5RS:  <token> --> <identifier> | <boolean> | <number>
//R5RS:       | <character> | <string>
//R5RS:       | ( | ) | #( | ' | ` | , | ,@ | .
//R5RS:  <delimiter> --> <whitespace> | ( | ) | " | ;
//R5RS:  <whitespace> --> <space or newline>
//R5RS:  <comment> --> ;  <all subsequent characters up to a
//R5RS:                   line break>
//R5RS:  <atmosphere> --> <whitespace> | <comment>
//R5RS:  <intertoken space> --> <atmosphere>*
//R5RS:  
SINGLE_QUOTE	: '\''	;	
LPAREN	:	'('	;
RPAREN	:	')'	;
WS	:	(' ' | '\t' | '\r' | '\n' )+ {$channel = 99 # HIDDEN } 	;
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
SYMBOL	:	('.'|'::'|'@')?('a'..'z'|'A'..'Z'|'-'|'%'|'^'|'&'|'*'|'_'|'+'|'='|'/'|'<'|'>'|'?'|'!'|'['|']'|'$'|'~')('0'..'9'|'a'..'z'|'A'..'Z'|'-'|'%'|'^'|'&'|'*'|'_'|'+'|'='|'/'|'<'|'>'|'?'|'!'|'['|']'|'::'|'@')*
	;

//R5RS:  <boolean> --> #t | #f
TRUE		: 	'#t'	;
FALSE	:	'#f'	;
/* Not part of standard Scheme, #nil reperesent's Ruby's nil value */
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
NUMBER 	:	'-'?(('0x'('0'..'9'|'a'..'f'|'A'..'F')+)|('0'..'9')('0'..'9'|'.')*)
	;
