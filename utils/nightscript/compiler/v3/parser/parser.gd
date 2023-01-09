extends Reference

# Parser
# A parser is a structure used by the NightScript compiler that parses module
# abstract syntax trees from NightScript source code.

const ASTNode: GDScript = preload("../ast/ast_node.gd")
const BinExprASTNode: GDScript = preload("../ast/bin_expr_ast_node.gd")
const BlockStmtASTNode: GDScript = preload("../ast/block_stmt_ast_node.gd")
const BreakStmtASTNode: GDScript = preload("../ast/break_stmt_ast_node.gd")
const CallExprASTNode: GDScript = preload("../ast/call_expr_ast_node.gd")
const ContinueStmtASTNode: GDScript = preload("../ast/continue_stmt_ast_node.gd")
const DoStmtASTNode: GDScript = preload("../ast/do_stmt_ast_node.gd")
const ErrorASTNode: GDScript = preload("../ast/error_ast_node.gd")
const ExprASTNode: GDScript = preload("../ast/expr_ast_node.gd")
const ExprStmtASTNode: GDScript = preload("../ast/expr_stmt_ast_node.gd")
const IdentifierExprASTNode: GDScript = preload("../ast/identifier_expr_ast_node.gd")
const IfStmtASTNode: GDScript = preload("../ast/if_stmt_ast_node.gd")
const IfElseStmtASTNode: GDScript = preload("../ast/if_else_stmt_ast_node.gd")
const IncludeASTNode: GDScript = preload("../ast/include_ast_node.gd")
const IntExprASTNode: GDScript = preload("../ast/int_expr_ast_node.gd")
const Lexer: GDScript = preload("../lexer/lexer.gd")
const Logger: GDScript = preload("../logger/logger.gd")
const MenuStmtASTNode: GDScript = preload("../ast/menu_stmt_ast_node.gd")
const ModuleASTNode: GDScript = preload("../ast/module_ast_node.gd")
const OptionStmtASTNode: GDScript = preload("../ast/option_stmt_ast_node.gd")
const Span: GDScript = preload("../logger/span.gd")
const StmtASTNode: GDScript = preload("../ast/stmt_ast_node.gd")
const StrExprASTNode: GDScript = preload("../ast/str_expr_ast_node.gd")
const Token: GDScript = preload("../lexer/token.gd")
const UnExprASTNode: GDScript = preload("../ast/un_expr_ast_node.gd")
const WhileStmtASTNode: GDScript = preload("../ast/while_stmt_ast_node.gd")

var logger: Logger
var lexer: Lexer = Lexer.new()
var current: Token = Token.new(Token.EOF, Span.new())
var next: Token = Token.new(Token.EOF, Span.new())
var span_stack: Array = []
var advance_stack: Array = []

# Set the parser's logger.
func _init(logger_ref: Logger) -> void:
	logger = logger_ref


# Abort the current span and create a new error AST node at the end of the
# current valid token's span from its message.
func create_error(message: String) -> ErrorASTNode:
	span_stack.pop_back()
	var error: ErrorASTNode = ErrorASTNode.new(message)
	error.span.copy(current.span)
	error.span.shrink_to_end()
	return error


# Advance to the next valid token.
func advance() -> void:
	current = next
	next = lexer.get_next_token()
	
	while next.type == Token.ERROR or next.type == Token.WHITESPACE:
		if next.type == Token.ERROR:
			logger.log_error(next.str_value, next.span)
		
		next = lexer.get_next_token()


# Advance to the next valid token and return true if its type matches a type.
# Otherwise, do nothing and return false.
func accept(type: int) -> bool:
	if next.type != type:
		return false
	
	advance()
	return true


# Mark the current token as a token that must be advanced from.
func begin_advance() -> void:
	advance_stack.push_back(current)


# Advance if we haven't advanced from a token that must be advanced.
func end_advance() -> void:
	if advance_stack.pop_back() == current:
		advance()


# Begin a new span at the next valid token.
func begin_span() -> void:
	span_stack.push_back(next.span.duplicate())


# Apply the current span to an AST node without ending it.
func apply_span(node: ASTNode) -> void:
	node.span.copy(span_stack[-1])
	node.span.expand_to_span(current.span)


# End the current span and return an AST node with its existing span.
func abort_span(node: ASTNode) -> ASTNode:
	span_stack.pop_back()
	return node


# End the current span and return an AST node with the span applied.
func end_span(node: ASTNode) -> ASTNode:
	apply_span(node)
	span_stack.pop_back()
	return node


# Parse a module abstract syntax tree from a module name and NightScript source
# code.
func parse_module(name: String, source: String) -> ModuleASTNode:
	lexer.begin(name, source)
	next = Token.new(Token.EOF, Span.new())
	advance()
	span_stack = []
	advance_stack = []
	begin_span()
	var module: ModuleASTNode = ModuleASTNode.new()
	
	while next.type == Token.KEYWORD_INCLUDE:
		begin_advance()
		var include: ASTNode = parse_include()
		
		if include is IncludeASTNode:
			module.includes.push_back(include)
		elif include is ErrorASTNode:
			logger.log_error(include.message, include.span)
		else:
			logger.log_error("Bug: Propagated `%s` to module includes!" % include, include.span)
		
		end_advance()
	
	while next.type != Token.EOF:
		begin_advance()
		var stmt: ASTNode = parse_stmt()
		
		if stmt is StmtASTNode:
			module.stmts.push_back(stmt)
		elif stmt is ErrorASTNode:
			logger.log_error(stmt.message, stmt.span)
		else:
			logger.log_error("Bug: Propagated `%s` to module statements!" % stmt, stmt.span)
		
		end_advance()
	
	return end_span(module) as ModuleASTNode


# Parse an include.
func parse_include() -> ASTNode:
	begin_span()
	
	if not accept(Token.KEYWORD_INCLUDE):
		return create_error("Expected `include`!")
	
	var expr: ASTNode = parse_expr_primary_str()
	
	if not expr is StrExprASTNode:
		return abort_span(expr)
	
	if not accept(Token.SEMICOLON):
		return create_error("Expected `;`!")
	
	return end_span(IncludeASTNode.new(expr))


# Parse a statement.
func parse_stmt() -> ASTNode:
	begin_span()
	
	if next.type == Token.BRACE_OPEN:
		return abort_span(parse_stmt_block())
	elif next.type == Token.KEYWORD_IF:
		return abort_span(parse_stmt_if())
	elif next.type == Token.KEYWORD_WHILE:
		return abort_span(parse_stmt_while())
	elif next.type == Token.KEYWORD_DO:
		return abort_span(parse_stmt_do())
	elif next.type == Token.KEYWORD_MENU:
		return abort_span(parse_stmt_menu())
	elif next.type == Token.KEYWORD_OPTION:
		return abort_span(parse_stmt_option())
	elif next.type == Token.KEYWORD_BREAK:
		return abort_span(parse_stmt_break())
	elif next.type == Token.KEYWORD_CONTINUE:
		return abort_span(parse_stmt_continue())
	
	var expr_stmt: ASTNode = parse_stmt_expr()
	
	if not expr_stmt is ExprStmtASTNode:
		return abort_span(expr_stmt)
	
	return end_span(expr_stmt)


# Parse a block statement.
func parse_stmt_block() -> ASTNode:
	begin_span()
	
	if not accept(Token.BRACE_OPEN):
		return create_error("Expected `{`!")
	
	var block_stmt: BlockStmtASTNode = BlockStmtASTNode.new()
	
	while not accept(Token.BRACE_CLOSE):
		if next.type == Token.EOF:
			return create_error("Unterminated block statement!")
		
		begin_advance()
		var stmt: ASTNode = parse_stmt()
		
		if stmt is StmtASTNode:
			block_stmt.stmts.append(stmt)
		elif stmt is ErrorASTNode:
			logger.log_error(stmt.message, stmt.span)
		else:
			logger.log_error("Bug: Propagated `%s` to block statement!" % stmt, stmt.span)
		
		end_advance()
	
	return end_span(block_stmt)


# Parse an if statement.
func parse_stmt_if() -> ASTNode:
	begin_span()
	
	if not accept(Token.KEYWORD_IF):
		return create_error("Expected `if`!")
	
	var expr: ASTNode = parse_expr_paren()
	
	if not expr is ExprASTNode:
		return abort_span(expr)
	
	var then_stmt: ASTNode = parse_stmt()
	
	if not then_stmt is StmtASTNode:
		return abort_span(then_stmt)
	
	if not accept(Token.KEYWORD_ELSE):
		return end_span(IfStmtASTNode.new(expr, then_stmt))
	
	var else_stmt: ASTNode = parse_stmt()
	
	if not else_stmt is StmtASTNode:
		return abort_span(else_stmt)
	
	return end_span(IfElseStmtASTNode.new(expr, then_stmt, else_stmt))


# Parse a while statement.
func parse_stmt_while() -> ASTNode:
	begin_span()
	
	if not accept(Token.KEYWORD_WHILE):
		return create_error("Expected `while`!")
	
	var expr: ASTNode = parse_expr_paren()
	
	if not expr is ExprASTNode:
		return abort_span(expr)
	
	var stmt: ASTNode = parse_stmt()
	
	if not stmt is StmtASTNode:
		return abort_span(stmt)
	
	return end_span(WhileStmtASTNode.new(expr, stmt))


# Parse a do statement.
func parse_stmt_do() -> ASTNode:
	begin_span()
	
	if not accept(Token.KEYWORD_DO):
		return create_error("Expected `do`!")
	
	var stmt: ASTNode = parse_stmt()
	
	if not stmt is StmtASTNode:
		return abort_span(stmt)
	
	if not accept(Token.KEYWORD_WHILE):
		return create_error("Expected `while`!")
	
	var expr: ASTNode = parse_expr_paren()
	
	if not expr is ExprASTNode:
		return abort_span(expr)
	
	if not accept(Token.SEMICOLON):
		return create_error("Expected `;`!")
	
	return end_span(DoStmtASTNode.new(stmt, expr))


# Parse a menu statement.
func parse_stmt_menu() -> ASTNode:
	begin_span()
	
	if not accept(Token.KEYWORD_MENU):
		return create_error("Expected `menu`!")
	
	var stmt: ASTNode = parse_stmt()
	
	if not stmt is StmtASTNode:
		return abort_span(stmt)
	
	return end_span(MenuStmtASTNode.new(stmt))


# Parse an option statement.
func parse_stmt_option() -> ASTNode:
	begin_span()
	
	if not accept(Token.KEYWORD_OPTION):
		return create_error("Expected `option`!")
	
	var expr: ASTNode = parse_expr_paren()
	
	if not expr is ExprASTNode:
		return abort_span(expr)
	
	var stmt: ASTNode = parse_stmt()
	
	if not stmt is StmtASTNode:
		return abort_span(stmt)
	
	return end_span(OptionStmtASTNode.new(expr, stmt))


# Parse a break statement.
func parse_stmt_break() -> ASTNode:
	begin_span()
	
	if not accept(Token.KEYWORD_BREAK):
		return create_error("Expected `break`!")
	
	if not accept(Token.SEMICOLON):
		return create_error("Expected `;`!")
	
	return end_span(BreakStmtASTNode.new())


# Parse a continue statement.
func parse_stmt_continue() -> ASTNode:
	begin_span()
	
	if not accept(Token.KEYWORD_CONTINUE):
		return create_error("Expected `continue`!")
	
	if not accept(Token.SEMICOLON):
		return create_error("Expected `;`!")
	
	return end_span(ContinueStmtASTNode.new())


# Parse an expression statement.
func parse_stmt_expr() -> ASTNode:
	begin_span()
	
	var expr: ASTNode = parse_expr()
	
	if not expr is ExprASTNode:
		return abort_span(expr)
	
	if not accept(Token.SEMICOLON):
		return create_error("Expected `;`!")
	
	return end_span(ExprStmtASTNode.new(expr))


# Parse a parenthesized expression.
func parse_expr_paren() -> ASTNode:
	begin_span()
	
	if not accept(Token.PARENTHESIS_OPEN):
		return create_error("Expected `(`!")
	
	var expr: ASTNode = parse_expr()
	
	if not expr is ExprASTNode:
		return abort_span(expr)
	
	if not accept(Token.PARENTHESIS_CLOSE):
		return create_error("Expected `)`!")
	
	return abort_span(expr)


# Parse an expression.
func parse_expr() -> ASTNode:
	return parse_expr_eager_or()


# Parse a generic binary expression.
func parse_expr_bin(child_parser: String, operators: Array) -> ASTNode:
	begin_span()
	
	if not has_method(child_parser):
		return create_error("Bug: Parser method `%s` does not exist!" % child_parser)
	
	var expr = call(child_parser)
	
	if not expr is ASTNode:
		return create_error("Bug: Parser method `%s` does not return an AST node!" % child_parser)
	
	if not expr is ExprASTNode:
		return abort_span(expr)
	
	while next.type in operators:
		advance()
		var operator: int = current.type
		var rhs_expr: ASTNode = call(child_parser)
		
		if not rhs_expr is ExprASTNode:
			return abort_span(rhs_expr)
		
		expr = BinExprASTNode.new(expr, operator, rhs_expr)
		apply_span(expr)
	
	return abort_span(expr)


# Parse an eager or expression.
func parse_expr_eager_or() -> ASTNode:
	return parse_expr_bin("parse_expr_eager_and", [Token.PIPE])


# Parse an eager and expression.
func parse_expr_eager_and() -> ASTNode:
	return parse_expr_bin("parse_expr_not", [Token.AMPERSAND])


# Parse a not expression.
func parse_expr_not() -> ASTNode:
	begin_span()
	
	if accept(Token.BANG):
		var expr: ASTNode = parse_expr_not()
		
		if not expr is ExprASTNode:
			return abort_span(expr)
		
		return end_span(UnExprASTNode.new(Token.BANG, expr))
	
	return abort_span(parse_expr_equality())


# Parse an equality expression.
func parse_expr_equality() -> ASTNode:
	return parse_expr_bin("parse_expr_comparison", [Token.BANG_EQUALS, Token.EQUALS_EQUALS])


# Parse a comparison expression.
func parse_expr_comparison() -> ASTNode:
	return parse_expr_bin("parse_expr_sum", [
			Token.LESS, Token.LESS_EQUALS, Token.GREATER, Token.GREATER_EQUALS])


# Parse a sum expression.
func parse_expr_sum() -> ASTNode:
	return parse_expr_bin("parse_expr_term", [Token.PLUS, Token.MINUS])


# Parse a term expression.
func parse_expr_term() -> ASTNode:
	return parse_expr_bin("parse_expr_sign", [Token.STAR])


# Parse a sign expression.
func parse_expr_sign() -> ASTNode:
	begin_span()
	
	if next.type == Token.PLUS or next.type == Token.MINUS:
		advance()
		var operator: int = current.type
		var expr: ASTNode = parse_expr_sign()
		
		if not expr is ExprASTNode:
			return abort_span(expr)
		
		return end_span(UnExprASTNode.new(operator, expr))
	
	return abort_span(parse_expr_call())


# Parse a call expression.
func parse_expr_call() -> ASTNode:
	begin_span()
	var expr: ASTNode = parse_expr_primary()
	
	if not expr is ExprASTNode:
		return abort_span(expr)
	
	while accept(Token.PARENTHESIS_OPEN):
		expr = CallExprASTNode.new(expr)
		
		if accept(Token.PARENTHESIS_CLOSE):
			apply_span(expr)
			continue
		
		var argument: ASTNode = parse_expr()
		
		if not argument is ExprASTNode:
			return abort_span(argument)
		
		expr.exprs.push_back(argument)
		
		while accept(Token.COMMA):
			argument = parse_expr()
			
			if not argument is ExprASTNode:
				return abort_span(argument)
			
			expr.exprs.push_back(argument)
		
		if not accept(Token.PARENTHESIS_CLOSE):
			return create_error("Expected `)`!")
		
		apply_span(expr)
	
	return abort_span(expr)


# Parse a primary expression.
func parse_expr_primary() -> ASTNode:
	begin_span()
	
	if next.type == Token.PARENTHESIS_OPEN:
		return abort_span(parse_expr_paren())
	elif next.type == Token.LITERAL_INT:
		return end_span(parse_expr_primary_int())
	elif next.type == Token.LITERAL_STR:
		return end_span(parse_expr_primary_str())
	elif next.type == Token.IDENTIFIER:
		return end_span(parse_expr_primary_identifier())
	
	return create_error("Expected an expression!")


# Parse a primary integer expression.
func parse_expr_primary_int() -> ASTNode:
	begin_span()
	
	if not accept(Token.LITERAL_INT):
		return create_error("Expected an integer!")
	
	return end_span(IntExprASTNode.new(current.int_value))


# Parse a primary string expression.
func parse_expr_primary_str() -> ASTNode:
	begin_span()
	
	if not accept(Token.LITERAL_STR):
		return create_error("Expected a string!")
	
	return end_span(StrExprASTNode.new(current.str_value))


# Parse a primary identifier expression.
func parse_expr_primary_identifier() -> ASTNode:
	begin_span()
	
	if not accept(Token.IDENTIFIER):
		return create_error("Expected an identifier!")
	
	return end_span(IdentifierExprASTNode.new(current.str_value))
