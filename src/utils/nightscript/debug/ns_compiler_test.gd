extends Control

# NightScript Compiler Test Scene
# The NightScript compiler test scene is a test scene that tests the integrity
# of the NightScript compiler by compiling and disassembling NightScript source
# code.

const ASTNode: GDScript = preload("../compiler/v2/ast_node.gd")
const Codegen: GDScript = preload("../compiler/v2/codegen.gd")
const CompileErrorLog: GDScript = preload("../compiler/v2/compile_error_log.gd")
const IRBlock: GDScript = preload("../compiler/v2/ir_block.gd")
const IROp: GDScript = preload("../compiler/v2/ir_op.gd")
const IRProgram: GDScript = preload("../compiler/v2/ir_program.gd")
const Lexer: GDScript = preload("../compiler/v2/lexer.gd")
const Optimizer: GDScript = preload("../compiler/v2/optimizer.gd")
const Parser: GDScript = preload("../compiler/v2/parser.gd")
const Token: GDScript = preload("../compiler/v2/token.gd")

onready var parse_timer: Timer = $ParseTimer
onready var source_edit: TextEdit = $HBoxContainer/SourceEdit
onready var disassembly_edit: TextEdit = $HBoxContainer/DisassemblyEdit

# Virtual _ready method. Runs when the NightScript compiler test scene is
# entered. Sets the window's scale:
func _ready() -> void:
	Global.display.set_window_scale(0)


# Gets an operation's name from its opcode:
func get_op_name(opcode: int) -> String:
	match opcode:
		NightScript.HLT:
			return "HLT"
		NightScript.CLP:
			return "CLP"
		NightScript.RUN:
			return "RUN"
		NightScript.SLP:
			return "SLP"
		NightScript.JMP:
			return "JMP"
		NightScript.BNZ:
			return "BNZ"
		NightScript.PHC:
			return "PHC"
		NightScript.PHF:
			return "PHF"
		NightScript.DUP:
			return "DUP"
		NightScript.POP:
			return "POP"
		NightScript.STF:
			return "STF"
		NightScript.NEG:
			return "NEG"
		NightScript.ADD:
			return "ADD"
		NightScript.SUB:
			return "SUB"
		NightScript.MUL:
			return "MUL"
		NightScript.CEQ:
			return "CEQ"
		NightScript.CNE:
			return "CNE"
		NightScript.CGT:
			return "CGT"
		NightScript.CGE:
			return "CGE"
		NightScript.CLT:
			return "CLT"
		NightScript.CLE:
			return "CLE"
		NightScript.NOT:
			return "NOT"
		NightScript.AND:
			return "AND"
		NightScript.LOR:
			return "LOR"
		NightScript.DGS:
			return "DGS"
		NightScript.DGH:
			return "DGH"
		NightScript.DNC:
			return "DNC"
		NightScript.DND:
			return "DND"
		NightScript.DGM:
			return "DGM"
		NightScript.MNO:
			return "MNO"
		NightScript.MNS:
			return "MNS"
		NightScript.LAK:
			return "LAK"
		NightScript.AFD:
			return "AFD"
		NightScript.APF:
			return "APF"
		NightScript.APR:
			return "APR"
		NightScript.APA:
			return "APA"
		NightScript.PLF:
			return "PLF"
		NightScript.PLT:
			return "PLT"
		NightScript.QTT:
			return "QTT"
		NightScript.PSE:
			return "PSE"
		NightScript.UNP:
			return "UNP"
		NightScript.SAV:
			return "SAV"
		NightScript.CKP:
			return "CKP"
		_:
			return "Unknown: %d" % opcode


# Converts NightScript source code to an array of tokens:
func source_to_tokens(error_log: CompileErrorLog, source: String) -> Array:
	var lexer: Lexer = Lexer.new(error_log)
	lexer.begin(source)
	var token: Token = lexer.get_next_token()
	var tokens: Array = [token]
	
	while token.type != Token.END_OF_FILE:
		token = lexer.get_next_token()
		tokens.push_back(token)
	
	return tokens


# Converts an array of tokens to an abstract syntax tree:
func tokens_to_ast(error_log: CompileErrorLog, tokens: Array) -> ASTNode:
	var parser: Parser = Parser.new(error_log)
	return parser.get_ast(tokens)


# Escapes a string to a quoted string:
func escape_string(value: String) -> String:
	var type: String = '"' if value.count("'") >= value.count('"') else "'"
	var output: String = type
	
	for character in value:
		match character:
			"\t":
				output += "\\t"
			"\n":
				output += "\\n"
			"\\", type:
				output += "\\%s" % character
			_:
				output += character
	
	output += type
	return output


# Compiles NightScript source code and returns a compilation log:
func source_to_string(source: String) -> String:
	var output: String = "# Token Stream:\n"
	var error_log: CompileErrorLog = CompileErrorLog.new()
	error_log.clear()
	var tokens: Array = source_to_tokens(error_log, source)
	
	for token in tokens:
		output += "%s\n" % token_to_string(token)
	
	var ast: ASTNode = tokens_to_ast(error_log, tokens)
	output += "\n\n# Abstract Syntax Tree:\n%s" % ast_node_to_string(ast)
	
	var codegen: Codegen = Codegen.new(error_log)
	codegen.begin()
	ast = codegen.fold_statements(ast)
	output += "\n\n# Statement Folded AST:\n%s" % ast_node_to_string(ast)
	
	codegen.declared_labels = codegen.discover_labels(ast)
	codegen.visit_node(ast)
	codegen.end()
	var program: IRProgram = codegen.program
	output += "\n\n# IR Program:\n%s" % ir_program_to_string(program)
	
	var optimizer: Optimizer = Optimizer.new()
	optimizer.optimize_program(program)
	output += "\n\n# Optimized IR:\n%s" % ir_program_to_string(program)
	
	return output


# Converts a token to a string representation:
func token_to_string(token: Token) -> String:
	var output: String = "["
	
	match token.type:
		Token.END_OF_FILE:
			output += "End of file"
		Token.ERROR:
			output += "Error: %s" % token.string_value
		Token.IDENTIFIER:
			output += "Identifier: %s" % token.string_value
		Token.LITERAL_INT:
			output += "Literal int: %d" % token.int_value
		Token.LITERAL_STRING:
			output += "Literal string: %s" % escape_string(token.string_value)
		Token.KEYWORD_AND:
			output += "and"
		Token.KEYWORD_BREAK:
			output += "break"
		Token.KEYWORD_CALL:
			output += "call"
		Token.KEYWORD_CHECKPOINT:
			output += "checkpoint"
		Token.KEYWORD_CONST:
			output += "const"
		Token.KEYWORD_CONTINUE:
			output += "continue"
		Token.KEYWORD_DEFINE:
			output += "define"
		Token.KEYWORD_DO:
			output += "do"
		Token.KEYWORD_ELSE:
			output += "else"
		Token.KEYWORD_EXIT:
			output += "exit"
		Token.KEYWORD_FALSE:
			output += "false"
		Token.KEYWORD_GOTO:
			output += "goto"
		Token.KEYWORD_IF:
			output += "if"
		Token.KEYWORD_META:
			output += "meta"
		Token.KEYWORD_NOT:
			output += "not"
		Token.KEYWORD_OR:
			output += "or"
		Token.KEYWORD_PAUSE:
			output += "pause"
		Token.KEYWORD_QUIT:
			output += "quit"
		Token.KEYWORD_RUN:
			output += "run"
		Token.KEYWORD_SAVE:
			output += "save"
		Token.KEYWORD_TRUE:
			output += "true"
		Token.KEYWORD_UNPAUSE:
			output += "unpause"
		Token.KEYWORD_WHILE:
			output += "while"
		Token.BANG:
			output += "!"
		Token.BANG_EQUAL:
			output += "!="
		Token.BANG_GREATER:
			output += "!>"
		Token.AMPERSAND:
			output += "&"
		Token.AMPERSAND_AMPERSAND:
			output += "&&"
		Token.PARENTHESIS_OPEN:
			output += "("
		Token.PARENTHESIS_CLOSE:
			output += ")"
		Token.STAR:
			output += "*"
		Token.STAR_GREATER:
			output += "*>"
		Token.PLUS:
			output += "+"
		Token.MINUS:
			output += "-"
		Token.MINUS_GREATER:
			output += "->"
		Token.DOT:
			output += "."
		Token.COLON:
			output += ":"
		Token.SEMICOLON:
			output += ";"
		Token.LESS:
			output += "<"
		Token.LESS_BANG:
			output += "<!"
		Token.LESS_STAR:
			output += "<*"
		Token.LESS_EQUAL:
			output += "<="
		Token.EQUAL:
			output += "="
		Token.EQUAL_EQUAL:
			output += "=="
		Token.GREATER:
			output += ">"
		Token.GREATER_EQUAL:
			output += ">="
		Token.BRACE_OPEN:
			output += "{"
		Token.PIPE:
			output += "|"
		Token.PIPE_PIPE:
			output += "||"
		Token.BRACE_CLOSE:
			output += "}"
		Token.TILDE:
			output += "~"
		Token.TILDE_GREATER:
			output += "~>"
		_:
			output += "Unknown: %d" % token.type
	
	output += "]"
	return output


# Recursively converts an AST node and its children to a string representation:
func ast_node_to_string(node: ASTNode, flags: Array = []) -> String:
	var output: String = ""
	var depth: int = flags.size()
	
	for i in range(depth):
		var flag: bool = flags[i]
		
		if i == depth - 1:
			output += "|_" if flag else "|-"
		else:
			output += "  " if flag else "| "
	
	output += "("
	
	match node.type:
		ASTNode.ERROR:
			output += "Error: %s" % node.string_value
		ASTNode.IDENTIFIER:
			output += "Identifier: %s" % node.string_value
		ASTNode.FLAG:
			output += "Flag"
		ASTNode.INT:
			output += "Int: %d" % node.int_value
		ASTNode.STRING:
			output += "String: %s" % escape_string(node.string_value)
		ASTNode.NOP_STMT:
			output += "NopStmt"
		ASTNode.COMPOUND_STMT:
			output += "CompoundStmt"
		ASTNode.IF_STMT:
			output += "IfStmt"
		ASTNode.LOOP_STMT:
			output += "LoopStmt: "
			
			match node.int_value:
				ASTNode.LOOP_WHILE:
					output += "While"
				ASTNode.LOOP_DO_WHILE:
					output += "DoWhile"
				_:
					output += "Unknown: %d" % node.int_value
		ASTNode.MENU_STMT:
			output += "MenuStmt"
		ASTNode.OPTION_STMT:
			output += "OptionStmt"
		ASTNode.SCOPED_JUMP_STMT:
			output += "ScopedJumpStmt"
		ASTNode.META_DECL_STMT:
			output += "MetaDeclStmt"
		ASTNode.DECL_STMT:
			output += "DeclStmt: "
			
			match node.int_value:
				ASTNode.DECL_DEFINE:
					output += "Define"
				ASTNode.DECL_CONST:
					output += "Const"
				_:
					output += "Unknown: %d" % node.int_value
		ASTNode.LABEL_STMT:
			output += "LabelStmt"
		ASTNode.GOTO_STMT:
			output += "GotoStmt"
		ASTNode.OP_STMT:
			output += "OpStmt: %s" % get_op_name(node.int_value)
		ASTNode.TEXT_OP_STMT:
			output += "TextOpStmt: %s" % get_op_name(node.int_value)
		ASTNode.EXPR_OP_STMT:
			output += "ExprOpStmt: %s" % get_op_name(node.int_value)
		ASTNode.PATH_STMT:
			output += "PathStmt: "
			
			match node.int_value:
				ASTNode.PATH_FIND:
					output += "Find"
				ASTNode.PATH_RUN:
					output += "Run"
				ASTNode.PATH_RUN_AWAIT:
					output += "RunAwait"
				_:
					output += "Unknown: %d" % node.int_value
		ASTNode.DISPLAY_DIALOG_NAME_STMT:
			output += "DisplayDialogNameStmt"
		ASTNode.UN_EXPR:
			output += "UnExpr: "
			
			match node.int_value:
				ASTNode.UN_NEG:
					output += "Neg"
				ASTNode.UN_NOT:
					output += "Not"
				_:
					output += "Unknown: %d" % node.int_value
		ASTNode.BIN_EXPR:
			output += "BinExpr: "
			
			match node.int_value:
				ASTNode.BIN_ADD:
					output += "Add"
				ASTNode.BIN_SUB:
					output += "Sub"
				ASTNode.BIN_MUL:
					output += "Mul"
				ASTNode.BIN_EQ:
					output += "Eq"
				ASTNode.BIN_NE:
					output += "Ne"
				ASTNode.BIN_GT:
					output += "Gt"
				ASTNode.BIN_GE:
					output += "Ge"
				ASTNode.BIN_LT:
					output += "Lt"
				ASTNode.BIN_LE:
					output += "Le"
				ASTNode.BIN_AND:
					output += "And"
				ASTNode.BIN_OR:
					output += "Or"
				_:
					output += "Unknown: %d" % node.int_value
		ASTNode.BOOL_EXPR:
			output += "BoolExpr: "
			
			match node.int_value:
				ASTNode.BOOL_AND:
					output += "And"
				ASTNode.BOOL_OR:
					output += "Or"
				_:
					output += "Unknown: %d" % node.int_value
		ASTNode.ASSIGN_EXPR:
			output += "AssignExpr"
		_:
			output += "Unknown: %d" % node.type
	
	output += ")\n"
	var child_count: int = node.children.size()
	
	for i in range(child_count):
		flags.push_back(i == child_count - 1)
		output += ast_node_to_string(node.children[i], flags)
		flags.remove(depth)
	
	return output


# Converts an IR program to a string representation:
func ir_program_to_string(program: IRProgram) -> String:
	var output: String = ""
	
	if not program.metadata.empty():
		for identifier in program.metadata:
			output += "meta %s = %d;\n" % [identifier, program.metadata[identifier]]
		
		output += "\n"
	
	for i in range(program.blocks.size()):
		if i > 0:
			output += "\n"
		
		output += ir_block_to_string(program.blocks[i])
	
	return output


# Converts an IR block to a string representation:
func ir_block_to_string(block: IRBlock) -> String:
	var output: String = "%s:\n" % block.label
	
	for op in block.ops:
		output += "  %s\n" % ir_op_to_string(op)
	
	return output


# Converts an IR operation to a string representation:
func ir_op_to_string(op: IROp) -> String:
	var op_name: String = get_op_name(op.type)
	
	match op.type:
		NightScript.CLP, NightScript.RUN, NightScript.DND, NightScript.DGM, NightScript.LAK:
			return "%s %s" % [op_name, escape_string(op.string_value)]
		NightScript.APF:
			return "%s %s" % [op_name, escape_string(op.string_value)]
		NightScript.JMP, NightScript.BNZ:
			return "%s %s" % [op_name, op.key_value]
		NightScript.PHC:
			return "%s %d" % [op_name, op.int_value]
		NightScript.PHF, NightScript.STF:
			return "%s %s.%s" % [op_name, op.string_value, op.key_value]
		NightScript.MNO:
			return "%s %s %s" % [op_name, op.key_value, escape_string(op.string_value)]
		_:
			return op_name


# Signal callback for timeout on the parse timer. Runs when the parse timer
# times out. Shows the disassembly of the NightScript source code:
func _on_parse_timer_timeout() -> void:
	disassembly_edit.text = source_to_string(source_edit.text)
	disassembly_edit.show()


# Signal callback for text_changed on the source edit. Runs when the source
# edit's text is changed. Hides the disassembly edit and restarts the parse
# timer:
func _on_source_edit_text_changed() -> void:
	disassembly_edit.hide()
	parse_timer.start()
