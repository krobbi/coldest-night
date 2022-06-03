extends Reference

# AST Node
# An AST node is a structure used by the NightScript compiler that represents a
# node of an abstract syntax tree.

enum {
	PROGRAM,
	BLOCK,
	COMMAND,
	IDENTIFIER,
	FLAG,
	INT,
	STRING,
	UNARY_OPERATION,
	BINARY_OPERATION,
}

enum {
	CMD_EXIT,
	CMD_CALL,
	CMD_RUN,
	CMD_DIALOG_SHOW,
	CMD_DIALOG_HIDE,
	CMD_SAY,
	CMD_PLAYER_FREEZE,
	CMD_PLAYER_UNFREEZE,
}

enum {
	UN_NEG,
	UN_NOT,
}

enum {
	BIN_ADD,
	BIN_SUB,
	BIN_MUL,
	BIN_EQ,
	BIN_NE,
	BIN_GT,
	BIN_GE,
	BIN_LT,
	BIN_LE,
	BIN_AND,
	BIN_OR,
}

var type: int
var int_value: int = 0
var string_value: String = ""
var key_value: String = ""
var children: Array = []

# Constructor. Sets the AST node's type:
func _init(type_val: int) -> void:
	type = type_val
