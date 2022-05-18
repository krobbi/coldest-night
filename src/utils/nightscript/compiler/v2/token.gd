extends Reference

# Token
# A token is a structure used by the NightScript compiler that represents a
# syntactic element of NightScript source code.

enum {
	END_OF_FILE,
	ERROR,
	IDENTIFIER,
	FLAG,
	LITERAL_INT,
	LITERAL_STRING,
	KEYWORD_AND,
	KEYWORD_NOT,
	KEYWORD_OR,
	PLUS,
	MINUS,
	STAR,
	EQUALS_EQUALS,
	BANG_EQUALS,
	GREATER,
	GREATER_EQUALS,
	LESS,
	LESS_EQUALS,
	OPEN_PARENTHESIS,
	CLOSE_PARENTHESIS,
}

var type: int
var int_value: int = 0
var string_value: String = ""
var key_value: String = ""

# Constructor. Sets the token's type:
func _init(type_val: int) -> void:
	type = type_val
