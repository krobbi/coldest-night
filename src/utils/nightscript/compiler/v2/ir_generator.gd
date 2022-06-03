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


# Gets whether an AST node is a unary operator with a given type:
func is_unary_type(node: ASTNode, type: int) -> bool:
	return node.children.size() == 1 and node.children[0].type == type


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
					err("Codegen bug: Unimplemented command AST node '%d'!" % node.int_value)
		_:
			err("Codegen bug: Unimplemented AST node type '%d'!" % node.type)
