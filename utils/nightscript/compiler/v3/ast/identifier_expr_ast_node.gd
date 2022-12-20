extends "expr_ast_node.gd"

# Identifier Expression AST Node
# An identifier expression AST node is a structure used by the NightScript
# compiler that represents an identifier expression node of an abstract syntax
# tree.

var name: String

# Set the identifier expression's name.
func _init(name_val: String).("Identifier") -> void:
	name = name_val


# Get information about the identifier expression as a string.
func get_info() -> String:
	return name
