extends "stmt_ast_node.gd"

# Option Statement AST Node
# An option statement AST node is a structure used by the NightScript compiler
# that represents an option statement node of an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")
const StmtASTNode: GDScript = preload("stmt_ast_node.gd")

var expr: ExprASTNode
var stmt: StmtASTNode

# Set the option statement's expression and statement.
func _init(expr_ref: ExprASTNode, stmt_ref: StmtASTNode).("Option") -> void:
	expr = expr_ref
	stmt = stmt_ref


# Get the option statement's children as an array.
func get_children() -> Array:
	return [expr, stmt]
