extends "ast_node.gd"

# Statement AST Node
# A statement AST node is a structure used by the NightScript compiler that
# represents a statement node of an abstract syntax tree.

# Set the statement's name.
func _init(node_subname: String).("%sStmt" % node_subname) -> void:
	pass
