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
			if node.children.size() >= 1 and node.children[0].type == ASTNode.BLOCK:
				visit_node(node.children[0])
			else:
				err("Parse bug: Generated program without block operand!")
			
			program.make_hlt()
		ASTNode.BLOCK:
			for child in node.children:
				visit_node(child)
		ASTNode.COMMAND:
			match node.int_value:
				ASTNode.CMD_EXIT:
					program.make_hlt()
				ASTNode.CMD_DIALOG_SHOW:
					program.make_dgs()
				ASTNode.CMD_DIALOG_HIDE:
					program.make_dgh()
				ASTNode.CMD_SAY:
					if node.children.size() < 1 or node.children[0].type != ASTNode.STRING:
						err("Parse bug: Generated say command without string operand!")
						return
					
					program.make_dgm(node.children[0].string_value)
				ASTNode.CMD_PLAYER_FREEZE:
					program.make_plf()
				ASTNode.CMD_PLAYER_UNFREEZE:
					program.make_plt()
				_:
					err("Codegen bug: Unimplemented command AST node '%d'!" % node.int_value)
		_:
			err("Codegen bug: Unimplemented AST node type '%d'!" % node.type)
