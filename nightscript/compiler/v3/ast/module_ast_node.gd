extends "ast_node.gd"

# Module AST Node
# A module AST node is a structure used by the NightScript compiler that
# represents a module node of an abstract syntax tree.

var includes: Array = []
var stmts: Array = []

# Initialize the module.
func _init().("Module") -> void:
	pass


# Get the module's children as an array.
func get_children() -> Array:
	var children: Array = includes.duplicate()
	children.append_array(stmts)
	return children


# Get information about the module as a string.
func get_info() -> String:
	return span.name
