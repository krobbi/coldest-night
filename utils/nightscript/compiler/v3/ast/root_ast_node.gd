extends "ast_node.gd"

# Root AST Node
# A root AST node is a structure used by the NightScript compiler that
# represents a root node of an abstract syntax tree.

var modules: Array = []

# Initialize the root.
func _init().("Root") -> void:
	pass


# Get the root's children as an array.
func get_children() -> Array:
	return modules
