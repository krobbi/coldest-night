extends Reference

# Token
# A token is a structure used by the NightScript compiler that represents a
# lexeme in NightScript source code.

const Span: GDScript = preload("../logger/span.gd")

enum {
	EOF, # End of file.
	ERROR, # Syntax error. (Skipped by parser.)
	WHITESPACE, # Whitespace or comment. (Skipped by parser.)
	LITERAL_INT, # Integer value.
	LITERAL_STR, # String value.
	IDENTIFIER, # Identifier.
	KEYWORD_BREAK, # `break`.
	KEYWORD_CONTINUE, # `continue`.
	KEYWORD_DO, # `do`.
	KEYWORD_ELSE, # `else`.
	KEYWORD_IF, # `if`.
	KEYWORD_INCLUDE, # `include`.
	KEYWORD_MENU, # `menu`.
	KEYWORD_OPTION, # `option`.
	KEYWORD_WHILE, # `while`.
	PARENTHESIS_OPEN, # `(`.
	PARENTHESIS_CLOSE, # `)`.
	COMMA, # `,`.
	SEMICOLON, # `;`.
	BRACE_OPEN, # `{`.
	BRACE_CLOSE, # `}`.
}

var type: int
var span: Span
var int_value: int = 0
var str_value: String = ""

# Set the token's type and span.
func _init(type_val: int, span_ref: Span) -> void:
	type = type_val
	span = span_ref


# Return the token's string representation.
func _to_string() -> String:
	var result: String = "Unknown"
	
	match type:
		EOF:
			result = "End of file"
		ERROR:
			result = "Syntax error: %s" % str_value
		WHITESPACE:
			result = "Whitespace or comment"
		LITERAL_INT:
			result = "%d" % int_value
		LITERAL_STR:
			result = '"%s"' % str_value.c_escape()
		IDENTIFIER:
			result = "Identifier: %s" % str_value
		KEYWORD_BREAK:
			result = "break"
		KEYWORD_CONTINUE:
			result = "continue"
		KEYWORD_DO:
			result = "do"
		KEYWORD_ELSE:
			result = "else"
		KEYWORD_IF:
			result = "if"
		KEYWORD_INCLUDE:
			result = "include"
		KEYWORD_MENU:
			result = "menu"
		KEYWORD_OPTION:
			result = "option"
		KEYWORD_WHILE:
			result = "while"
		PARENTHESIS_OPEN:
			result = "("
		PARENTHESIS_CLOSE:
			result = ")"
		COMMA:
			result = ","
		SEMICOLON:
			result = ";"
		BRACE_OPEN:
			result = "{"
		BRACE_CLOSE:
			result = "}"
	
	return "%s (%s)" % [result, span]
