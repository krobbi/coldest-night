extends "expr_ast_node.gd"

# Binary Expression AST Node
# A binary expression AST node is a structure used by the NightScript compiler
# that represents a binary expression node of an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")
const Token: GDScript = preload("../lexer/token.gd")

var lhs_expr: ExprASTNode
var operator: int
var rhs_expr: ExprASTNode

# Set the binary expression's expressions and operator.
func _init(lhs_expr_ref: ExprASTNode, operator_val: int, rhs_expr_ref: ExprASTNode).("Bin") -> void:
	lhs_expr = lhs_expr_ref
	operator = operator_val
	rhs_expr = rhs_expr_ref


# Get the binary expression's children as an array.
func get_children() -> Array:
	return [lhs_expr, rhs_expr]


# Get information about the binary expression as a string.
func get_info() -> String:
	return Token.get_name(operator)
