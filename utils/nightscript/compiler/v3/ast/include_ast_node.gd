extends "ast_node.gd"

# Include AST Node
# An include AST node is a structure used by the NightScript compiler that
# represents an include node of an abstract syntax tree.

const StrExprASTNode: GDScript = preload("str_expr_ast_node.gd")

var expr: StrExprASTNode

# Set the include's expression.
func _init(expr_ref: StrExprASTNode).("Include") -> void:
	expr = expr_ref


# Get the include's children as an array.
func get_children() -> Array:
	return [expr]
