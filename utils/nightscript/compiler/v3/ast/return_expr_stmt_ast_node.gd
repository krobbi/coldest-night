extends "stmt_ast_node.gd"

# Return Expression Statement AST Node
# A return expression statement AST node is a structure used by the NightScript
# compiler that represents a return expression statement node of an abstract
# syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")

var expr: ExprASTNode

# Set the return expression statement's expression.
func _init(expr_ref: ExprASTNode).("ReturnExpr") -> void:
	expr = expr_ref


# Get the return expression statement's children as an array.
func get_children() -> Array:
	return [expr]
