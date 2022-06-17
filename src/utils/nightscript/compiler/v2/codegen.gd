extends Reference

# Code Generator
# The code generator is a component of the NightScript compiler that converts an
# abstract syntax tree to an IR program.

const ASTNode: GDScript = preload("ast_node.gd")
const CodegenScope: GDScript = preload("codegen_scope.gd")
const IRProgram: GDScript = preload("ir_program.gd")

var program: IRProgram = IRProgram.new()
var scopes: Array = []

# Gets an IR program from an abstract syntax tree:
func get_program(ast: ASTNode) -> IRProgram:
	begin()
	visit_node(fold_statements(ast))
	end()
	return program


# Gets a label for the current scope from its key. Returns an empty string if
# there is no label in the current scope with the given key:
func get_scoped_label(key: String) -> String:
	for i in range(scopes.size() - 1, -1, -1):
		if scopes[i].labels.has(key):
			return scopes[i].labels[key]
	
	return ""


# Logs an error message:
func err(_message: String) -> void:
	pass


# Begins the code generator:
func begin() -> void:
	program = IRProgram.new()
	scopes.resize(1)
	scopes[0] = CodegenScope.new({})


# Ends the code generator:
func end() -> void:
	program.make_op(NightScript.HLT)


# Pushes a new scope to the scope stack from its overwritten labels:
func push_scope(labels: Dictionary) -> void:
	scopes.push_back(CodegenScope.new(labels))


# Pops the top scope from the scope stack if it is not the global scope:
func pop_scope() -> void:
	var top_index: int = scopes.size() - 1
	
	if top_index > 0:
		scopes.remove(top_index)


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
# children. Returns the constant-folded equivalent of the AST node:
func fold_expression(node: ASTNode) -> ASTNode:
	for i in range(node.children.size()):
		node.children[i] = fold_expression(node.children[i])
	
	var folded: ASTNode = node
	
	if node.type == ASTNode.UN_EXPR:
		var child: ASTNode = node.children[0]
		var is_const: bool = child.type == ASTNode.INT
		
		if is_const and node.int_value == ASTNode.UN_NEG:
			folded = child
			folded.int_value = -child.int_value
		elif is_const and node.int_value == ASTNode.UN_NOT:
			folded = child
			folded.int_value = int(child.int_value == 0)
	elif node.type == ASTNode.BIN_EXPR:
		var left: ASTNode = node.children[0]
		var right: ASTNode = node.children[1]
		var is_const: bool = left.type == ASTNode.INT and right.type == ASTNode.INT
		
		if is_const and node.int_value == ASTNode.BIN_ADD:
			folded = left
			folded.int_value = left.int_value + right.int_value
		elif is_const and node.int_value == ASTNode.BIN_SUB:
			folded = left
			folded.int_value = left.int_value - right.int_value
		elif is_const and node.int_value == ASTNode.BIN_MUL:
			folded = left
			folded.int_value = left.int_value * right.int_value
		elif is_const and node.int_value == ASTNode.BIN_EQ:
			folded = left
			folded.int_value = int(left.int_value == right.int_value)
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
	
	return folded


# Recursively visits and evaluates an AST node and its children:
func visit_node(node: ASTNode) -> void:
	match node.type:
		ASTNode.IDENTIFIER:
			err("Identifier expressions are unimplemented!")
			program.make_value(NightScript.PHC, 0) # Preserve stack size.
		ASTNode.FLAG:
			program.make_flag(
					NightScript.PHF, node.children[0].string_value, node.children[1].string_value
			)
		ASTNode.INT:
			program.make_value(NightScript.PHC, node.int_value)
		ASTNode.NOP_STMT:
			pass # Explicitly do nothing instead of throwing an error.
		ASTNode.COMPOUND_STMT:
			push_scope({})
			
			for child in node.children:
				visit_node(child)
			
			pop_scope()
		ASTNode.IF_STMT:
			var expr: ASTNode = fold_expression(node.children[0])
			
			if expr.type == ASTNode.INT:
				push_scope({})
				
				if expr.int_value != 0:
					visit_node(node.children[1])
				else:
					visit_node(node.children[2])
				
				pop_scope()
			else:
				var end_label: String = program.create_block_temp("if_end")
				var false_label: String = program.create_block_temp("if_false")
				var true_label: String = program.create_block_temp("if_true")
				
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
		ASTNode.LOOP_STMT:
			var expr: ASTNode = fold_expression(node.children[0])
			
			if expr.type != ASTNode.INT:
				var end_label: String = program.create_block_temp("loop_end")
				var condition_label: String = program.create_block_temp("loop_condition")
				var body_label: String = program.create_block_temp("loop_body")
				
				if node.int_value == ASTNode.LOOP_DO_WHILE:
					program.make_pointer(NightScript.JMP, body_label)
				else:
					program.make_pointer(NightScript.JMP, condition_label)
				
				program.set_label(condition_label)
				visit_node(expr)
				program.make_pointer(NightScript.BNZ, body_label)
				program.make_pointer(NightScript.JMP, end_label)
				
				program.set_label(body_label)
				push_scope({"break": end_label, "continue": condition_label})
				visit_node(node.children[1])
				program.make_pointer(NightScript.JMP, condition_label)
				pop_scope()
				
				program.set_label(end_label)
			elif expr.int_value != 0:
				var end_label: String = program.create_block_temp("infinite_loop_end")
				var body_label: String = program.create_block_temp("infinite_loop_body")
				
				program.make_pointer(NightScript.JMP, body_label)
				
				program.set_label(body_label)
				push_scope({"break": end_label, "continue": body_label})
				visit_node(node.children[1])
				program.make_pointer(NightScript.JMP, body_label)
				pop_scope()
				
				program.set_label(end_label)
		ASTNode.MENU_STMT:
			if not get_scoped_label("menu").empty():
				err("Menu statements cannot be directly nested!")
			else:
				var end_label: String = program.create_block_temp("menu_end")
				var show_label: String = program.create_block_temp("menu_show")
				
				push_scope({"break": show_label, "continue": "", "menu": end_label})
				visit_node(node.children[0])
				program.make_pointer(NightScript.JMP, show_label)
				pop_scope()
				
				program.set_label(show_label)
				program.make_op(NightScript.MNS)
				program.make_pointer(NightScript.JMP, end_label)
				
				program.set_label(end_label)
		ASTNode.OPTION_STMT:
			var menu_label: String = get_scoped_label("menu")
			
			if menu_label.empty():
				err("Option statements must be used inside a menu statement!")
			else:
				var end_label: String = program.create_block_temp("option_end")
				var body_label: String = program.create_block_temp("option_body")
				
				program.make_pointer_text(
						NightScript.MNO, body_label, node.children[0].string_value
				)
				program.make_pointer(NightScript.JMP, end_label)
				
				program.set_label(body_label)
				push_scope({"break": menu_label, "continue": "", "menu": ""})
				visit_node(node.children[1])
				program.make_pointer(NightScript.JMP, menu_label)
				pop_scope()
				
				program.set_label(end_label)
		ASTNode.SCOPED_JUMP_STMT:
			var key: String = node.children[0].string_value
			var label: String = get_scoped_label(key)
			
			if label.empty():
				err("Cannot jump to '%s' point!" % key)
			else:
				program.make_pointer(NightScript.JMP, label)
		ASTNode.META_DECL_STMT:
			var identifier: String = node.children[0].string_value
			var expr: ASTNode = fold_expression(node.children[1])
			
			if program.has_metadata(identifier):
				err("Metadata value '%s' is already declared!" % identifier)
			elif expr.type != ASTNode.INT:
				err("Metadata value '%s' expects a constant expression!" % expr)
			else:
				program.set_metadata(identifier, expr.int_value)
		ASTNode.EXIT_STMT:
			program.make_op(NightScript.HLT)
		ASTNode.CALL_STMT:
			program.make_text(NightScript.CLP, node.children[0].string_value)
		ASTNode.RUN_STMT:
			program.make_text(NightScript.RUN, node.children[0].string_value)
		ASTNode.SLEEP_STMT:
			visit_node(fold_expression(node.children[0]))
			program.make_op(NightScript.SLP)
		ASTNode.SHOW_DIALOG_STMT:
			program.make_op(NightScript.DGS)
		ASTNode.HIDE_DIALOG_STMT:
			program.make_op(NightScript.DGH)
		ASTNode.DISPLAY_DIALOG_NAME_STMT:
			var text: String = node.children[0].string_value
			
			if text.empty():
				program.make_op(NightScript.DNC)
			else:
				program.make_text(NightScript.DND, text)
		ASTNode.DISPLAY_DIALOG_MESSAGE_STMT:
			program.make_text(NightScript.DGM, node.children[0].string_value)
		ASTNode.FREEZE_PLAYER_STMT:
			program.make_op(NightScript.PLF)
		ASTNode.UNFREEZE_PLAYER_STMT:
			program.make_op(NightScript.PLT)
		ASTNode.EXPR_STMT:
			var expr: ASTNode = fold_expression(node.children[0])
			
			# Eliminate standalone constant expressions:
			if expr.type != ASTNode.INT:
				visit_node(expr)
				program.make_op(NightScript.POP) # Discard expression result.
		ASTNode.UN_EXPR:
			visit_node(node.children[0])
			
			match node.int_value:
				ASTNode.UN_NEG:
					program.make_op(NightScript.NEG)
				ASTNode.UN_NOT:
					program.make_op(NightScript.NOT)
				_:
					err("Codegen bug: Unimplemented unary operator '%d'!" % node.int_value)
		ASTNode.BIN_EXPR:
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
					err("Codegen bug: Unimplemented binary operator '%s'!" % node.int_value)
					program.make_op(NightScript.ADD) # Preserve stack size.
		ASTNode.ASSIGN_EXPR:
			visit_node(node.children[1])
			var target: ASTNode = node.children[0]
			
			if target.type == ASTNode.FLAG:
				program.make_flag(
						NightScript.STF,
						target.children[0].string_value, target.children[1].string_value
				)
			else:
				err("Assignment to non-variable!")
		_:
			err("Codegen bug: Unimplemented visitor for AST node type '%d'!" % node.type)
