extends "expr_ast_node.gd"

# Unary Expression AST Node
# A unary expression AST node is a structure used by the NightScript compiler
# that represents a unary expression node of an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")

var operator: int
var expr: ExprASTNode

# Set the unary expression's operator and expression.
func _init(operator_val: int, expr_ref: ExprASTNode).("Un") -> void:
	operator = operator_val
	expr = expr_ref


# Get the unary expression's children as an array.
func get_children() -> Array:
	return [expr]


# Get information about the unary expression as a string.
func get_info() -> String:
	return "%d" % operator
