extends "stmt_ast_node.gd"

# Variable Statement AST Node
# A variable statement AST node is a structure used by the NightScript compiler
# that represents a variable statement node of an abstract syntax tree.

const IdentifierExprASTNode: GDScript = preload("identifier_expr_ast_node.gd")

var expr: IdentifierExprASTNode

# Set the variable statement's expression.
func _init(expr_ref: IdentifierExprASTNode).("Var") -> void:
	expr = expr_ref


# Get the variable statement's children as an array.
func get_children() -> Array:
	return [expr]
