extends Reference

# Token
# A token is a structure used by the NightScript compiler that represents a
# lexeme in NightScript source code.

const Span: GDScript = preload("../logger/span.gd")

enum {
	EOF, # End of file.
	INVALID, # Syntax error, whitespace, or comment. (Skipped by parser.)
	LITERAL_INT, # Integer value.
	LITERAL_STR, # String value.
	IDENTIFIER, # Identifier.
	KEYWORD_AND, # `and`.
	KEYWORD_BREAK, # `break`.
	KEYWORD_CONST, # `const`.
	KEYWORD_CONTINUE, # `continue`.
	KEYWORD_ELSE, # `else`.
	KEYWORD_FUNC, # `func`.
	KEYWORD_IF, # `if`.
	KEYWORD_INCLUDE, # `include`.
	KEYWORD_MENU, # `menu`.
	KEYWORD_NOT, # `not`.
	KEYWORD_OPTION, # `option`.
	KEYWORD_OR, # `or`.
	KEYWORD_RETURN, # `return`.
	KEYWORD_VAR, # `var`.
	KEYWORD_WHILE, # `while`.
	BANG_EQUALS, # `!=`.
	PARENTHESIS_OPEN, # `(`.
	PARENTHESIS_CLOSE, # `)`.
	STAR, # `*`.
	PLUS, # `+`.
	COMMA, # `,`.
	MINUS, # `-`.
	SEMICOLON, # `;`.
	LESS, # `<`.
	LESS_EQUALS, # `<=`.
	EQUALS, # `=`.
	EQUALS_EQUALS, # `==`.
	GREATER, # `>`.
	GREATER_EQUALS, # `>=`.
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
	var result: String = get_name(type)
	
	match type:
		LITERAL_INT:
			result = "%s `%d`" % [result, int_value]
		LITERAL_STR, IDENTIFIER:
			result = "%s `%s`" % [result, str_value.c_escape()]
	
	return "%s (%s)" % [result, span]


# Get a token's name from its type.
static func get_name(token_type: int) -> String:
	match token_type:
		EOF:
			return "end of file"
		INVALID:
			return "invalid token"
		LITERAL_INT:
			return "integer"
		LITERAL_STR:
			return "string"
		IDENTIFIER:
			return "identifier"
		KEYWORD_AND:
			return "`and`"
		KEYWORD_BREAK:
			return "`break`"
		KEYWORD_CONST:
			return "`const`"
		KEYWORD_CONTINUE:
			return "`continue`"
		KEYWORD_ELSE:
			return "`else`"
		KEYWORD_FUNC:
			return "`func`"
		KEYWORD_IF:
			return "`if`"
		KEYWORD_INCLUDE:
			return "`include`"
		KEYWORD_MENU:
			return "`menu`"
		KEYWORD_NOT:
			return "`not`"
		KEYWORD_OPTION:
			return "`option`"
		KEYWORD_OR:
			return "`or`"
		KEYWORD_RETURN:
			return "`return`"
		KEYWORD_VAR:
			return "`var`"
		KEYWORD_WHILE:
			return "`while`"
		BANG_EQUALS:
			return "`!=`"
		PARENTHESIS_OPEN:
			return "`(`"
		PARENTHESIS_CLOSE:
			return "`)`"
		STAR:
			return "`*`"
		PLUS:
			return "`+`"
		COMMA:
			return "`,`"
		MINUS:
			return "`-`"
		SEMICOLON:
			return "`;`"
		LESS:
			return "`<`"
		LESS_EQUALS:
			return "`<=`"
		EQUALS:
			return "`=`"
		EQUALS_EQUALS:
			return "`==`"
		GREATER:
			return "`>`"
		GREATER_EQUALS:
			return "`>=`"
		BRACE_OPEN:
			return "`{`"
		BRACE_CLOSE:
			return "`}`"
	
	return "Bug: Unnamed token type `%d`!" % token_type
