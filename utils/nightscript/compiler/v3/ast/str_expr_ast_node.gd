extends "expr_ast_node.gd"

# String Expression AST Node
# A string expression AST node is a structure used by the NightScript compiler
# that represents a string expression node of an abstract syntax tree.

var value: String

# Set the string expression's value.
func _init(value_val: String).("Str") -> void:
	value = value_val


# Get information about the string expression as a string.
func get_info() -> String:
	return '"%s"' % value.c_escape()
