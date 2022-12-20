extends "stmt_ast_node.gd"

# Block Statement AST Node
# A block statement AST node is a structure used by the NightScript compiler
# that represents a block statement node of an abstract syntax tree.

var stmts: Array = []

# Initialize the block statement.
func _init().("Block") -> void:
	pass


# Get the block statement's children as an array.
func get_children() -> Array:
	return stmts
