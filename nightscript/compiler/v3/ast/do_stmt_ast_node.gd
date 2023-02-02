extends "stmt_ast_node.gd"

# Do Statement AST Node
# A do statement AST node is a structure used by the NightScript compiler that
# represents a do statement node of an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")
const StmtASTNode: GDScript = preload("stmt_ast_node.gd")

var stmt: StmtASTNode
var expr: ExprASTNode

# Set the do statement's statement and expression.
func _init(stmt_ref: StmtASTNode, expr_ref: ExprASTNode).("Do") -> void:
	stmt = stmt_ref
	expr = expr_ref


# Get the do statement's children as an array.
func get_children() -> Array:
	return [stmt, expr]
