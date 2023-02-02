extends "expr_ast_node.gd"

# Integer Expression AST Node
# An integer expression AST node is a structure used by the NightScript compiler
# that represents an integer expression node of an abstract syntax tree.

var value: int

# Set the integer expression's value.
func _init(value_val: int).("Int") -> void:
	value = value_val


# Get information about the integer expression as a string.
func get_info() -> String:
	return "%d" % value
