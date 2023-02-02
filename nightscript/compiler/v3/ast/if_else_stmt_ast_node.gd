extends "stmt_ast_node.gd"

# If-Else Statement AST Node
# An if else statement AST node is a structure used by the NightScript compiler
# that represents an if-else statement node of an abstract syntax tree.

const ExprASTNode: GDScript = preload("expr_ast_node.gd")
const StmtASTNode: GDScript = preload("stmt_ast_node.gd")

var expr: ExprASTNode
var then_stmt: StmtASTNode
var else_stmt: StmtASTNode

# Set the if-else statement's expression and statements.
func _init(expr_ref: ExprASTNode, then_stmt_ref: StmtASTNode, else_stmt_ref: StmtASTNode).(
		"IfElse") -> void:
	expr = expr_ref
	then_stmt = then_stmt_ref
	else_stmt = else_stmt_ref


# Get the-if else statement's children as an array.
func get_children() -> Array:
	return [expr, then_stmt, else_stmt]
