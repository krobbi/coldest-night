extends "stmt_ast_node.gd"

# Variable Expression Statement AST Node
# A variable expression statement AST node is a structure used by the
# NightScript compiler that represents a variable expression statement node of
# an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")
const IdentifierExprASTNode: GDScript = preload("identifier_expr_ast_node.gd")

var identifier_expr: IdentifierExprASTNode
var value_expr: ExprASTNode

# Set the variable expression statement's expressions.
func _init(identifier_expr_ref: IdentifierExprASTNode, value_expr_ref: ExprASTNode).(
		"VarExpr") -> void:
	identifier_expr = identifier_expr_ref
	value_expr = value_expr_ref


# Get the variable expression statement's children as an array.
func get_children() -> Array:
	return [identifier_expr, value_expr]
