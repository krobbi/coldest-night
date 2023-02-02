extends "stmt_ast_node.gd"

# If Statement AST Node
# An if statement AST node is a structure used by the NightScript compiler that
# represents an if statement node of an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")
const StmtASTNode: GDScript = preload("stmt_ast_node.gd")

var expr: ExprASTNode
var stmt: StmtASTNode

# Set the if statement's expression and statement.
func _init(expr_ref: ExprASTNode, stmt_ref: StmtASTNode).("If") -> void:
	expr = expr_ref
	stmt = stmt_ref


# Get the if statement's children as an array.
func get_children() -> Array:
	return [expr, stmt]
