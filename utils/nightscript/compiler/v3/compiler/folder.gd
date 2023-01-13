extends Reference

# Folder
# A folder is a component of the NightScript compiler that folds expression AST
# nodes to simpler forms.

const ExprASTNode: GDScript = preload("../ast/expr_ast_node.gd")
const IdentifierExprASTNode: GDScript = preload("../ast/identifier_expr_ast_node.gd")
const IntExprASTNode: GDScript = preload("../ast/int_expr_ast_node.gd")
const ScopeStack: GDScript = preload("scope_stack.gd")
const StrExprASTNode: GDScript = preload("../ast/str_expr_ast_node.gd")
const Symbol: GDScript = preload("symbol.gd")
const Token: GDScript = preload("../lexer/token.gd")
const UnExprASTNode: GDScript = preload("../ast/un_expr_ast_node.gd")

var scope_stack: ScopeStack

# Set the folder's scope stack.
func _init(scope_stack_ref: ScopeStack) -> void:
	scope_stack = scope_stack_ref


# Copy an expression AST node's span to another expression AST node and return
# the target expression AST node.
func copy_span(from: ExprASTNode, to: ExprASTNode) -> ExprASTNode:
	to.span.copy(from.span)
	return to


# Fold an expression AST node.
func fold_expr(expr: ExprASTNode) -> ExprASTNode:
	if expr is UnExprASTNode:
		return fold_un_expr(expr)
	elif expr is IdentifierExprASTNode:
		return fold_identifier_expr(expr)
	
	return expr


# Fold a unary expression AST node.
func fold_un_expr(un_expr: UnExprASTNode) -> ExprASTNode:
	var child_expr: ExprASTNode = fold_expr(un_expr.expr)
	
	if not child_expr is IntExprASTNode:
		return copy_span(un_expr, UnExprASTNode.new(un_expr.operator, child_expr))
	
	if un_expr.operator == Token.BANG:
		return copy_span(un_expr, IntExprASTNode.new(int(child_expr.value == 0)))
	elif un_expr.operator == Token.PLUS:
		return copy_span(un_expr, child_expr)
	elif un_expr.operator == Token.MINUS:
		return copy_span(un_expr, IntExprASTNode.new(-child_expr.value))
	
	return copy_span(un_expr, UnExprASTNode.new(un_expr.operator, child_expr))


# Fold an identifier expression AST node.
func fold_identifier_expr(identifier_expr: IdentifierExprASTNode) -> ExprASTNode:
	var symbol: Symbol = scope_stack.get_symbol(identifier_expr.name)
	
	if symbol.access == Symbol.LITERAL_INT:
		return copy_span(identifier_expr, IntExprASTNode.new(symbol.int_value))
	elif symbol.access == Symbol.LITERAL_STR:
		return copy_span(identifier_expr, StrExprASTNode.new(symbol.str_value))
	
	return identifier_expr
