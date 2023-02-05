extends Reference

# AST Node
# An AST node is a structure used by the NightScript compiler that represents a
# node of an abstract syntax tree.

enum {
	ERROR, # Syntax error.
	IDENTIFIER, # User-defined name.
	FLAG, # User-defined flag namespace and key: `x.y`
	INT, # Integer value.
	STRING, # String value.
	NOP_STMT, # No operation statement: `;`
	COMPOUND_STMT, # Compound statement: `{}`
	IF_STMT, # If statement: `if x {y;} else {z;}`
	LOOP_STMT, # Loop statement: `while x {y;}` or `do {y;} while x;`
	MENU_STMT, # Menu statement: `& {x;}`
	OPTION_STMT, # Option statement: `| "x" {y;}`
	SCOPED_JUMP_STMT, # Scoped jump statement: `break;` or `continue;`
	META_DECL_STMT, # Meta declaration statement: `meta x = y;`
	DECL_STMT, # Declaration statement: `define x = y;` or `const x = y;`
	OP_STMT, # Operation statement.
	TEXT_OP_STMT, # Text operation statement.
	EXPR_OP_STMT, # Expression operation statement.
	ACTOR_FACE_DIRECTION_STMT, # Actor face direction statement: `"x" > y;`
	PATH_STMT, # Path finding statement.
	DISPLAY_DIALOG_NAME_STMT, # Display dialog name statement: `"x":`
	IS_REPEAT_EXPR, # Is repeat expression: `IS_REPEAT`
	UN_EXPR, # Unary expression: `f(x)`
	BIN_EXPR, # Binary expression: `f(x, y)`
	BOOL_EXPR, # Short-circuit boolean expression: `x && y` or `x || y`
	ASSIGN_EXPR, # Assignment expression: `x = y`
}

# Detach operations from native NightScript opcodes.
enum {
	OP_HALT,
	OP_RUN_PROGRAM,
	OP_CALL_PROGRAM,
	OP_SLEEP,
	OP_DROP,
	OP_SHOW_DIALOG,
	OP_HIDE_DIALOG,
	OP_DISPLAY_DIALOG_MESSAGE,
	OP_RUN_ACTOR_PATHS,
	OP_AWAIT_ACTOR_PATHS,
	OP_FREEZE_PLAYER,
	OP_UNFREEZE_PLAYER,
	OP_PAUSE_GAME,
	OP_UNPAUSE_GAME,
	OP_SAVE_GAME,
	OP_SAVE_CHECKPOINT,
}

enum {
	LOOP_WHILE, # While loop: `while x {y;}`
	LOOP_DO_WHILE, # Do while loop: `do {y;} while x;`
}

enum {
	DECL_DEFINE, # Definition declaraion: `define x = y;`
	DECL_CONST, # Constant declaration: `const x = y;`
}

enum {
	PATH_FIND, # Find path: `"x" ~ "y";`
	PATH_RUN, # Run path: `"x" ~> "y";`
	PATH_RUN_AWAIT, # Run path and await: `"x" -> "y";`
}

enum {
	UN_NEG, # Unary negation operator: `-x`
	UN_NOT, # Unary logical not operator: `!x`
}

enum {
	BIN_ADD, # Binary addition operator: `x + y`
	BIN_SUB, # Binary subtraction operator: `x - y`
	BIN_MUL, # Binary multiplication operator: `x * y`
	BIN_EQ, # Binary equality operator: `x == y`
	BIN_NE, # Binary inequality operator: `x != y`
	BIN_GT, # Binary greater than operator: `x > y`
	BIN_GE, # Binary greater than or equal to operator: `x >= y`
	BIN_LT, # Binary less than operator: `x < y`
	BIN_LE, # Binary less than or equal to operator: `x <= y`
	BIN_AND, # Binary logical and operator: `x and y`
	BIN_OR, # Binary logical or operator: `x or y`
}

enum {
	BOOL_AND, # Short-circuit boolean and operator: `x && y`
	BOOL_OR, # Short-circuit boolean or operator: `x || y`
}

var type: int
var int_value: int = 0
var string_value: String = ""
var children: Array = []

# Constructor. Sets the AST node's type:
func _init(type_val: int) -> void:
	type = type_val
