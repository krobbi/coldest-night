extends Reference

# IR Generator
# The IR generator is a component of the NightScript compiler that generates an
# intermediate representation program from an abstract syntax tree.

const ASTNode: GDScript = preload("ast_node.gd")
const IRProgram: GDScript = preload("ir_program.gd")

var program: IRProgram = IRProgram.new()

# Gets an intermediate representation program from an abstract syntax tree:
func get_program(ast: ASTNode) -> IRProgram:
	begin()
	visit_node(ast)
	return program


# Gets whether an AST node is a unary operation:
func is_unary(node: ASTNode) -> bool:
	return node.children.size() == 1


# Gets whether an AST node is a unary operation with a given type:
func is_unary_type(node: ASTNode, type: int) -> bool:
	return is_unary(node) and node.children[0].type == type


# Gets whether an AST node is a binary operation:
func is_binary(node: ASTNode) -> bool:
	return node.children.size() == 2


# Begins the IR generator:
func begin() -> void:
	program = IRProgram.new()


# Logs an error message:
func err(_message: String) -> void:
	pass


# Recursively visits an abstract syntax tree node and its children and performs
# code generation:
func visit_node(node: ASTNode) -> void:
	match node.type:
		ASTNode.PROGRAM:
			if is_unary_type(node, ASTNode.BLOCK):
				visit_node(node.children[0])
			else:
				err("Parse bug: Generated a program without a unary block operand!")
			
			program.make_hlt()
		ASTNode.BLOCK:
			for child in node.children:
				visit_node(child)
		ASTNode.COMMAND:
			match node.int_value:
				ASTNode.CMD_EXIT:
					program.make_hlt()
				ASTNode.CMD_CALL:
					if is_unary_type(node, ASTNode.STRING):
						program.make_clp(node.children[0].string_value)
					else:
						err("Parse bug: Generated a call command without a unary string operand!")
				ASTNode.CMD_RUN:
					if is_unary_type(node, ASTNode.STRING):
						program.make_run(node.children[0].string_value)
					else:
						err("Parse bug: Generated a run command without a unary string operand!")
				ASTNode.CMD_SLEEP:
					for child in node.children:
						visit_node(child)
					
					program.make_slp()
				ASTNode.CMD_NAME:
					if is_unary_type(node, ASTNode.STRING):
						var value: String = node.children[0].string_value
						
						if value.empty():
							program.make_dnc()
						else:
							program.make_dnd(value)
					else:
						err("Parse bug: Generated a name command without a unary string operand!")
				ASTNode.CMD_DIALOG_SHOW:
					program.make_dgs()
				ASTNode.CMD_DIALOG_HIDE:
					program.make_dgh()
				ASTNode.CMD_SAY:
					if is_unary_type(node, ASTNode.STRING):
						program.make_dgm(node.children[0].string_value)
					else:
						err("Parse bug: Generated a say command without a unary string operand!")
				ASTNode.CMD_PLAYER_FREEZE:
					program.make_plf()
				ASTNode.CMD_PLAYER_UNFREEZE:
					program.make_plt()
				ASTNode.CMD_QUIT_TITLE:
					program.make_qtt()
				ASTNode.CMD_PAUSE:
					program.make_pse()
				ASTNode.CMD_UNPAUSE:
					program.make_unp()
				ASTNode.CMD_SAVE:
					program.make_sav()
				ASTNode.CMD_CHECKPOINT:
					program.make_ckp()
				_:
					err("Codegen bug: Unimplemented command '#%d'!" % node.int_value)
		ASTNode.IDENTIFIER:
			err("Identifier '%s' is undeclared in the current scope!" % node.string_value)
			program.make_phc(0)
		ASTNode.FLAG:
			program.make_phf(node.string_value, node.key_value)
		ASTNode.INT:
			program.make_phc(node.int_value)
		ASTNode.UNARY_OPERATION:
			if not is_unary(node):
				err("Parse bug: Generated a unary operator without a unary operand!")
				program.make_phc(0)
				return
			
			visit_node(node.children[0])
			
			match node.int_value:
				ASTNode.UN_NEG:
					program.make_neg()
				ASTNode.UN_NOT:
					program.make_not()
				_:
					err("Codegen bug: Unimplemented unary operation '#%d'!" % node.int_value)
					program.make_neg()
		ASTNode.BINARY_OPERATION:
			if not is_binary(node):
				err("Parse bug: Generated a binary operator without binary operands!")
				program.make_phc(0)
				return
			
			visit_node(node.children[0])
			visit_node(node.children[1])
			
			match node.int_value:
				ASTNode.BIN_ADD:
					program.make_add()
				ASTNode.BIN_SUB:
					program.make_sub()
				ASTNode.BIN_MUL:
					program.make_mul()
				ASTNode.BIN_EQ:
					program.make_ceq()
				ASTNode.BIN_NE:
					program.make_cne()
				ASTNode.BIN_GT:
					program.make_cgt()
				ASTNode.BIN_GE:
					program.make_cge()
				ASTNode.BIN_LT:
					program.make_clt()
				ASTNode.BIN_LE:
					program.make_cle()
				ASTNode.BIN_AND:
					program.make_and()
				ASTNode.BIN_OR:
					program.make_lor()
				_:
					err("Codegen bug: Unimplemented binary operation '#%d'!" % node.int_value)
					program.make_add()
		_:
			err("Codegen bug: Unimplemented node type '#%d'!" % node.type)
