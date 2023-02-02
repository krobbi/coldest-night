extends "stmt_ast_node.gd"

# Menu Statement AST Node
# A menu statement AST node is a structure used by the NightScript compiler that
# represents a menu statement node of an abstract syntax tree.

const StmtASTNode: GDScript = preload("stmt_ast_node.gd")

var stmt: StmtASTNode

# Set the menu statement's statement.
func _init(stmt_ref: StmtASTNode).("Menu") -> void:
	stmt = stmt_ref


# Get the menu statement's children as an array.
func get_children() -> Array:
	return [stmt]
