extends "stmt_ast_node.gd"

# Expression Statement AST Node
# An expression statement AST node is a structure used by the NightScript
# compiler that represents an expression statement node of an abstract syntax
# tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")

var expr: ExprASTNode

# Set the expression statement's expression.
func _init(expr_ref: ExprASTNode).("Expr") -> void:
	expr = expr_ref


# Get the expression statement's children as an array.
func get_children() -> Array:
	return [expr]
