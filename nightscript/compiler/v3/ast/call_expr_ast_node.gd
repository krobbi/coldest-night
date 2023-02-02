extends "expr_ast_node.gd"

# Call Expression AST Node
# A call expression AST node is a structure used by the NightScript compiler
# that represents a call expression node of an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")

var callee_expr: ExprASTNode
var argument_exprs: Array = []

# Set the call expression's callee expression.
func _init(callee_expr_ref: ExprASTNode).("Call") -> void:
	callee_expr = callee_expr_ref


# Get the call expression's children as an array.
func get_children() -> Array:
	var children: Array = [callee_expr]
	children.append_array(argument_exprs)
	return children
