extends Reference

# Compiler
# A compiler is a component of the NightScript compiler that compiles abstract
# syntax trees to IR code.

const ASTNode: GDScript = preload("../ast/ast_node.gd")
const BinExprASTNode: GDScript = preload("../ast/bin_expr_ast_node.gd")
const BlockStmtASTNode: GDScript = preload("../ast/block_stmt_ast_node.gd")
const BreakStmtASTNode: GDScript = preload("../ast/break_stmt_ast_node.gd")
const CallExprASTNode: GDScript = preload("../ast/call_expr_ast_node.gd")
const ConstStmtASTNode: GDScript = preload("../ast/const_stmt_ast_node.gd")
const ContinueStmtASTNode: GDScript = preload("../ast/continue_stmt_ast_node.gd")
const ExprASTNode: GDScript = preload("../ast/expr_ast_node.gd")
const ExprStmtASTNode: GDScript = preload("../ast/expr_stmt_ast_node.gd")
const Folder: GDScript = preload("folder.gd")
const FuncStmtASTNode: GDScript = preload("../ast/func_stmt_ast_node.gd")
const IdentifierExprASTNode: GDScript = preload("../ast/identifier_expr_ast_node.gd")
const IfStmtASTNode: GDScript = preload("../ast/if_stmt_ast_node.gd")
const IfElseStmtASTNode: GDScript = preload("../ast/if_else_stmt_ast_node.gd")
const IntExprASTNode: GDScript = preload("../ast/int_expr_ast_node.gd")
const IRCode: GDScript = preload("../../backend/ir_code.gd")
const Logger: GDScript = preload("../logger/logger.gd")
const MenuStmtASTNode: GDScript = preload("../ast/menu_stmt_ast_node.gd")
const ModuleASTNode: GDScript = preload("../ast/module_ast_node.gd")
const OptionStmtASTNode: GDScript = preload("../ast/option_stmt_ast_node.gd")
const ReturnExprStmtASTNode: GDScript = preload("../ast/return_expr_stmt_ast_node.gd")
const ReturnStmtASTNode: GDScript = preload("../ast/return_stmt_ast_node.gd")
const RootASTNode: GDScript = preload("../ast/root_ast_node.gd")
const ScopeStack: GDScript = preload("scope_stack.gd")
const StrExprASTNode: GDScript = preload("../ast/str_expr_ast_node.gd")
const Symbol: GDScript = preload("symbol.gd")
const Token: GDScript = preload("../lexer/token.gd")
const UnExprASTNode: GDScript = preload("../ast/un_expr_ast_node.gd")
const VarExprStmtASTNode: GDScript = preload("../ast/var_expr_stmt_ast_node.gd")
const VarStmtASTNode: GDScript = preload("../ast/var_stmt_ast_node.gd")
const WhileStmtASTNode: GDScript = preload("../ast/while_stmt_ast_node.gd")

var code: IRCode
var logger: Logger
var scope_stack: ScopeStack
var folder: Folder

# Set the compiler's IR code, logger, scope stack, and folder.
func _init(code_ref: IRCode, logger_ref: Logger) -> void:
	code = code_ref
	logger = logger_ref
	scope_stack = ScopeStack.new(code)
	folder = Folder.new(scope_stack)


# Compile an abstract synax tree to IR code.
func compile_ast(root: RootASTNode) -> void:
	code.reset()
	
	var main_label: String = code.get_label()
	var entry_label: String = code.append_unique_label("entry")
	
	code.set_label(entry_label)
	scope_stack.reset()
	visit_node(root)
	
	if not logger.has_records():
		return
	
	code.set_label(main_label)
	code.make_freeze_player()
	
	if not code.is_pausable:
		code.make_pause_game()
	
	code.make_show_dialog()
	code.make_push_string("Error")
	code.make_display_dialog_name()
	
	for record in logger.get_records():
		code.make_push_string("%s:\n%s" % [record.span, record.message])
		code.make_display_dialog_message()
	
	code.make_clear_dialog_name()
	code.make_hide_dialog()
	
	if not code.is_pausable:
		code.make_unpause_game()
	
	code.make_unfreeze_player()
	code.make_push_int(1)
	code.make_sleep()


# Visit an AST node.
func visit_node(node: ASTNode) -> void:
	if node is RootASTNode:
		visit_root(node)
	elif node is ModuleASTNode:
		visit_module(node)
	elif node is FuncStmtASTNode:
		visit_func_stmt(node)
	elif node is BlockStmtASTNode:
		visit_block_stmt(node)
	elif node is IfStmtASTNode:
		visit_if_stmt(node)
	elif node is IfElseStmtASTNode:
		visit_if_else_stmt(node)
	elif node is WhileStmtASTNode:
		visit_while_stmt(node)
	elif node is MenuStmtASTNode:
		visit_menu_stmt(node)
	elif node is OptionStmtASTNode:
		visit_option_stmt(node)
	elif node is BreakStmtASTNode:
		visit_break_stmt(node)
	elif node is ContinueStmtASTNode:
		visit_continue_stmt(node)
	elif node is ConstStmtASTNode:
		visit_const_stmt(node)
	elif node is VarStmtASTNode:
		visit_var_stmt(node)
	elif node is VarExprStmtASTNode:
		visit_var_expr_stmt(node)
	elif node is ReturnStmtASTNode:
		visit_return_stmt(node)
	elif node is ReturnExprStmtASTNode:
		visit_return_expr_stmt(node)
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
	elif node is IdentifierExprASTNode:
		visit_identifier_expr(node)
	else:
		logger.log_error("Bug: No visitor for node type `%s`!" % node.node_name, node.span)
		
		# Expressions must push a value to the stack.
		if node is ExprASTNode:
			code.make_push_int(0)


# Visit a root AST node.
func visit_root(root: RootASTNode) -> void:
	scope_stack.push()
	scope_stack.define_intrinsic("await_paths", "make_await_actor_paths", 0)
	scope_stack.define_intrinsic("call", "make_call_program", 1)
	scope_stack.define_intrinsic("checkpoint", "make_save_checkpoint", 0)
	scope_stack.define_intrinsic("do_not_pause", "define_not_pausable", 0)
	scope_stack.define_intrinsic("exit", "make_halt", 0)
	scope_stack.define_intrinsic("face", "make_actor_face_direction", 2)
	scope_stack.define_intrinsic("format", "*visit_format_intrinsic_call_expr", -1)
	scope_stack.define_intrinsic("freeze", "make_freeze_player", 0)
	scope_stack.define_intrinsic("get_flag", "=make_load_flag", 1)
	scope_stack.define_intrinsic("hide", "make_hide_dialog", 0)
	scope_stack.define_intrinsic("is_repeat", "=make_push_is_repeat", 0)
	scope_stack.define_intrinsic("name", "*visit_name_intrinsic_call_expr", -1)
	scope_stack.define_intrinsic("path", "make_actor_find_path", 2)
	scope_stack.define_intrinsic("pause", "make_pause_game", 0)
	scope_stack.define_intrinsic("run", "make_run_program", 1)
	scope_stack.define_intrinsic("run_paths", "make_run_actor_paths", 0)
	scope_stack.define_intrinsic("save", "make_save_game", 0)
	scope_stack.define_intrinsic("say", "make_display_dialog_message", 1)
	scope_stack.define_intrinsic("set_flag", "*visit_set_flag_intrinsic_call_expr", 2)
	scope_stack.define_intrinsic("show", "make_show_dialog", 0)
	scope_stack.define_intrinsic("sleep", "make_sleep", 1)
	scope_stack.define_intrinsic("unfreeze", "make_unfreeze_player", 0)
	scope_stack.define_intrinsic("unpause", "make_unpause_game", 0)
	
	for module in root.modules:
		visit_node(module)
	
	scope_stack.pop()
	code.make_halt()


# Visit a module AST node.
func visit_module(module: ModuleASTNode) -> void:
	for stmt in module.stmts:
		visit_node(stmt)


# Visit a function statement AST node.
func visit_func_stmt(func_stmt: FuncStmtASTNode) -> void:
	var symbol: Symbol = scope_stack.get_symbol(func_stmt.identifier_expr.name)
	var parent_label = code.get_label()
	var body_label = code.append_unique_label("func_%s" % symbol.identifier)
	var argument_names: Array = []
	
	for argument_expr in func_stmt.argument_exprs:
		if argument_expr.name in argument_names:
			logger.log_error(
					"Argument `%s` is already defined for `%s`!"
					% [argument_expr.name, symbol.identifier], argument_expr.span)
		else:
			argument_names.push_back(argument_expr.name)
	
	if symbol.access == Symbol.UNDEFINED:
		scope_stack.define_func(symbol.identifier, body_label, argument_names.size())
	else:
		logger.log_error(
				"`%s` is already defined in the current scope!" % symbol.identifier,
				func_stmt.identifier_expr.span)
	
	scope_stack.push() # Buffer scope to clear scope.
	code.set_label(body_label)
	scope_stack.define_label("func", body_label)
	scope_stack.undefine_label("break")
	scope_stack.undefine_label("continue")
	scope_stack.undefine_label("menu")
	scope_stack.undefine_locals()
	
	scope_stack.push() # Argument definition scope.
	
	for argument_name in argument_names:
		scope_stack.define_local(argument_name, true)
	
	scope_stack.push() # Function body scope.
	visit_node(func_stmt.stmt)
	code.make_push_int(0)
	code.make_return_from_function()
	scope_stack.pop()
	
	scope_stack.pop() # End argument definition scope.
	scope_stack.pop() # End buffer scope.
	
	code.set_label(parent_label)


# Visit a block statement AST node.
func visit_block_stmt(block_stmt: BlockStmtASTNode) -> void:
	scope_stack.push()
	
	for stmt in block_stmt.stmts:
		visit_node(stmt)
	
	scope_stack.pop()


# Visit an if statement AST node.
func visit_if_stmt(if_stmt: IfStmtASTNode) -> void:
	var expr: ExprASTNode = folder.fold_expr(if_stmt.expr)
	
	if expr is IntExprASTNode:
		if expr.value != 0:
			scope_stack.push()
			visit_node(if_stmt.stmt)
			scope_stack.pop()
		else:
			var parent_label: String = code.get_label()
			var body_label: String = code.append_unique_label("if_unreachable")
			
			scope_stack.push()
			code.set_label(body_label)
			visit_node(if_stmt.stmt)
			scope_stack.pop()
			code.make_halt()
			
			code.set_label(parent_label)
		
		return
	
	var end_label: String = code.insert_unique_label("if_end")
	
	visit_node(expr)
	code.make_jump_zero_label(end_label)
	
	scope_stack.push()
	visit_node(if_stmt.stmt)
	scope_stack.pop()
	
	code.set_label(end_label)


# Visit an if-else statement AST node.
func visit_if_else_stmt(if_else_stmt: IfElseStmtASTNode) -> void:
	var expr: ExprASTNode = folder.fold_expr(if_else_stmt.expr)
	
	if expr is IntExprASTNode:
		if expr.value != 0:
			scope_stack.push()
			visit_node(if_else_stmt.then_stmt)
			scope_stack.pop()
			
			var parent_label: String = code.get_label()
			var body_label: String = code.append_unique_label("if_else_unreachable_else")
			
			scope_stack.push()
			code.set_label(body_label)
			visit_node(if_else_stmt.else_stmt)
			scope_stack.pop()
			code.make_halt()
			
			code.set_label(parent_label)
		else:
			var parent_label: String = code.get_label()
			var body_label: String = code.append_unique_label("if_else_unreachable_then")
			
			scope_stack.push()
			code.set_label(body_label)
			visit_node(if_else_stmt.then_stmt)
			scope_stack.pop()
			code.make_halt()
			
			code.set_label(parent_label)
			
			scope_stack.push()
			visit_node(if_else_stmt.else_stmt)
			scope_stack.pop()
		
		return
	
	var end_label: String = code.insert_unique_label("if_else_end")
	var else_label: String = code.insert_unique_label("if_else_else")
	
	visit_node(expr)
	code.make_jump_zero_label(else_label)
	
	scope_stack.push()
	visit_node(if_else_stmt.then_stmt)
	scope_stack.pop()
	code.make_jump_label(end_label)
	
	scope_stack.push()
	code.set_label(else_label)
	visit_node(if_else_stmt.else_stmt)
	scope_stack.pop()
	
	code.set_label(end_label)


# Visit a while statement AST node.
func visit_while_stmt(while_stmt: WhileStmtASTNode) -> void:
	var expr: ExprASTNode = folder.fold_expr(while_stmt.expr)
	
	if expr is IntExprASTNode:
		if expr.value != 0:
			var end_label: String = code.insert_unique_label("while_forever_end")
			var body_label: String = code.insert_unique_label("while_forever")
			
			scope_stack.push()
			code.set_label(body_label)
			scope_stack.define_label("break", end_label)
			scope_stack.define_label("continue", body_label)
			visit_node(while_stmt.stmt)
			scope_stack.pop()
			code.make_jump_label(body_label)
			
			code.set_label(end_label)
		else:
			var parent_label: String = code.get_label()
			var body_label: String = code.append_unique_label("while_unreachable")
			
			scope_stack.push()
			code.set_label(body_label)
			var end_label: String = code.insert_unique_label("while_unreachable_end")
			scope_stack.define_label("break", end_label)
			scope_stack.define_label("continue", end_label)
			visit_node(while_stmt.stmt)
			scope_stack.pop()
			code.make_jump_label(end_label)
			code.set_label(end_label)
			code.make_halt()
			
			code.set_label(parent_label)
		
		return
	
	var end_label: String = code.insert_unique_label("while_end")
	var condition_label: String = code.insert_unique_label("while_condition")
	
	code.set_label(condition_label)
	visit_node(expr)
	code.make_jump_zero_label(end_label)
	
	scope_stack.push()
	scope_stack.define_label("break", end_label)
	scope_stack.define_label("continue", condition_label)
	visit_node(while_stmt.stmt)
	scope_stack.pop()
	code.make_jump_label(condition_label)
	
	code.set_label(end_label)


# Visit a menu statement AST node.
func visit_menu_stmt(menu_stmt: MenuStmtASTNode) -> void:
	if scope_stack.has_label("menu"):
		logger.log_error("Cannot use `menu` directly inside of a menu!", menu_stmt.span)
		return
	
	var end_label: String = code.insert_unique_label("menu_end")
	
	scope_stack.push()
	scope_stack.define_label("menu", end_label)
	scope_stack.undefine_label("break")
	scope_stack.undefine_label("continue")
	visit_node(menu_stmt.stmt)
	scope_stack.pop()
	code.make_show_dialog_menu()
	
	code.set_label(end_label)


# Visit an option statement AST node.
func visit_option_stmt(option_stmt: OptionStmtASTNode) -> void:
	if not scope_stack.has_label("menu"):
		logger.log_error("Cannot use `option` outside of a menu!", option_stmt.span)
		return
	
	var parent_label: String = code.get_label()
	var option_label: String = code.append_unique_label("option")
	
	visit_node(folder.fold_expr(option_stmt.expr))
	code.make_store_dialog_menu_option_label(option_label)
	
	scope_stack.push() # Buffer scope to prevent dropping parent locals.
	scope_stack.define_label("menu", scope_stack.get_label("menu"))
	
	scope_stack.push() # Option body scope.
	scope_stack.undefine_label("break")
	scope_stack.undefine_label("continue")
	scope_stack.undefine_label("menu")
	code.set_label(option_label)
	visit_node(option_stmt.stmt)
	scope_stack.pop() # End option body scope.
	
	scope_stack.jump_to_label("menu")
	scope_stack.pop() # End buffer scope.
	
	code.set_label(parent_label)


# Visit a break statement AST node.
func visit_break_stmt(break_stmt: BreakStmtASTNode) -> void:
	if scope_stack.has_label("break"):
		scope_stack.jump_to_label("break")
	else:
		logger.log_error("Cannot use `break` outside of loop!", break_stmt.span)


# Visit a continue statement AST node.
func visit_continue_stmt(continue_stmt: ContinueStmtASTNode) -> void:
	if scope_stack.has_label("continue"):
		scope_stack.jump_to_label("continue")
	else:
		logger.log_error("Cannot use `continue` outside of a loop!", continue_stmt.span)


# Visit a constant statement AST node.
func visit_const_stmt(const_stmt: ConstStmtASTNode) -> void:
	var symbol: Symbol = scope_stack.get_symbol(const_stmt.identifier_expr.name)
	var value_expr: ExprASTNode = folder.fold_expr(const_stmt.value_expr)
	
	if symbol.access != Symbol.UNDEFINED:
		logger.log_error(
				"`%s` is already defined in the current scope!" % symbol.identifier,
				const_stmt.identifier_expr.span)
		visit_node(value_expr)
		code.make_drop()
		return
	
	if value_expr is IntExprASTNode:
		scope_stack.define_literal_int(symbol.identifier, value_expr.value, false)
	elif value_expr is StrExprASTNode:
		scope_stack.define_literal_str(symbol.identifier, value_expr.value, false)
	else:
		logger.log_error(
				"Constant `%s` expects a constant value!" % symbol.identifier, value_expr.span)
		visit_node(value_expr)
		code.make_drop()


# Visit a variable statement AST node.
func visit_var_stmt(var_stmt: VarStmtASTNode) -> void:
	var symbol: Symbol = scope_stack.get_symbol(var_stmt.expr.name)
	
	if symbol.access != Symbol.UNDEFINED:
		logger.log_error(
				"`%s` is already defined in the current scope!" % symbol.identifier,
				var_stmt.expr.span)
		return
	
	code.make_push_int(0)
	scope_stack.define_local(symbol.identifier, true)


# Visit a variable expression statement AST node.
func visit_var_expr_stmt(var_expr_stmt: VarExprStmtASTNode) -> void:
	var symbol: Symbol = scope_stack.get_symbol(var_expr_stmt.identifier_expr.name)
	visit_node(folder.fold_expr(var_expr_stmt.value_expr))
	
	if symbol.access != Symbol.UNDEFINED:
		logger.log_error(
				"`%s` is already defined in the current scope!" % symbol.identifier,
				var_expr_stmt.identifier_expr.span)
		code.make_drop()
		return
	
	scope_stack.define_local(symbol.identifier, true)


# Visit a return statement AST node.
func visit_return_stmt(return_stmt: ReturnStmtASTNode) -> void:
	if not scope_stack.has_label("func"):
		logger.log_error("Cannot use `return` outside of a function!", return_stmt.span)
		return
	
	code.make_push_int(0)
	code.make_return_from_function()


# Visit a return expression statement AST node.
func visit_return_expr_stmt(return_expr_stmt: ReturnExprStmtASTNode) -> void:
	if not scope_stack.has_label("func"):
		logger.log_error("Cannot use `return` outside of a function!", return_expr_stmt.span)
		return
	
	visit_node(folder.fold_expr(return_expr_stmt.expr))
	code.make_return_from_function()


# Visit an expression statement AST node.
func visit_expr_stmt(expr_stmt: ExprStmtASTNode) -> void:
	visit_node(folder.fold_expr(expr_stmt.expr))
	code.make_drop()


# Visit a unary expression AST node.
func visit_un_expr(un_expr: UnExprASTNode) -> void:
	visit_node(un_expr.expr)
	
	if un_expr.operator == Token.KEYWORD_NOT:
		code.make_unary_not()
	elif un_expr.operator == Token.PLUS:
		pass # Unary plus intentionally does nothing, this is not a bug.
	elif un_expr.operator == Token.MINUS:
		code.make_unary_negate()
	else:
		logger.log_error(
				"Bug: No unary operation for operator %s!" % Token.get_name(un_expr.operator),
				un_expr.span)


# Visit a binary expression AST node.
func visit_bin_expr(bin_expr: BinExprASTNode) -> void:
	if bin_expr.operator == Token.KEYWORD_AND:
		var end_label: String = code.insert_unique_label("and_end")
		
		visit_node(bin_expr.lhs_expr)
		code.make_duplicate()
		code.make_jump_zero_label(end_label)
		code.make_drop()
		visit_node(bin_expr.rhs_expr)
		
		code.set_label(end_label)
	elif bin_expr.operator == Token.KEYWORD_OR:
		var end_label: String = code.insert_unique_label("or_end")
		
		visit_node(bin_expr.lhs_expr)
		code.make_duplicate()
		code.make_jump_not_zero_label(end_label)
		code.make_drop()
		visit_node(bin_expr.rhs_expr)
		
		code.set_label(end_label)
	elif bin_expr.operator == Token.EQUALS:
		visit_node(bin_expr.rhs_expr)
		
		if not bin_expr.lhs_expr is IdentifierExprASTNode:
			logger.log_error("Can only assign to a variable!", bin_expr.lhs_expr.span)
			visit_node(bin_expr.lhs_expr)
			code.make_drop()
			return
		
		var symbol: Symbol = scope_stack.get_symbol(bin_expr.lhs_expr.name)
		
		if symbol.access == Symbol.UNDEFINED:
			visit_node(bin_expr.lhs_expr)
			code.make_drop()
			return
		elif not symbol.is_mutable:
			logger.log_error(
					"Cannot assign to non-variable `%s`!" % symbol.identifier,
					bin_expr.lhs_expr.span)
			return
		
		if symbol.access == Symbol.LOCAL:
			code.make_store_local_offset(symbol.int_value)
		else:
			logger.log_error(
					"Bug: No mutator for access type %d!" % symbol.access, bin_expr.lhs_expr.span)
	else:
		visit_node(bin_expr.lhs_expr)
		visit_node(bin_expr.rhs_expr)
		
		if bin_expr.operator == Token.BANG_EQUALS:
			code.make_binary_not_equals()
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
		else:
			logger.log_error(
					"Bug: No binary operation for operator %s!" % Token.get_name(bin_expr.operator),
					bin_expr.span)
			
			# Binary expressions must only push a single value to the stack.
			code.make_drop()


# Visit a call expression AST node.
func visit_call_expr(call_expr: CallExprASTNode) -> void:
	if not call_expr.callee_expr is IdentifierExprASTNode:
		logger.log_error("Can only call a function!", call_expr.callee_expr.span)
		visit_invalid_call_expr(call_expr)
		return
	
	var symbol: Symbol = scope_stack.get_symbol(call_expr.callee_expr.name)
	
	if symbol.access == Symbol.UNDEFINED:
		visit_invalid_call_expr(call_expr)
		return
	elif not symbol.is_callable:
		logger.log_error(
				"Cannot call non-function `%s`!" % symbol.identifier, call_expr.callee_expr.span)
		visit_invalid_call_expr(call_expr)
		return
	
	if symbol.access == Symbol.INTRINSIC:
		visit_intrinsic_call_expr(call_expr)
	elif symbol.access == Symbol.FUNC:
		visit_func_call_expr(call_expr)
	else:
		logger.log_error("Bug: No caller for access type `%d`!" % symbol.access, call_expr.span)
		visit_invalid_call_expr(call_expr)


# Visit a call expression AST node that has been invalidated.
func visit_invalid_call_expr(call_expr: CallExprASTNode) -> void:
	visit_node(call_expr.callee_expr)
	
	for argument_expr in call_expr.argument_exprs:
		visit_node(argument_expr)
		code.make_drop()


# Visit an intrinsic call expression AST node.
func visit_intrinsic_call_expr(call_expr: CallExprASTNode) -> void:
	var symbol: Symbol = scope_stack.get_symbol(call_expr.callee_expr.name)
	var intrinsic_func_name: String = symbol.str_value
	
	# Handle special case intrinsics.
	if intrinsic_func_name.begins_with("*"):
		call(intrinsic_func_name.substr(1), call_expr)
		return
	
	var is_intrinsic_void: bool = true
	
	# Handle non-void intrinsics.
	if intrinsic_func_name.begins_with("="):
		is_intrinsic_void = false
		intrinsic_func_name = intrinsic_func_name.substr(1)
	
	for argument_expr in call_expr.argument_exprs:
		visit_node(argument_expr)
	
	if call_expr.argument_exprs.size() != symbol.int_value:
		if symbol.int_value == 1:
			logger.log_error(
					"`%s` expects 1 argument, got %d!"
					% [symbol.identifier, call_expr.argument_exprs.size()], call_expr.span)
		else:
			logger.log_error(
					"`%s` expects %d arguments, got %d!"
					% [symbol.identifier, symbol.int_value, call_expr.argument_exprs.size()],
					call_expr.span)
		
		for _i in range(call_expr.argument_exprs.size()):
			code.make_drop()
		
		code.make_push_int(0)
		return
	
	code.call(intrinsic_func_name)
	
	if is_intrinsic_void:
		code.make_push_int(0)


# Visit a call expression AST node with the format intrinsic.
func visit_format_intrinsic_call_expr(call_expr: CallExprASTNode) -> void:
	if call_expr.argument_exprs.empty():
		logger.log_error(
				"`%s` expects at least 1 argument, got 0!" % call_expr.callee_expr.name,
				call_expr.span)
		code.make_push_string("")
		return
	elif call_expr.argument_exprs.size() == 1:
		var argument_expr: ExprASTNode = call_expr.argument_exprs[0]
		
		if argument_expr is IntExprASTNode:
			code.make_push_string(String(argument_expr.value))
		elif argument_expr is StrExprASTNode:
			code.make_push_string(argument_expr.value)
		else:
			code.make_push_string("{0}")
			visit_node(argument_expr)
			code.make_push_int(1)
			code.make_format_string()
		
		return
	
	for argument_expr in call_expr.argument_exprs:
		visit_node(argument_expr)
	
	code.make_push_int(call_expr.argument_exprs.size() - 1)
	code.make_format_string()


# Visit a call expression AST node with the name intrinsic.
func visit_name_intrinsic_call_expr(call_expr: CallExprASTNode) -> void:
	if call_expr.argument_exprs.empty():
		code.make_clear_dialog_name()
	elif call_expr.argument_exprs.size() == 1:
		visit_node(call_expr.argument_exprs[0])
		code.make_display_dialog_name()
	else:
		logger.log_error(
				"`%s` expects 0 or 1 arguments, got %d!"
				% [call_expr.callee_expr.name, call_expr.argument_exprs.size()], call_expr.span)
		
		for argument_expr in call_expr.argument_exprs:
			visit_node(argument_expr)
			code.make_drop()
	
	code.make_push_int(0)


# Visit a call expression AST node with the set flag intrinsic.
func visit_set_flag_intrinsic_call_expr(call_expr: CallExprASTNode) -> void:
	if call_expr.argument_exprs.size() != 2:
		logger.log_error(
				"`%s` expects 2 arguments, got %d!"
				% [call_expr.callee_expr.name, call_expr.argument_exprs.size()],
				call_expr.span)
		
		for argument_expr in call_expr.argument_exprs:
			visit_node(argument_expr)
			code.make_drop()
		
		code.make_push_int(0)
		return
	
	visit_node(call_expr.argument_exprs[1])
	visit_node(call_expr.argument_exprs[0])
	code.make_store_flag()


# Visit a function call expression AST node.
func visit_func_call_expr(call_expr: CallExprASTNode) -> void:
	var symbol: Symbol = scope_stack.get_symbol(call_expr.callee_expr.name)
	
	if call_expr.argument_exprs.size() != symbol.int_value:
		if symbol.int_value == 1:
			logger.log_error(
					"`%s` expects 1 argument, got %d!"
					% [symbol.identifier, call_expr.argument_exprs.size()], call_expr.span)
		else:
			logger.log_error(
					"`%s` expects %d arguments, got %d!"
					% [symbol.identifier, symbol.int_value, call_expr.argument_exprs.size()],
					call_expr.span)
		
		for argument_expr in call_expr.argument_exprs:
			visit_node(argument_expr)
			code.make_drop()
		
		code.make_push_int(0)
		return
	
	for argument_expr in call_expr.argument_exprs:
		visit_node(argument_expr)
	
	code.make_push_int(symbol.int_value)
	code.make_call_function_label(symbol.str_value)


# Visit an integer expression AST node.
func visit_int_expr(int_expr: IntExprASTNode) -> void:
	code.make_push_int(int_expr.value)


# Visit a string expression AST node.
func visit_str_expr(str_expr: StrExprASTNode) -> void:
	code.make_push_string(str_expr.value)


# Visit an identifier expression AST node.
func visit_identifier_expr(identifier_expr: IdentifierExprASTNode) -> void:
	var symbol: Symbol = scope_stack.get_symbol(identifier_expr.name)
	
	if symbol.access == Symbol.UNDEFINED:
		logger.log_error(
				"`%s` is undefined in the current scope!" % symbol.identifier, identifier_expr.span)
		code.make_push_int(0)
		return
	elif not symbol.is_evaluable:
		logger.log_error(
				"Cannot evaluate non-value `%s`!" % symbol.identifier, identifier_expr.span)
		code.make_push_int(0)
		return
	
	if symbol.access == Symbol.LITERAL_INT:
		code.make_push_int(symbol.int_value)
	elif symbol.access == Symbol.LITERAL_STR:
		code.make_push_string(symbol.str_value)
	elif symbol.access == Symbol.LOCAL:
		code.make_load_local_offset(symbol.int_value)
	else:
		logger.log_error(
				"Bug: No evaluator for access type %d!" % symbol.access, identifier_expr.span)
		code.make_push_int(0)
