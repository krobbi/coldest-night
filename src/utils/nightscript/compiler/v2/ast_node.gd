extends Reference

# Abstract Syntax Tree Node
# An abstract syntax tree node is a structure used by the NightScript compiler
# that represents a statement or expression of a NightScript program with
# unambiguous precedence. Each AST node may have values and child AST nodes.

enum {
	NOP,
	BLOCK,
	IDENTIFIER,
	FLAG,
	INT,
	STRING,
	NEGATE,
	ADD,
	SUBTRACT,
	MULTIPLY,
	EQUALS,
	NOT_EQUALS,
	GREATER_THAN,
	GREATER_EQUALS,
	LESS_THAN,
	LESS_EQUALS,
	NOT,
	AND,
	OR,
}

var type: int
var int_value: int = 0
var string_value: String = ""
var key_value: String = ""
var children: Array = []

# Constructor. Sets the abstract syntax tree node's type:
func _init(type_val: int) -> void:
	type = type_val
