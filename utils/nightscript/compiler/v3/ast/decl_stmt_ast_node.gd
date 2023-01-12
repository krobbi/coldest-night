extends "stmt_ast_node.gd"

# Declaration Statement AST Node
# A declaration statement AST node is a structure used by the NightScript
# compiler that represents a declaration statement node of an abstract syntax
# tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")
const IdentifierExprASTNode: GDScript = preload("identifier_expr_ast_node.gd")
const Token: GDScript = preload("../lexer/token.gd")

var operator: int
var identifier_expr: IdentifierExprASTNode
var value_expr: ExprASTNode

# Set the declaration statement's operator and expressions.
func _init(
		operator_val: int, identifier_expr_ref: IdentifierExprASTNode,
		value_expr_ref: ExprASTNode).("Decl") -> void:
	operator = operator_val
	identifier_expr = identifier_expr_ref
	value_expr = value_expr_ref


# Get the declaration statement's children as an array.
func get_children() -> Array:
	return [identifier_expr, value_expr]


# Get information about the declaration statement as a string.
func get_info() -> String:
	return Token.get_name(operator)
