extends Reference

# Compiler
# A compiler is a component of the NightScript compiler that compiles abstract
# syntax trees to IR code.

const ASTNode: GDScript = preload("../ast/ast_node.gd")
const BinExprASTNode: GDScript = preload("../ast/bin_expr_ast_node.gd")
const BlockStmtASTNode: GDScript = preload("../ast/block_stmt_ast_node.gd")
const BreakStmtASTNode: GDScript = preload("../ast/break_stmt_ast_node.gd")
const CallExprASTNode: GDScript = preload("../ast/call_expr_ast_node.gd")
const ContinueStmtASTNode: GDScript = preload("../ast/continue_stmt_ast_node.gd")
const DoStmtASTNode: GDScript = preload("../ast/do_stmt_ast_node.gd")
const ExprASTNode: GDScript = preload("../ast/expr_ast_node.gd")
const ExprStmtASTNode: GDScript = preload("../ast/expr_stmt_ast_node.gd")
const IdentifierExprASTNode: GDScript = preload("../ast/identifier_expr_ast_node.gd")
const IfStmtASTNode: GDScript = preload("../ast/if_stmt_ast_node.gd")
const IfElseStmtASTNode: GDScript = preload("../ast/if_else_stmt_ast_node.gd")
const IntExprASTNode: GDScript = preload("../ast/int_expr_ast_node.gd")
const IRCode: GDScript = preload("../../backend/ir_code.gd")
const Logger: GDScript = preload("../logger/logger.gd")
const MenuStmtASTNode: GDScript = preload("../ast/menu_stmt_ast_node.gd")
const ModuleASTNode: GDScript = preload("../ast/module_ast_node.gd")
const OptionStmtASTNode: GDScript = preload("../ast/option_stmt_ast_node.gd")
const RootASTNode: GDScript = preload("../ast/root_ast_node.gd")
const Scope: GDScript = preload("scope.gd")
const StrExprASTNode: GDScript = preload("../ast/str_expr_ast_node.gd")
const Symbol: GDScript = preload("symbol.gd")
const Token: GDScript = preload("../lexer/token.gd")
const UnExprASTNode: GDScript = preload("../ast/un_expr_ast_node.gd")
const WhileStmtASTNode: GDScript = preload("../ast/while_stmt_ast_node.gd")

const INFO_BREAK_LABEL: String = "break_label"
const INFO_CONTINUE_LABEL: String = "continue_label"
const INFO_MENU_END_LABEL: String = "menu_end_label"

var code: IRCode
var logger: Logger
var scopes: Array = [Scope.new()]

# Set the compiler's IR code and logger.
func _init(code_ref: IRCode, logger_ref: Logger) -> void:
	code = code_ref
	logger = logger_ref


# Get a symbol from its identifier.
func get_symbol(identifier: String) -> Symbol:
	for i in range(scopes.size() - 1, -1, -1):
		var scope: Scope = scopes[i]
		
		if scope.symbols.has(identifier):
			return scope.symbols[identifier]
	
	return Symbol.new(identifier, Symbol.UNDEFINED)


# Get scoped info from its key.
func get_info(key: String) -> String:
	for i in range(scopes.size() - 1, -1, -1):
		var scope: Scope = scopes[i]
		
		if scope.info.has(key):
			return scope.info[key]
	
	return ""


# Return whether scoped info is defined from its key.
func has_info(key: String) -> bool:
	for i in range(scopes.size() - 1, -1, -1):
		var scope: Scope = scopes[i]
		
		if scope.info.has(key):
			return not scope.info[key].empty()
	
	return false


# Push a new scope to the top of the scope stack.
func push_scope() -> void:
	scopes.push_back(Scope.new())


# Pop a scope from the top of the scope stack if it is not the global scope.
func pop_scope() -> void:
	var top_index: int = scopes.size() - 1
	
	if top_index > 0:
		scopes.remove(top_index)


# Define an intrinsic from its identifier, method, and argument count.
func define_intrinsic(identifier: String, method: String, argument_count: int) -> void:
	var symbol: Symbol = Symbol.new(identifier, Symbol.INTRINSIC)
	symbol.str_value = method
	symbol.int_value = argument_count
	scopes[-1].symbols[identifier] = symbol


# Define scoped info from its key and value.
func define_info(key: String, value: String) -> void:
	scopes[-1].info[key] = value


# Undefine scoped info from its key.
func undefine_info(key: String) -> void:
	scopes[-1].info[key] = ""


# Compile an abstract synax tree to IR code.
func compile_ast(root: RootASTNode) -> void:
	code.reset()
	scopes = [Scope.new()]
	visit_node(root)


# Visit an AST node.
func visit_node(node: ASTNode) -> void:
	if node is RootASTNode:
		visit_root(node)
	elif node is ModuleASTNode:
		visit_module(node)
	elif node is BlockStmtASTNode:
		visit_block_stmt(node)
	elif node is IfStmtASTNode:
		visit_if_stmt(node)
	elif node is IfElseStmtASTNode:
		visit_if_else_stmt(node)
	elif node is WhileStmtASTNode:
		visit_while_stmt(node)
	elif node is DoStmtASTNode:
		visit_do_stmt(node)
	elif node is MenuStmtASTNode:
		visit_menu_stmt(node)
	elif node is OptionStmtASTNode:
		visit_option_stmt(node)
	elif node is BreakStmtASTNode:
		visit_break_stmt(node)
	elif node is ContinueStmtASTNode:
		visit_continue_stmt(node)
	elif node is ExprStmtASTNode:
		visit_expr_stmt(node)
	elif node is UnExprASTNode:
		visit_un_expr(node)
	elif node is BinExprASTNode:
		visit_bin_expr(node)
	elif node is CallExprASTNode:
		visit_call_expr(node)
	elif node is IntExprASTNode:
		visit_int_expr(node)
	elif node is StrExprASTNode:
		visit_str_expr(node)
	else:
		logger.log_error("Bug: No visitor for node type `%s`!" % node.node_name, node.span)
		
		# Expressions must push a value to the stack.
		if node is ExprASTNode:
			code.make_push_int(0)


# Visit a root AST node.
func visit_root(root: RootASTNode) -> void:
	push_scope()
	define_intrinsic("awaitPaths", "make_await_actor_paths", 0)
	define_intrinsic("call", "make_call_program", 1)
	define_intrinsic("checkpoint", "make_save_checkpoint", 0)
	define_intrinsic("clearName", "make_clear_dialog_name", 0)
	define_intrinsic("doNotPause", "define_not_pausable", 0)
	define_intrinsic("exit", "make_halt", 0)
	define_intrinsic("face", "make_actor_face_direction", 2)
	define_intrinsic("freeze", "make_freeze_player", 0)
	define_intrinsic("hide", "make_hide_dialog", 0)
	define_intrinsic("isRepeat", "=make_push_is_repeat", 0)
	define_intrinsic("name", "make_display_dialog_name", 1)
	define_intrinsic("path", "make_actor_find_path", 2)
	define_intrinsic("pause", "make_pause_game", 0)
	define_intrinsic("quit", "make_quit_to_title", 0)
	define_intrinsic("run", "make_run_program", 1)
	define_intrinsic("runPaths", "make_run_actor_paths", 0)
	define_intrinsic("save", "make_save_game", 0)
	define_intrinsic("say", "make_display_dialog_message", 1)
	define_intrinsic("show", "make_show_dialog", 0)
	define_intrinsic("sleep", "make_sleep", 1)
	define_intrinsic("thaw", "make_thaw_player", 0)
	define_intrinsic("unpause", "make_unpause_game", 0)
	
	for module in root.modules:
		visit_node(module)
	
	code.make_halt()
	pop_scope()


# Visit a module AST node.
func visit_module(module: ModuleASTNode) -> void:
	for stmt in module.stmts:
		visit_node(stmt)


# Visit a block statement AST node.
func visit_block_stmt(block_stmt: BlockStmtASTNode) -> void:
	push_scope()
	
	for stmt in block_stmt.stmts:
		visit_node(stmt)
	
	pop_scope()


# Visit an if statement AST node.
func visit_if_stmt(if_stmt: IfStmtASTNode) -> void:
	var end_label: String = code.insert_unique_label("if_end")
	
	visit_node(if_stmt.expr)
	code.make_jump_zero_label(end_label)
	
	push_scope()
	visit_node(if_stmt.stmt)
	pop_scope()
	
	code.set_label(end_label)


# Visit an if-else statement AST node.
func visit_if_else_stmt(if_else_stmt: IfElseStmtASTNode) -> void:
	var end_label: String = code.insert_unique_label("if_else_end")
	var else_label: String = code.insert_unique_label("if_else_else")
	
	visit_node(if_else_stmt.expr)
	code.make_jump_zero_label(else_label)
	
	push_scope()
	visit_node(if_else_stmt.then_stmt)
	code.make_jump_label(end_label)
	pop_scope()
	
	push_scope()
	code.set_label(else_label)
	visit_node(if_else_stmt.else_stmt)
	pop_scope()
	
	code.set_label(end_label)


# Visit a while statement AST node.
func visit_while_stmt(while_stmt: WhileStmtASTNode) -> void:
	var end_label: String = code.insert_unique_label("while_end")
	var condition_label: String = code.insert_unique_label("while_condition")
	
	code.set_label(condition_label)
	visit_node(while_stmt.expr)
	code.make_jump_zero_label(end_label)
	
	push_scope()
	define_info(INFO_BREAK_LABEL, end_label)
	define_info(INFO_CONTINUE_LABEL, condition_label)
	visit_node(while_stmt.stmt)
	code.make_jump_label(condition_label)
	pop_scope()
	
	code.set_label(end_label)


# Visit a do statement AST node.
func visit_do_stmt(do_stmt: DoStmtASTNode) -> void:
	var end_label: String = code.insert_unique_label("do_end")
	var condition_label: String = code.insert_unique_label("do_condition")
	var body_label: String = code.insert_unique_label("do_body")
	
	push_scope()
	define_info(INFO_BREAK_LABEL, end_label)
	define_info(INFO_CONTINUE_LABEL, condition_label)
	code.set_label(body_label)
	visit_node(do_stmt.stmt)
	pop_scope()
	
	code.set_label(condition_label)
	visit_node(do_stmt.expr)
	code.make_jump_not_zero_label(body_label)
	
	code.set_label(end_label)


# Visit a menu statement AST node.
func visit_menu_stmt(menu_stmt: MenuStmtASTNode) -> void:
	if has_info(INFO_MENU_END_LABEL):
		logger.log_error("Used `menu` directly inside of a menu statement!", menu_stmt.span)
		return
	
	var end_label: String = code.insert_unique_label("menu_end")
	var show_label: String = code.insert_unique_label("menu_show")
	
	push_scope()
	define_info(INFO_BREAK_LABEL, show_label)
	define_info(INFO_MENU_END_LABEL, end_label)
	undefine_info(INFO_CONTINUE_LABEL)
	visit_node(menu_stmt.stmt)
	pop_scope()
	
	code.set_label(show_label)
	code.make_show_dialog_menu()
	
	code.set_label(end_label)


# Visit an option statement AST node.
func visit_option_stmt(option_stmt: OptionStmtASTNode) -> void:
	if not has_info(INFO_MENU_END_LABEL):
		logger.log_error("Used `option` outside of a menu statement!", option_stmt.span)
		return
	
	var end_label: String = code.insert_unique_label("option_end")
	var body_label: String = code.insert_unique_label("option_body")
	
	visit_node(option_stmt.expr)
	code.make_store_dialog_menu_option_label(body_label)
	code.make_jump_label(end_label)
	
	push_scope()
	define_info(INFO_BREAK_LABEL, get_info(INFO_MENU_END_LABEL))
	undefine_info(INFO_CONTINUE_LABEL)
	undefine_info(INFO_MENU_END_LABEL)
	code.set_label(body_label)
	visit_node(option_stmt.stmt)
	pop_scope()
	
	code.make_jump_label(get_info(INFO_MENU_END_LABEL))
	
	code.set_label(end_label)


# Visit a break statement AST node.
func visit_break_stmt(break_stmt: BreakStmtASTNode) -> void:
	if not has_info(INFO_BREAK_LABEL):
		logger.log_error("Used `break` outside of a breakable statement!", break_stmt.span)
		return
	
	code.make_jump_label(get_info(INFO_BREAK_LABEL))


# Visit a continue statement AST node.
func visit_continue_stmt(continue_stmt: ContinueStmtASTNode) -> void:
	if not has_info(INFO_CONTINUE_LABEL):
		logger.log_error("Used `continue` outside of a continuable statement!", continue_stmt.span)
		return
	
	code.make_jump_label(get_info(INFO_CONTINUE_LABEL))


# Visit an expression statement AST node.
func visit_expr_stmt(expr_stmt: ExprStmtASTNode) -> void:
	visit_node(expr_stmt.expr)
	code.make_drop()


# Visit a unary expression AST node.
func visit_un_expr(un_expr: UnExprASTNode) -> void:
	visit_node(un_expr.expr)
	
	match un_expr.operator:
		Token.PLUS:
			pass
		Token.MINUS:
			code.make_unary_negate()
		Token.BANG:
			code.make_unary_not()
		_:
			logger.log_error(
					"Bug: No unary operation for token %s!" % Token.get_name(un_expr.operator),
					un_expr.span)


# Visit a binary expression AST node.
func visit_bin_expr(bin_expr: BinExprASTNode) -> void:
	if bin_expr.operator == Token.AMPERSAND_AMPERSAND:
		var end_label: String = code.insert_unique_label("and_end")
		
		visit_node(bin_expr.lhs_expr)
		code.make_duplicate()
		code.make_jump_zero_label(end_label)
		code.make_drop()
		visit_node(bin_expr.rhs_expr)
		
		code.set_label(end_label)
	elif bin_expr.operator == Token.DOT:
		if(
				not bin_expr.lhs_expr is IdentifierExprASTNode
				or not bin_expr.rhs_expr is IdentifierExprASTNode):
			logger.log_error("Access expressions may only contain two identifiers!", bin_expr.span)
			visit_node(bin_expr.lhs_expr)
			visit_node(bin_expr.rhs_expr)
			code.make_drop()
			return
		
		code.make_load_flag_namespace_key(bin_expr.lhs_expr.name, bin_expr.rhs_expr.name)
	elif bin_expr.operator == Token.EQUALS:
		visit_node(bin_expr.rhs_expr)
		
		if(
				bin_expr.lhs_expr is BinExprASTNode
				and bin_expr.lhs_expr.operator == Token.DOT
				and bin_expr.lhs_expr.lhs_expr is IdentifierExprASTNode
				and bin_expr.lhs_expr.rhs_expr is IdentifierExprASTNode):
			code.make_store_flag_namespace_key(
					bin_expr.lhs_expr.lhs_expr.name, bin_expr.lhs_expr.rhs_expr.name)
		else:
			logger.log_error("Can only assign to a flag!", bin_expr.lhs_expr.span)
			visit_node(bin_expr.lhs_expr)
			code.make_drop()
	elif bin_expr.operator == Token.PIPE_PIPE:
		var end_label: String = code.insert_unique_label("or_end")
		
		visit_node(bin_expr.lhs_expr)
		code.make_duplicate()
		code.make_jump_not_zero_label(end_label)
		code.make_drop()
		visit_node(bin_expr.rhs_expr)
		
		code.set_label(end_label)
	else:
		visit_node(bin_expr.lhs_expr)
		visit_node(bin_expr.rhs_expr)
		
		if bin_expr.operator == Token.BANG_EQUALS:
			code.make_binary_not_equals()
		elif bin_expr.operator == Token.AMPERSAND:
			code.make_binary_and()
		elif bin_expr.operator == Token.STAR:
			code.make_binary_multiply()
		elif bin_expr.operator == Token.PLUS:
			code.make_binary_add()
		elif bin_expr.operator == Token.MINUS:
			code.make_binary_subtract()
		elif bin_expr.operator == Token.LESS:
			code.make_binary_less()
		elif bin_expr.operator == Token.LESS_EQUALS:
			code.make_binary_less_equals()
		elif bin_expr.operator == Token.EQUALS_EQUALS:
			code.make_binary_equals()
		elif bin_expr.operator == Token.GREATER:
			code.make_binary_greater()
		elif bin_expr.operator == Token.GREATER_EQUALS:
			code.make_binary_greater_equals()
		elif bin_expr.operator == Token.PIPE:
			code.make_binary_or()
		else:
			logger.log_error(
					"Bug: No binary operation for token %s!" % Token.get_name(bin_expr.operator),
					bin_expr.span)
			
			# Binary expressions must only push a single value to the stack.
			code.make_drop()


# Visit a call expression AST node.
func visit_call_expr(call_expr: CallExprASTNode) -> void:
	for expr in call_expr.exprs:
		visit_node(expr)
	
	var argument_count: int = call_expr.exprs.size()
	var expected_argument_count: int = -1
	var is_intrinsic_void: bool = true
	var intrinsic_func_name: String = ""
	
	if call_expr.expr is IdentifierExprASTNode:
		var symbol: Symbol = get_symbol(call_expr.expr.name)
		
		if symbol.access == Symbol.UNDEFINED:
			logger.log_error(
					"Identifier `%s` is undefined in the current scope!" % symbol.identifier,
					call_expr.expr.span)
		elif symbol.access == Symbol.INTRINSIC:
			intrinsic_func_name = symbol.str_value
			expected_argument_count = symbol.int_value
			
			if intrinsic_func_name.begins_with("="):
				is_intrinsic_void = false
				intrinsic_func_name = intrinsic_func_name.substr(1)
		else:
			logger.log_error(
					"Identifier `%s` is not callable!" % symbol.identifier, call_expr.expr.span)
	else:
		logger.log_error("Only identifiers may be called!", call_expr.expr.span)
	
	if argument_count != expected_argument_count:
		if expected_argument_count == 1:
			logger.log_error("Expected 1 argument, got %d!" % argument_count, call_expr.span)
		elif expected_argument_count >= 0:
			logger.log_error(
					"Expected %d arguments, got %d!"
					% [expected_argument_count, argument_count], call_expr.span)
		
		if argument_count > 0:
			for _i in range(argument_count):
				code.make_drop()
		
		visit_node(call_expr.expr)
		return
	
	code.call(intrinsic_func_name)
	
	if is_intrinsic_void:
		code.make_push_int(0)


# Visit an integer expression AST node.
func visit_int_expr(int_expr: IntExprASTNode) -> void:
	code.make_push_int(int_expr.value)


# Visit a string expression AST node.
func visit_str_expr(str_expr: StrExprASTNode) -> void:
	code.make_push_string(str_expr.value)
