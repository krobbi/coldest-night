extends Reference

# Code Generator
# The code generator is a component of the NightScript compiler that converts an
# abstract syntax tree to an IR program.

const ASTNode: GDScript = preload("ast_node.gd")
const CodegenScope: GDScript = preload("codegen_scope.gd")
const CodegenSymbol: GDScript = preload("codegen_symbol.gd")
const CompileErrorLog: GDScript = preload("compile_error_log.gd")
const IRCode: GDScript = preload("../backend/ir_code.gd")
const IROp: GDScript = preload("../backend/ir_op.gd")

var error_log: CompileErrorLog
var code: IRCode
var scopes: Array = []

# Pass the compile error log and IR code to the code generator:
func _init(error_log_ref: CompileErrorLog, code_ref: IRCode) -> void:
	error_log = error_log_ref
	code = code_ref


# Gets a label for the current scope from its key. Returns an empty string if
# there is no label in the current scope with the given key:
func get_scoped_label(key: String) -> String:
	for i in range(scopes.size() - 1, -1, -1):
		if scopes[i].scoped_labels.has(key):
			return scopes[i].scoped_labels[key]
	
	return ""


# Gets a symbol for the current scope from its identifier. Returns an undeclared
# symbol if there is no symbol in the current scope with the given identifier:
func get_symbol(identifier: String) -> CodegenSymbol:
	for i in range(scopes.size() - 1, -1, -1):
		if scopes[i].symbols.has(identifier):
			return scopes[i].symbols[identifier]
	
	return CodegenSymbol.new(identifier, CodegenSymbol.UNDECLARED)


# Logs an error message:
func err(message: String) -> void:
	error_log.log_error(message)


# Generate IR code from an abstract syntax tree.
func generate_code(ast: ASTNode) -> void:
	code.reset()
	
	var main_label: String = code.get_label()
	var entry_label: String = code.append_unique_label("entry")
	
	code.set_label(entry_label)
	scopes.resize(1)
	scopes[0] = CodegenScope.new({})
	ast = fold_statements(ast)
	visit_node(ast)
	code.make_halt()
	
	if not error_log.has_errors():
		return
	
	code.set_label(main_label)
	code.make_freeze_player()
	
	if not code.is_pausable:
		code.make_pause_game()
	
	code.make_show_dialog()
	code.make_display_dialog_name_text("Error")
	
	for error in error_log.get_errors():
		code.make_display_dialog_message_text(error.message)
	
	code.make_clear_dialog_name()
	code.make_hide_dialog()
	
	if not code.is_pausable:
		code.make_unpause_game()
	
	code.make_thaw_player()
	code.make_push_int(0)
	code.make_sleep()


# Pushes a new scope to the scope stack from its scoped labels:
func push_scope(scoped_labels: Dictionary) -> void:
	scopes.push_back(CodegenScope.new(scoped_labels))


# Pops the top scope from the scope stack if it is not the global scope:
func pop_scope() -> void:
	var top_index: int = scopes.size() - 1
	
	if top_index > 0:
		scopes.remove(top_index)


# Declares an int symbol in the current scope from its identifier and value:
func declare_int(identifier: String, value: int) -> void:
	var symbol: CodegenSymbol = CodegenSymbol.new(identifier, CodegenSymbol.INT)
	symbol.int_value = value
	scopes[-1].symbols[identifier] = symbol


# Declares a flag symbol in the current scope from its identifier, namespace,
# and key:
func declare_flag(identifier: String, namespace: String, key: String) -> void:
	var symbol: CodegenSymbol = CodegenSymbol.new(identifier, CodegenSymbol.FLAG)
	symbol.namespace_value = namespace
	symbol.key_value = key
	scopes[-1].symbols[identifier] = symbol


# Recursively eliminates erroneous and redundant statements from an AST node and
# its children by propagating them up the abstract syntax tree until they can be
# removed from a compound statement. Returns the statement-folded equivalent of
# the AST node:
func fold_statements(node: ASTNode) -> ASTNode:
	for i in range(node.children.size()):
		node.children[i] = fold_statements(node.children[i])
	
	if node.type == ASTNode.COMPOUND_STMT:
		for i in range(node.children.size() - 1, -1, -1):
			var child: ASTNode = node.children[i]
			
			if(
					child.type == ASTNode.ERROR or child.type == ASTNode.NOP_STMT
					or child.type == ASTNode.COMPOUND_STMT and child.children.empty()
			):
				node.children.remove(i)
		
		if node.children.size() == 1 and node.children[0].type == ASTNode.COMPOUND_STMT:
			return node.children[0]
	else:
		for child in node.children:
			if child.type == ASTNode.ERROR:
				return child
	
	return node


# Recursively performs constant folding on an expression AST node and its
# children. Returns the constant-folded equivalent of the AST node. Reads from
# and writes to flags are not eliminated as they may cause side-effects:
func fold_expression(node: ASTNode) -> ASTNode:
	# Do not fold assignment targets; expressions that would otherwise fold to a
	# variable are not allowed as assignment targets to avoid confusion:
	if node.type == ASTNode.ASSIGN_EXPR:
		node.children[1] = fold_expression(node.children[1])
	else:
		for i in range(node.children.size()):
			node.children[i] = fold_expression(node.children[i])
	
	var folded: ASTNode = node
	
	if node.type == ASTNode.IDENTIFIER:
		var symbol: CodegenSymbol = get_symbol(node.string_value)
		
		if symbol.type == CodegenSymbol.INT:
			folded.type = ASTNode.INT
			folded.int_value = symbol.int_value
	elif node.type == ASTNode.UN_EXPR:
		var child: ASTNode = node.children[0]
		var is_const: bool = child.type == ASTNode.INT
		
		if node.int_value == ASTNode.UN_NEG:
			if is_const:
				folded = child
				folded.int_value = -child.int_value
			elif child.type == ASTNode.UN_EXPR and child.int_value == ASTNode.UN_NEG:
				folded = child.children[0]
		elif node.int_value == ASTNode.UN_NOT:
			if is_const:
				folded = child
				folded.int_value = int(child.int_value == 0)
			elif(
					child.type == ASTNode.UN_EXPR and child.int_value == ASTNode.UN_NOT
					and child.children[0].type == ASTNode.UN_EXPR
					and child.children[0].int_value == ASTNode.UN_NOT
			):
				folded = child.children[0]
			elif child.type == ASTNode.UN_EXPR and child.int_value == ASTNode.UN_NEG:
				folded.children[0] = child.children[0]
	elif node.type == ASTNode.BIN_EXPR:
		var left: ASTNode = node.children[0]
		var right: ASTNode = node.children[1]
		var is_left_const: bool = left.type == ASTNode.INT
		var is_right_const: bool = right.type == ASTNode.INT
		var is_const: bool = is_left_const and is_right_const
		
		if node.int_value == ASTNode.BIN_ADD:
			if is_const:
				folded = left
				folded.int_value = left.int_value + right.int_value
			elif is_left_const and left.int_value == 0:
				folded = right
			elif is_right_const and right.int_value == 0:
				folded = left
		elif node.int_value == ASTNode.BIN_SUB:
			if is_const:
				folded = left
				folded.int_value = left.int_value - right.int_value
			elif is_left_const and left.int_value == 0:
				folded.type = ASTNode.UN_EXPR
				folded.int_value = ASTNode.UN_NEG
				folded.children.remove(0)
			elif is_right_const and right.int_value == 0:
				folded = left
		elif node.int_value == ASTNode.BIN_MUL:
			if is_const:
				folded = left
				folded.int_value = left.int_value * right.int_value
			elif is_left_const and left.int_value == 1:
				folded = right
			elif is_right_const and right.int_value == 1:
				folded = left
		elif node.int_value == ASTNode.BIN_EQ:
			if is_const:
				folded = left
				folded.int_value = int(left.int_value == right.int_value)
			elif is_left_const and left.int_value == 0:
				folded.type = ASTNode.UN_EXPR
				folded.int_value = ASTNode.UN_NOT
				folded.children.remove(0)
			elif is_right_const and right.int_value == 0:
				folded.type = ASTNode.UN_EXPR
				folded.int_value = ASTNode.UN_NOT
				folded.children.remove(1)
		elif is_const and node.int_value == ASTNode.BIN_NE:
			folded = left
			folded.int_value = int(left.int_value != right.int_value)
		elif is_const and node.int_value == ASTNode.BIN_GT:
			folded = left
			folded.int_value = int(left.int_value > right.int_value)
		elif is_const and node.int_value == ASTNode.BIN_GE:
			folded = left
			folded.int_value = int(left.int_value >= right.int_value)
		elif is_const and node.int_value == ASTNode.BIN_LT:
			folded = left
			folded.int_value = int(left.int_value < right.int_value)
		elif is_const and node.int_value == ASTNode.BIN_LE:
			folded = left
			folded.int_value = int(left.int_value <= right.int_value)
		elif is_const and node.int_value == ASTNode.BIN_AND:
			folded = left
			folded.int_value = int(left.int_value != 0 and right.int_value != 0)
		elif is_const and node.int_value == ASTNode.BIN_OR:
			folded = left
			folded.int_value = int(left.int_value != 0 or right.int_value != 0)
	elif node.type == ASTNode.BOOL_EXPR:
		var left: ASTNode = node.children[0]
		var right: ASTNode = node.children[1]
		var is_left_const: bool = left.type == ASTNode.INT
		var is_right_const: bool = right.type == ASTNode.INT
		var is_const: bool = is_left_const and is_right_const
		
		if is_const and node.int_value == ASTNode.BOOL_AND:
			folded = left
			folded.int_value = int(left.int_value != 0 and right.int_value != 0)
		elif is_const and node.int_value == ASTNode.BOOL_OR:
			folded = left
			folded.int_value = int(left.int_value != 0 or right.int_value != 0)
		elif is_left_const and node.int_value == ASTNode.BOOL_AND:
			if left.int_value == 0:
				folded = left
			else:
				folded.type = ASTNode.BIN_EXPR
				folded.int_value = ASTNode.BIN_AND
				folded.children[0].int_value = 1
		elif is_left_const and node.int_value == ASTNode.BOOL_OR:
			if left.int_value != 0:
				folded = left
				folded.int_value = 1
			else:
				folded.type = ASTNode.BIN_EXPR
				folded.int_value = ASTNode.BIN_OR
		elif is_right_const and node.int_value == ASTNode.BOOL_AND:
			folded.type = ASTNode.BIN_EXPR
			folded.int_value = ASTNode.BIN_AND
			
			if right.int_value != 0:
				folded.children[1].int_value = 1
		elif is_right_const and node.int_value == ASTNode.BOOL_OR:
			folded.type = ASTNode.BIN_EXPR
			folded.int_value = ASTNode.BIN_OR
			
			if right.int_value != 0:
				folded.children[1].int_value = 1
	
	return folded


# Recursively visits and evaluates an AST node and its children:
func visit_node(node: ASTNode) -> void:
	match node.type:
		ASTNode.ERROR:
			visit_error(node)
		ASTNode.IDENTIFIER:
			visit_identifier(node)
		ASTNode.FLAG:
			visit_flag(node)
		ASTNode.INT:
			visit_int(node)
		ASTNode.STRING:
			visit_string(node)
		ASTNode.NOP_STMT:
			visit_nop_stmt(node)
		ASTNode.COMPOUND_STMT:
			visit_compound_stmt(node)
		ASTNode.IF_STMT:
			visit_if_stmt(node)
		ASTNode.LOOP_STMT:
			visit_loop_stmt(node)
		ASTNode.MENU_STMT:
			visit_menu_stmt(node)
		ASTNode.OPTION_STMT:
			visit_option_stmt(node)
		ASTNode.SCOPED_JUMP_STMT:
			visit_scoped_jump_stmt(node)
		ASTNode.META_DECL_STMT:
			visit_meta_decl_stmt(node)
		ASTNode.DECL_STMT:
			visit_decl_stmt(node)
		ASTNode.OP_STMT:
			visit_op_stmt(node)
		ASTNode.TEXT_OP_STMT:
			visit_text_op_stmt(node)
		ASTNode.EXPR_OP_STMT:
			visit_expr_op_stmt(node)
		ASTNode.ACTOR_FACE_DIRECTION_STMT:
			visit_actor_face_direction_stmt(node)
		ASTNode.PATH_STMT:
			visit_path_stmt(node)
		ASTNode.DISPLAY_DIALOG_NAME_STMT:
			visit_display_dialog_name_stmt(node)
		ASTNode.IS_REPEAT_EXPR:
			visit_is_repeat_expr(node)
		ASTNode.UN_EXPR:
			visit_un_expr(node)
		ASTNode.BIN_EXPR:
			visit_bin_expr(node)
		ASTNode.BOOL_EXPR:
			visit_bool_expr(node)
		ASTNode.ASSIGN_EXPR:
			visit_assign_expr(node)
		_:
			err("Codegen bug: Unimplemented visitor for AST node type '%d'!" % node.type)


# Visits and evaluates an error AST node:
func visit_error(_node: ASTNode) -> void:
	err("Codegen bug: Error AST node not eliminated at time of visiting!")


# Visits and evaluates an identifier AST node:
func visit_identifier(node: ASTNode) -> void:
	var symbol: CodegenSymbol = get_symbol(node.string_value)
	
	match symbol.type:
		CodegenSymbol.UNDECLARED:
			err("Identifier '%s' is undeclared in the current scope!" % symbol.identifier)
			code.make_push_int(0) # Preserve stack size.
		CodegenSymbol.INT:
			code.make_push_int(symbol.int_value)
		CodegenSymbol.FLAG:
			code.make_load_flag_namespace_key(symbol.namespace_value, symbol.key_value)
		_:
			err("Codegen bug: Unimplemented visitor for symbol type '%d'!" % symbol.type)
			code.make_push_int(0) # Preserve stack size.


# Visits and evaluates a flag AST node:
func visit_flag(node: ASTNode) -> void:
	code.make_load_flag_namespace_key(node.children[0].string_value, node.children[1].string_value)


# Visits and evaluates an int AST node:
func visit_int(node: ASTNode) -> void:
	code.make_push_int(node.int_value)


# Visits and evaluates a string AST node:
func visit_string(_node: ASTNode) -> void:
	err("String expressions are not supported in NightScript version 2!")


# Visits and evaluates a no operation statement AST node:
func visit_nop_stmt(_node: ASTNode) -> void:
	pass


# Recursively visits and evaluates a compound statement AST node and its
# children:
func visit_compound_stmt(node: ASTNode) -> void:
	push_scope({})
	
	for child in node.children:
		visit_node(child)
	
	pop_scope()


# Recursively visits and evaluates an if statement AST node and its children:
func visit_if_stmt(node: ASTNode) -> void:
	var end_label: String = code.insert_unique_label("if_end")
	var true_label: String = code.insert_unique_label("if_true")
	var false_label: String = code.insert_unique_label("if_false")
	
	var expr: ASTNode = fold_expression(node.children[0])
	
	if expr.type == ASTNode.INT:
		if expr.int_value != 0:
			code.make_jump_label(true_label)
		else:
			code.make_jump_label(false_label)
	else:
		visit_node(expr)
		code.make_jump_not_zero_label(true_label)
		code.make_jump_label(false_label)
	
	code.set_label(true_label)
	push_scope({})
	visit_node(node.children[1])
	code.make_jump_label(end_label)
	pop_scope()
	
	code.set_label(false_label)
	push_scope({})
	visit_node(node.children[2])
	code.make_jump_label(end_label)
	pop_scope()
	
	code.set_label(end_label)


# Recursively visits and evaluates a loop statement AST node and its children:
func visit_loop_stmt(node: ASTNode) -> void:
	var end_label: String = code.insert_unique_label("loop_end")
	var condition_label: String = code.insert_unique_label("loop_condition")
	var body_label: String = code.insert_unique_label("loop_body")
	
	if node.int_value == ASTNode.LOOP_DO_WHILE:
		code.make_jump_label(body_label)
	else:
		code.make_jump_label(condition_label)
	
	code.set_label(condition_label)
	var expr: ASTNode = fold_expression(node.children[0])
	
	if expr.type == ASTNode.INT:
		if expr.int_value != 0:
			code.make_jump_label(body_label)
		else:
			code.make_jump_label(end_label)
	else:
		visit_node(expr)
		code.make_jump_not_zero_label(body_label)
		code.make_jump_label(end_label)
	
	code.set_label(body_label)
	push_scope({"break": end_label, "continue": condition_label})
	visit_node(node.children[1])
	code.make_jump_label(condition_label)
	pop_scope()
	
	code.set_label(end_label)


# Recursively visits and evaluates a menu statement AST node and its children:
func visit_menu_stmt(node: ASTNode) -> void:
	if not get_scoped_label("menu").empty():
		err("Cannot directly nest menu statements inside other menu statements!")
		return
	
	var end_label: String = code.insert_unique_label("menu_end")
	var show_label: String = code.insert_unique_label("menu_show")
	
	push_scope({"break": show_label, "continue": "", "menu": end_label})
	visit_node(node.children[0])
	code.make_jump_label(show_label)
	pop_scope()
	
	code.set_label(show_label)
	code.make_show_dialog_menu()
	
	code.set_label(end_label)


# Recursively visits and evaluates an option statement AST node and its
# children:
func visit_option_stmt(node: ASTNode) -> void:
	var menu_label: String = get_scoped_label("menu")
	
	if menu_label.empty():
		err("Cannot use option statement outside of a menu statement!")
		return
	
	var end_label: String = code.insert_unique_label("option_end")
	var body_label: String = code.insert_unique_label("option_body")
	
	code.make_store_dialog_menu_option_text_label(node.children[0].string_value, body_label)
	code.make_jump_label(end_label)
	
	code.set_label(body_label)
	push_scope({"break": menu_label, "continue": "", "menu": ""})
	visit_node(node.children[1])
	code.make_jump_label(menu_label)
	pop_scope()
	
	code.set_label(end_label)


# Visits and evaluates a scoped jump statement AST node:
func visit_scoped_jump_stmt(node: ASTNode) -> void:
	var key: String = node.children[0].string_value
	var label: String = get_scoped_label(key)
	
	if label.empty():
		err("Cannot jump to '%s' point!" % key)
		return
	
	code.make_jump_label(label)


# Visits and evaluates a meta declaration statement AST node:
func visit_meta_decl_stmt(node: ASTNode) -> void:
	var identifier: String = node.children[0].string_value
	var expr: ASTNode = fold_expression(node.children[1])
	
	if expr.type != ASTNode.INT:
		err("Metadata declaration '%s' expects a constant expression!" % identifier)
		return
	
	if identifier == "is_pausable":
		code.is_pausable = expr.int_value != 0


# Visits and evaluates a declaration statement AST node:
func visit_decl_stmt(node: ASTNode) -> void:
	var identifier: String = node.children[0].string_value
	
	if get_symbol(identifier).type != CodegenSymbol.UNDECLARED:
		err(
				"Cannot declare identifier '%s' as it is already declared in the current scope!"
				% identifier
		)
		return
	
	var expr: ASTNode = node.children[1]
	
	match node.int_value:
		ASTNode.DECL_DEFINE:
			if expr.type == ASTNode.FLAG:
				declare_flag(
						identifier, expr.children[0].string_value, expr.children[1].string_value
				)
				return
			
			expr = fold_expression(expr)
			
			if expr.type != ASTNode.INT:
				err(
						"Definition declaration '%s' expects a flag or a constant expression!"
						% identifier
				)
				return
			
			declare_int(identifier, expr.int_value)
		ASTNode.DECL_CONST:
			expr = fold_expression(expr)
			
			if expr.type != ASTNode.INT:
				err("Constant declaration '%s' expects a constant expression!" % identifier)
				return
			
			declare_int(identifier, expr.int_value)
		_:
			err("Codegen bug: Unimplemented visitor for declaration type '%d'!" % node.int_value)


# Make an IR code operation from an AST opcode.
func make_op_ir(opcode: int) -> void:
	match opcode:
		ASTNode.OP_HALT:
			code.make_halt()
		ASTNode.OP_SLEEP:
			code.make_sleep()
		ASTNode.OP_DROP:
			code.make_drop()
		ASTNode.OP_SHOW_DIALOG:
			code.make_show_dialog()
		ASTNode.OP_HIDE_DIALOG:
			code.make_hide_dialog()
		ASTNode.OP_RUN_ACTOR_PATHS:
			code.make_run_actor_paths()
		ASTNode.OP_AWAIT_ACTOR_PATHS:
			code.make_await_actor_paths()
		ASTNode.OP_FREEZE_PLAYER:
			code.make_freeze_player()
		ASTNode.OP_THAW_PLAYER:
			code.make_thaw_player()
		ASTNode.OP_QUIT_TO_TITLE:
			code.make_quit_to_title()
		ASTNode.OP_PAUSE_GAME:
			code.make_pause_game()
		ASTNode.OP_UNPAUSE_GAME:
			code.make_unpause_game()
		ASTNode.OP_SAVE_GAME:
			code.make_save_game()
		ASTNode.OP_SAVE_CHECKPOINT:
			code.make_save_checkpoint()
		_:
			err("Unimplemented opcode IR code '%d'!" % opcode)


# Visits and evaluates an operation statement AST node:
func visit_op_stmt(node: ASTNode) -> void:
	make_op_ir(node.int_value)


# Visits and evaluates a text operation statement AST node:
func visit_text_op_stmt(node: ASTNode) -> void:
	match node.int_value:
		ASTNode.OP_RUN_PROGRAM:
			code.make_run_program_key(node.children[0].string_value)
		ASTNode.OP_CALL_PROGRAM:
			code.make_call_program_key(node.children[0].string_value)
		ASTNode.OP_DISPLAY_DIALOG_MESSAGE:
			code.make_display_dialog_message_text(node.children[0].string_value)


# Recursively visits and evaluates an expression operation statement AST node
# and its children:
func visit_expr_op_stmt(node: ASTNode) -> void:
	visit_node(fold_expression(node.children[0]))
	make_op_ir(node.int_value)


func visit_actor_face_direction_stmt(node: ASTNode) -> void:
	code.make_push_string(node.children[0].string_value)
	visit_node(fold_expression(node.children[1]))
	code.make_actor_face_direction()


# Visits and evaluates a path finding statement AST node:
func visit_path_stmt(node: ASTNode) -> void:
	code.make_actor_find_path_key_point(
			node.children[0].string_value, node.children[1].string_value)
	
	if node.int_value == ASTNode.PATH_RUN or node.int_value == ASTNode.PATH_RUN_AWAIT:
		code.make_run_actor_paths()
	
	if node.int_value == ASTNode.PATH_RUN_AWAIT:
		code.make_await_actor_paths()


# Visits and evaluates a display dialog name statement AST node:
func visit_display_dialog_name_stmt(node: ASTNode) -> void:
	var text: String = node.children[0].string_value
	
	if text.empty():
		code.make_clear_dialog_name()
	else:
		code.make_display_dialog_name_text(text)


# Visit and evaluate an is repeat expression AST node:
func visit_is_repeat_expr(_node: ASTNode) -> void:
	code.make_push_is_repeat()


# Recursively visits and evaluates a unary expression AST node and its children:
func visit_un_expr(node: ASTNode) -> void:
	visit_node(node.children[0])
	
	match node.int_value:
		ASTNode.UN_NEG:
			code.make_unary_negate()
		ASTNode.UN_NOT:
			code.make_unary_not()
		_:
			err("Codegen bug: Unimplemented visitor for unary operator type '%d'!" % node.int_value)


# Recursively visits and evaluates a binary expression AST node and its
# children:
func visit_bin_expr(node: ASTNode) -> void:
	visit_node(node.children[0])
	visit_node(node.children[1])
	
	match node.int_value:
		ASTNode.BIN_ADD:
			code.make_binary_add()
		ASTNode.BIN_SUB:
			code.make_binary_subtract()
		ASTNode.BIN_MUL:
			code.make_binary_multiply()
		ASTNode.BIN_EQ:
			code.make_binary_equals()
		ASTNode.BIN_NE:
			code.make_binary_not_equals()
		ASTNode.BIN_GT:
			code.make_binary_greater()
		ASTNode.BIN_GE:
			code.make_binary_greater_equals()
		ASTNode.BIN_LT:
			code.make_binary_less()
		ASTNode.BIN_LE:
			code.make_binary_less_equals()
		ASTNode.BIN_AND:
			code.make_binary_and()
		ASTNode.BIN_OR:
			code.make_binary_or()
		_:
			err(
					"Codegen bug: Unimplemented visitor for binary operator type '%d'!"
					% node.int_value
			)
			code.make_drop() # Preserve stack size.


# Recursively visits and evaluates a short-circuit boolean expression AST node
# and its children:
func visit_bool_expr(node: ASTNode) -> void:
	visit_node(node.children[0])
	
	match node.int_value:
		ASTNode.BOOL_AND:
			var end_label: String = code.insert_unique_label("bool_and_end")
			var long_label: String = code.insert_unique_label("bool_and_long")
			
			code.make_duplicate()
			code.make_jump_not_zero_label(long_label)
			code.make_jump_label(end_label)
			
			code.set_label(long_label)
			visit_node(node.children[1])
			code.make_binary_and()
			code.make_jump_label(end_label)
			
			code.set_label(end_label)
		ASTNode.BOOL_OR:
			var end_label: String = code.insert_unique_label("bool_or_end")
			var short_label: String = code.insert_unique_label("bool_or_short")
			
			code.make_jump_not_zero_label(short_label)
			code.make_push_int(0)
			visit_node(node.children[1])
			code.make_binary_or()
			code.make_jump_label(end_label)
			
			code.set_label(short_label)
			code.make_push_int(1)
			code.make_jump_label(end_label)
			
			code.set_label(end_label)
		_:
			err(
					"Codegen bug: Unimplemented visitor for boolean operator type '%d'!"
					% node.int_value
			)


# Recursively visits and evaluates an assignment expression AST node and its
# children:
func visit_assign_expr(node: ASTNode) -> void:
	visit_node(node.children[1])
	var target: ASTNode = node.children[0]
	
	match target.type:
		ASTNode.FLAG:
			code.make_store_flag_namespace_key(
					target.children[0].string_value, target.children[1].string_value)
		ASTNode.IDENTIFIER:
			var symbol: CodegenSymbol = get_symbol(target.string_value)
			
			if symbol.type != CodegenSymbol.FLAG:
				err(
						"Cannot assign to identifier '%s' as it is not declared as a variable!"
						% symbol.identifier
				)
				return
			
			code.make_store_flag_namespace_key(symbol.namespace_value, symbol.key_value)
		_:
			err("Cannot assign to a non-variable target!")
