extends "stmt_ast_node.gd"

# Function Statement AST Node
# A function statement AST node is a structure used by the NightScript compiler
# that represents a function statement node of an abstract syntax tree.

const IdentifierExprASTNode: GDScript = preload("identifier_expr_ast_node.gd")
const StmtASTNode: GDScript = preload("stmt_ast_node.gd")

var identifier_expr: IdentifierExprASTNode
var argument_exprs: Array
var stmt: StmtASTNode

# Set the function statement's expressions and statement.
func _init(
		identifier_expr_ref: IdentifierExprASTNode, argument_exprs_ref: Array,
		stmt_ref: StmtASTNode).("Func") -> void:
	identifier_expr = identifier_expr_ref
	argument_exprs = argument_exprs_ref
	stmt = stmt_ref


# Get the function statement's children as an array.
func get_children() -> Array:
	var children: Array = [identifier_expr]
	children.append_array(argument_exprs)
	children.push_back(stmt)
	return children
