extends "ast_node.gd"

# Expression AST Node
# An expression AST node is a structure used by the NightScript compiler that
# represents an expression node of an abstract syntax tree.

# Set the expression's name.
func _init(node_subname: String).("%sExpr" % node_subname) -> void:
	pass
