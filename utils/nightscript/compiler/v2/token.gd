extends Reference

# Token
# A token is a structure used by the NightScript compiler that represents a
# syntactic element of NightScript source code.

enum {
	END_OF_FILE, # End of source code.
	ERROR, # Syntax error.
	IDENTIFIER, # User-defined name.
	LITERAL_INT, # User-defined integer value.
	LITERAL_STRING, # User-defined string value.
	KEYWORD_AND, # `and`
	KEYWORD_BREAK, # `break`
	KEYWORD_CALL, # `call`
	KEYWORD_CHECKPOINT, # `checkpoint`
	KEYWORD_CONST, # `const`
	KEYWORD_CONTINUE, # `continue`
	KEYWORD_DEFINE, # `define`
	KEYWORD_DO, # `do`
	KEYWORD_ELSE, # `else`
	KEYWORD_EXIT, # `exit`
	KEYWORD_FALSE, # `false`
	KEYWORD_IF, # `if`
	KEYWORD_IS_REPEAT, # `IS_REPEAT`
	KEYWORD_META, # `meta`
	KEYWORD_NOT, # `not`
	KEYWORD_OR, # `or`
	KEYWORD_PAUSE, # `pause`
	KEYWORD_QUIT, # `quit`
	KEYWORD_RUN, # `run`
	KEYWORD_SAVE, # `save`
	KEYWORD_TRUE, # `true`
	KEYWORD_UNPAUSE, # `unpause`
	KEYWORD_WHILE, # `while`
	BANG, # `!`
	BANG_EQUAL, # `!=`
	BANG_GREATER, # `!>`
	AMPERSAND, # `&`
	AMPERSAND_AMPERSAND, # `&&`
	PARENTHESIS_OPEN, # `(`
	PARENTHESIS_CLOSE, # `)`
	STAR, # `*`
	STAR_GREATER, # `*>`
	PLUS, # `+`
	MINUS, # `-`
	MINUS_GREATER, # `->`
	DOT, # `.`
	COLON, # `:`
	SEMICOLON, # `;`
	LESS, # `<`
	LESS_BANG, # '<!'
	LESS_STAR, # `<*`
	LESS_EQUAL, # `<=`
	EQUAL, # `=`
	EQUAL_EQUAL, # `==`
	GREATER, # `>`
	GREATER_EQUAL, # `>=`
	BRACE_OPEN, # `{`
	PIPE, # `|`
	PIPE_PIPE, # `||`
	BRACE_CLOSE, # `}`
	TILDE, # `~`
	TILDE_GREATER, # `~>`
}

var type: int
var int_value: int = 0
var string_value: String = ""

# Constructor. Sets the token's type:
func _init(type_val: int) -> void:
	type = type_val
