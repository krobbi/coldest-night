extends Reference

# Code Generator
# The code generator is a component of the NightScript compiler that converts an
# abstract syntax tree to an IR program.

const ASTNode: GDScript = preload("ast_node.gd")
const CodegenScope: GDScript = preload("codegen_scope.gd")
const CodegenSymbol: GDScript = preload("codegen_symbol.gd")
const CompileErrorLog: GDScript = preload("compile_error_log.gd")
const IRProgram: GDScript = preload("ir_program.gd")

var error_log: CompileErrorLog
var program: IRProgram = IRProgram.new()
var scopes: Array = []
var declared_labels: Array = []

# Constructor. Passes the compile error log to the code generator:
func _init(error_log_ref: CompileErrorLog) -> void:
	error_log = error_log_ref


# Gets an IR program from an abstract syntax tree:
func get_program(ast: ASTNode) -> IRProgram:
	begin()
	ast = fold_statements(ast)
	declared_labels = discover_labels(ast)
	visit_node(ast)
	end()
	return program


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


# Begins the code generator:
func begin() -> void:
	program = IRProgram.new()
	scopes.resize(1)
	scopes[0] = CodegenScope.new({})
	declared_labels.clear()


# Ends the code generator:
func end() -> void:
	program.make_op(NightScript.HLT)
	
	# HACK: Get rid of goto statements pointing to unevaluated label statements:
	for block in program.blocks:
		for op in block.ops:
			if op.type == NightScript.JMP and not program.has_block(op.key_value):
				op.type = NightScript.HLT
	
	if not error_log.has_errors():
		return
	
	var is_repeatable: bool = program.has_block("repeat")
	var is_pausable: bool = program.get_metadata("is_pausable") != 0
	program.create_block_head("$error")
	
	if is_repeatable:
		program.create_block_head("$error_repeat")
		program.create_block_head("$error_main")
		
		program.set_label("$error_main")
		program.make_value(NightScript.PHC, 0)
		program.make_pointer(NightScript.JMP, "$error")
		
		program.set_label("$error_repeat")
		program.make_value(NightScript.PHC, 1)
		program.make_pointer(NightScript.JMP, "$error")
	
	program.set_label("$error")
	program.make_op(NightScript.PLF)
	
	if not is_pausable:
		program.make_op(NightScript.PSE)
	
	program.make_op(NightScript.DGS)
	
	for error in error_log.get_errors():
		program.make_text(NightScript.DND, "Error")
		program.make_text(NightScript.DGM, error.message)
	
	program.make_op(NightScript.DNC)
	program.make_op(NightScript.DGH)
	
	if not is_pausable:
		program.make_op(NightScript.UNP)
	
	program.make_op(NightScript.PLT)
	program.make_value(NightScript.PHC, 0)
	program.make_op(NightScript.SLP)
	
	if is_repeatable:
		program.make_pointer(NightScript.BNZ, "repeat")
	
	program.make_pointer(NightScript.JMP, "main" if program.has_block("main") else "$main")


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


# Recursively discovers user-declared labels from an AST node and its children:
func discover_labels(node: ASTNode) -> Array:
	var discovered_labels: Array = []
	
	for child in node.children:
		discovered_labels.append_array(discover_labels(child))
	
	if node.type == ASTNode.LABEL_STMT:
		discovered_labels.push_back(node.children[0].string_value)
	
	return discovered_labels


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
		ASTNode.LABEL_STMT:
			visit_label_stmt(node)
		ASTNode.GOTO_STMT:
			visit_goto_stmt(node)
		ASTNode.OP_STMT:
			visit_op_stmt(node)
		ASTNode.TEXT_OP_STMT:
			visit_text_op_stmt(node)
		ASTNode.EXPR_OP_STMT:
			visit_expr_op_stmt(node)
		ASTNode.PATH_STMT:
			visit_path_stmt(node)
		ASTNode.DISPLAY_DIALOG_NAME_STMT:
			visit_display_dialog_name_stmt(node)
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
			program.make_value(NightScript.PHC, 0) # Preserve stack size.
		CodegenSymbol.INT:
			program.make_value(NightScript.PHC, symbol.int_value)
		CodegenSymbol.FLAG:
			program.make_flag(NightScript.PHF, symbol.namespace_value, symbol.key_value)
		_:
			err("Codegen bug: Unimplemented visitor for symbol type '%d'!" % symbol.type)
			program.make_value(NightScript.PHC, 0) # Preserve stack size.


# Visits and evaluates a flag AST node:
func visit_flag(node: ASTNode) -> void:
	program.make_flag(NightScript.PHF, node.children[0].string_value, node.children[1].string_value)


# Visits and evaluates an int AST node:
func visit_int(node: ASTNode) -> void:
	program.make_value(NightScript.PHC, node.int_value)


# Visits and evaluates a string AST node:
func visit_string(_node: ASTNode) -> void:
	err("Codegen bug: String expressions are unimplemented!")


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
	var end_label: String = program.create_block_temp("if_end")
	var true_label: String = program.create_block_temp("if_true")
	var false_label: String = program.create_block_temp("if_false")
	
	var expr: ASTNode = fold_expression(node.children[0])
	
	if expr.type == ASTNode.INT:
		if expr.int_value != 0:
			program.make_pointer(NightScript.JMP, true_label)
		else:
			program.make_pointer(NightScript.JMP, false_label)
	else:
		visit_node(expr)
		program.make_pointer(NightScript.BNZ, true_label)
		program.make_pointer(NightScript.JMP, false_label)
	
	program.set_label(true_label)
	push_scope({})
	visit_node(node.children[1])
	program.make_pointer(NightScript.JMP, end_label)
	pop_scope()
	
	program.set_label(false_label)
	push_scope({})
	visit_node(node.children[2])
	program.make_pointer(NightScript.JMP, end_label)
	pop_scope()
	
	program.set_label(end_label)


# Recursively visits and evaluates a loop statement AST node and its children:
func visit_loop_stmt(node: ASTNode) -> void:
	var end_label: String = program.create_block_temp("loop_end")
	var condition_label: String = program.create_block_temp("loop_condition")
	var body_label: String = program.create_block_temp("loop_body")
	
	if node.int_value == ASTNode.LOOP_DO_WHILE:
		program.make_pointer(NightScript.JMP, body_label)
	else:
		program.make_pointer(NightScript.JMP, condition_label)
	
	program.set_label(condition_label)
	var expr: ASTNode = fold_expression(node.children[0])
	
	if expr.type == ASTNode.INT:
		if expr.int_value != 0:
			program.make_pointer(NightScript.JMP, body_label)
		else:
			program.make_pointer(NightScript.JMP, end_label)
	else:
		visit_node(expr)
		program.make_pointer(NightScript.BNZ, body_label)
		program.make_pointer(NightScript.JMP, end_label)
	
	program.set_label(body_label)
	push_scope({"break": end_label, "continue": condition_label})
	visit_node(node.children[1])
	program.make_pointer(NightScript.JMP, condition_label)
	pop_scope()
	
	program.set_label(end_label)


# Recursively visits and evaluates a menu statement AST node and its children:
func visit_menu_stmt(node: ASTNode) -> void:
	if not get_scoped_label("menu").empty():
		err("Cannot directly nest menu statements inside other menu statements!")
		return
	
	var end_label: String = program.create_block_temp("menu_end")
	var show_label: String = program.create_block_temp("menu_show")
	
	push_scope({"break": show_label, "continue": "", "menu": end_label})
	visit_node(node.children[0])
	program.make_pointer(NightScript.JMP, show_label)
	pop_scope()
	
	program.set_label(show_label)
	program.make_op(NightScript.MNS)
	
	program.set_label(end_label)


# Recursively visits and evaluates an option statement AST node and its
# children:
func visit_option_stmt(node: ASTNode) -> void:
	var menu_label: String = get_scoped_label("menu")
	
	if menu_label.empty():
		err("Cannot use option statement outside of a menu statement!")
		return
	
	var end_label: String = program.create_block_temp("option_end")
	var body_label: String = program.create_block_temp("option_body")
	
	program.make_pointer_text(NightScript.MNO, body_label, node.children[0].string_value)
	program.make_pointer(NightScript.JMP, end_label)
	
	program.set_label(body_label)
	push_scope({"break": menu_label, "continue": "", "menu": ""})
	visit_node(node.children[1])
	program.make_pointer(NightScript.JMP, menu_label)
	pop_scope()
	
	program.set_label(end_label)


# Visits and evaluates a scoped jump statement AST node:
func visit_scoped_jump_stmt(node: ASTNode) -> void:
	var key: String = node.children[0].string_value
	var label: String = get_scoped_label(key)
	
	if label.empty():
		err("Cannot jump to '%s' point!" % key)
		return
	
	program.make_pointer(NightScript.JMP, label)


# Visits and evaluates a meta declaration statement AST node:
func visit_meta_decl_stmt(node: ASTNode) -> void:
	var identifier: String = node.children[0].string_value
	
	if program.has_metadata(identifier):
		err("Cannot declare already declared metadata value '%s'!" % identifier)
		return
	
	var expr: ASTNode = fold_expression(node.children[1])
	
	if expr.type != ASTNode.INT:
		err("Metadata declaration '%s' expects a constant expression!" % identifier)
		return
	
	program.set_metadata(identifier, expr.int_value)


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


# Visits and evaluates a label statement AST node:
func visit_label_stmt(node: ASTNode) -> void:
	var label: String = node.children[0].string_value
	
	if program.has_block(label):
		err("Cannot declare already declared label '%s'!" % label)
		return
	
	program.create_block(label)	
	program.make_pointer(NightScript.JMP, label)
	program.set_label(label)


# Visits and evaluates a goto statement AST node:
func visit_goto_stmt(node: ASTNode) -> void:
	var label: String = node.children[0].string_value
	
	if not declared_labels.has(label):
		err("Cannot jump to undeclared label '%s'!" % label)
		program.make_op(NightScript.HLT)
		return
	
	program.make_pointer(NightScript.JMP, label)


# Visits and evaluates an operation statement AST node:
func visit_op_stmt(node: ASTNode) -> void:
	program.make_op(node.int_value)


# Visits and evaluates a text operation statement AST node:
func visit_text_op_stmt(node: ASTNode) -> void:
	program.make_text(node.int_value, node.children[0].string_value)


# Recursively visits and evaluates an expression operation statement AST node
# and its children:
func visit_expr_op_stmt(node: ASTNode) -> void:
	visit_node(fold_expression(node.children[0]))
	program.make_op(node.int_value)


# Visits and evaluates a path finding statement AST node:
func visit_path_stmt(node: ASTNode) -> void:
	program.make_text(NightScript.LAK, node.children[0].string_value)
	program.make_text(NightScript.APF, node.children[1].string_value)
	
	if node.int_value == ASTNode.PATH_RUN or node.int_value == ASTNode.PATH_RUN_AWAIT:
		program.make_op(NightScript.APR)
	
	if node.int_value == ASTNode.PATH_RUN_AWAIT:
		program.make_op(NightScript.APA)


# Visits and evaluates a display dialog name statement AST node:
func visit_display_dialog_name_stmt(node: ASTNode) -> void:
	var text: String = node.children[0].string_value
	
	if text.empty():
		program.make_op(NightScript.DNC)
	else:
		program.make_text(NightScript.DND, text)


# Recursively visits and evaluates a unary expression AST node and its children:
func visit_un_expr(node: ASTNode) -> void:
	visit_node(node.children[0])
	
	match node.int_value:
		ASTNode.UN_NEG:
			program.make_op(NightScript.NEG)
		ASTNode.UN_NOT:
			program.make_op(NightScript.NOT)
		_:
			err("Codegen bug: Unimplemented visitor for unary operator type '%d'!" % node.int_value)


# Recursively visits and evaluates a binary expression AST node and its
# children:
func visit_bin_expr(node: ASTNode) -> void:
	visit_node(node.children[0])
	visit_node(node.children[1])
	
	match node.int_value:
		ASTNode.BIN_ADD:
			program.make_op(NightScript.ADD)
		ASTNode.BIN_SUB:
			program.make_op(NightScript.SUB)
		ASTNode.BIN_MUL:
			program.make_op(NightScript.MUL)
		ASTNode.BIN_EQ:
			program.make_op(NightScript.CEQ)
		ASTNode.BIN_NE:
			program.make_op(NightScript.CNE)
		ASTNode.BIN_GT:
			program.make_op(NightScript.CGT)
		ASTNode.BIN_GE:
			program.make_op(NightScript.CGE)
		ASTNode.BIN_LT:
			program.make_op(NightScript.CLT)
		ASTNode.BIN_LE:
			program.make_op(NightScript.CLE)
		ASTNode.BIN_AND:
			program.make_op(NightScript.AND)
		ASTNode.BIN_OR:
			program.make_op(NightScript.LOR)
		_:
			err(
					"Codegen bug: Unimplemented visitor for binary operator type '%d'!"
					% node.int_value
			)
			program.make_op(NightScript.POP) # Preserve stack size.


# Recursively visits and evaluates a short-circuit boolean expression AST node
# and its children:
func visit_bool_expr(node: ASTNode) -> void:
	visit_node(node.children[0])
	
	match node.int_value:
		ASTNode.BOOL_AND:
			var end_label: String = program.create_block_temp("bool_and_end")
			var long_label: String = program.create_block_temp("bool_and_long")
			
			program.make_op(NightScript.DUP)
			program.make_pointer(NightScript.BNZ, long_label)
			program.make_pointer(NightScript.JMP, end_label)
			
			program.set_label(long_label)
			visit_node(node.children[1])
			program.make_op(NightScript.AND)
			program.make_pointer(NightScript.JMP, end_label)
			
			program.set_label(end_label)
		ASTNode.BOOL_OR:
			var end_label: String = program.create_block_temp("bool_or_end")
			var short_label: String = program.create_block_temp("bool_or_short")
			
			program.make_pointer(NightScript.BNZ, short_label)
			program.make_value(NightScript.PHC, 0)
			visit_node(node.children[1])
			program.make_op(NightScript.LOR)
			program.make_pointer(NightScript.JMP, end_label)
			
			program.set_label(short_label)
			program.make_value(NightScript.PHC, 1)
			program.make_pointer(NightScript.JMP, end_label)
			
			program.set_label(end_label)
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
			program.make_flag(
					NightScript.STF, target.children[0].string_value,
					target.children[1].string_value
			)
		ASTNode.IDENTIFIER:
			var symbol: CodegenSymbol = get_symbol(target.string_value)
			
			if symbol.type != CodegenSymbol.FLAG:
				err(
						"Cannot assign to identifier '%s' as it is not declared as a variable!"
						% symbol.identifier
				)
				return
			
			program.make_flag(NightScript.STF, symbol.namespace_value, symbol.key_value)
		_:
			err("Cannot assign to a non-variable target!")
