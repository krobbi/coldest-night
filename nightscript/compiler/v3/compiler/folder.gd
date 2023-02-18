extends Reference

# Folder
# A folder is a component of the NightScript compiler that folds expression AST
# nodes to simpler forms.

const BinExprASTNode: GDScript = preload("../ast/bin_expr_ast_node.gd")
const CallExprASTNode: GDScript = preload("../ast/call_expr_ast_node.gd")
const ExprASTNode: GDScript = preload("../ast/expr_ast_node.gd")
const IdentifierExprASTNode: GDScript = preload("../ast/identifier_expr_ast_node.gd")
const IntExprASTNode: GDScript = preload("../ast/int_expr_ast_node.gd")
const ScopeStack: GDScript = preload("scope_stack.gd")
const StrExprASTNode: GDScript = preload("../ast/str_expr_ast_node.gd")
const Symbol: GDScript = preload("symbol.gd")
const Token: GDScript = preload("../lexer/token.gd")
const UnExprASTNode: GDScript = preload("../ast/un_expr_ast_node.gd")

var scope_stack: ScopeStack
var span_stack: Array = []

# Set the folder's scope stack.
func _init(scope_stack_ref: ScopeStack) -> void:
	scope_stack = scope_stack_ref


# Push a new span to the span stack at an expression AST node's span.
func push_span(expr: ExprASTNode) -> void:
	span_stack.push_back(expr.span.duplicate())


# Pop and apply the top span from the span stack to an expression AST node.
func pop_span(expr: ExprASTNode) -> ExprASTNode:
	expr.span.copy(span_stack.pop_back())
	return expr


# Fold an expression AST node.
func fold_expr(expr: ExprASTNode) -> ExprASTNode:
	if expr is UnExprASTNode:
		return fold_un_expr(expr)
	elif expr is BinExprASTNode:
		return fold_bin_expr(expr)
	elif expr is CallExprASTNode:
		return fold_call_expr(expr)
	elif expr is IdentifierExprASTNode:
		return fold_identifier_expr(expr)
	
	return expr


# Fold a unary expression AST node.
func fold_un_expr(un_expr: UnExprASTNode) -> ExprASTNode:
	push_span(un_expr)
	var child_expr: ExprASTNode = fold_expr(un_expr.expr)
	
	if not child_expr is IntExprASTNode:
		return pop_span(UnExprASTNode.new(un_expr.operator, child_expr))
	
	if un_expr.operator == Token.KEYWORD_NOT:
		return pop_span(IntExprASTNode.new(int(child_expr.value == 0)))
	elif un_expr.operator == Token.PLUS:
		return pop_span(child_expr)
	elif un_expr.operator == Token.MINUS:
		return pop_span(IntExprASTNode.new(-child_expr.value))
	
	return pop_span(UnExprASTNode.new(un_expr.operator, child_expr))


# Fold a binary expression AST node.
func fold_bin_expr(bin_expr: BinExprASTNode) -> ExprASTNode:
	push_span(bin_expr)
	var rhs_expr: ExprASTNode = fold_expr(bin_expr.rhs_expr)
	
	# Never fold the left hand side of assignments.
	if bin_expr.operator == Token.EQUALS:
		return pop_span(BinExprASTNode.new(bin_expr.lhs_expr, bin_expr.operator, rhs_expr))
	
	var lhs_expr: ExprASTNode = fold_expr(bin_expr.lhs_expr)
	
	if lhs_expr is IntExprASTNode:
		if bin_expr.operator == Token.KEYWORD_AND:
			return pop_span(rhs_expr if lhs_expr.value != 0 else lhs_expr)
		elif bin_expr.operator == Token.KEYWORD_OR:
			return pop_span(lhs_expr if lhs_expr.value != 0 else rhs_expr)
		elif bin_expr.operator == Token.STAR and lhs_expr.value == 1:
			return pop_span(rhs_expr)
		elif bin_expr.operator == Token.PLUS and lhs_expr.value == 0:
			return pop_span(rhs_expr)
		elif bin_expr.operator == Token.MINUS and lhs_expr.value == 0:
			return pop_span(fold_expr(UnExprASTNode.new(Token.MINUS, rhs_expr)))
	elif rhs_expr is IntExprASTNode:
		if bin_expr.operator == Token.KEYWORD_OR and rhs_expr.value == 0:
			return pop_span(lhs_expr)
		elif bin_expr.operator == Token.STAR and rhs_expr.value == 1:
			return pop_span(lhs_expr)
		elif bin_expr.operator == Token.PLUS and rhs_expr.value == 0:
			return pop_span(lhs_expr)
		elif bin_expr.operator == Token.MINUS and rhs_expr.value == 0:
			return pop_span(lhs_expr)
	
	if not lhs_expr is IntExprASTNode or not rhs_expr is IntExprASTNode:
		return pop_span(BinExprASTNode.new(lhs_expr, bin_expr.operator, rhs_expr))
	
	if bin_expr.operator == Token.BANG_EQUALS:
		return pop_span(IntExprASTNode.new(int(lhs_expr.value != rhs_expr.value)))
	elif bin_expr.operator == Token.STAR:
		return pop_span(IntExprASTNode.new(lhs_expr.value * rhs_expr.value))
	elif bin_expr.operator == Token.PLUS:
		return pop_span(IntExprASTNode.new(lhs_expr.value + rhs_expr.value))
	elif bin_expr.operator == Token.MINUS:
		return pop_span(IntExprASTNode.new(lhs_expr.value - rhs_expr.value))
	elif bin_expr.operator == Token.LESS:
		return pop_span(IntExprASTNode.new(int(lhs_expr.value < rhs_expr.value)))
	elif bin_expr.operator == Token.LESS_EQUALS:
		return pop_span(IntExprASTNode.new(int(lhs_expr.value <= rhs_expr.value)))
	elif bin_expr.operator == Token.EQUALS_EQUALS:
		return pop_span(IntExprASTNode.new(int(lhs_expr.value == rhs_expr.value)))
	elif bin_expr.operator == Token.GREATER:
		return pop_span(IntExprASTNode.new(int(lhs_expr.value > rhs_expr.value)))
	elif bin_expr.operator == Token.GREATER_EQUALS:
		return pop_span(IntExprASTNode.new(int(lhs_expr.value >= rhs_expr.value)))
	
	return pop_span(BinExprASTNode.new(lhs_expr, bin_expr.operator, rhs_expr))


# Fold a call expression AST node.
func fold_call_expr(call_expr: CallExprASTNode) -> ExprASTNode:
	push_span(call_expr)
	var folded: CallExprASTNode = pop_span(CallExprASTNode.new(call_expr.callee_expr))
	
	for argument_expr in call_expr.argument_exprs:
		folded.argument_exprs.push_back(fold_expr(argument_expr))
	
	return folded


# Fold an identifier expression AST node.
func fold_identifier_expr(identifier_expr: IdentifierExprASTNode) -> ExprASTNode:
	push_span(identifier_expr)
	var symbol: Symbol = scope_stack.get_symbol(identifier_expr.name)
	
	if symbol.access == Symbol.LITERAL_INT:
		return pop_span(IntExprASTNode.new(symbol.int_value))
	elif symbol.access == Symbol.LITERAL_STR:
		return pop_span(StrExprASTNode.new(symbol.str_value))
	
	return pop_span(identifier_expr)
