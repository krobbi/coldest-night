extends "expr_ast_node.gd"

# Call Expression AST Node
# A call expression AST node is a structure used by the NightScript compiler
# that represents a call expression node of an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")

var expr: ExprASTNode
var exprs: Array = []

# Set the call expression's expression.
func _init(expr_ref: ExprASTNode).("Call") -> void:
	expr = expr_ref


# Get the call expression's children as an array.
func get_children() -> Array:
	var children: Array = [expr]
	children.append_array(exprs)
	return children
