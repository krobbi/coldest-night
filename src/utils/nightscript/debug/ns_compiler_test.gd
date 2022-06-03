extends Control

# NightScript Compiler Test Scene
# The NightScript compiler test scene is a test scene that tests the integrity
# of the NightScript compiler by compiling and disassembling NightScript source
# code.

const ASTNode: GDScript = preload("../compiler/v2/ast_node.gd")
const Lexer: GDScript = preload("../compiler/v2/lexer.gd")
const NSMachine: GDScript = NightScript.NSMachine
const NSOp: GDScript = NightScript.NSOp
const Parser: GDScript = preload("../compiler/v2/parser.gd")
const Token: GDScript = preload("../compiler/v2/token.gd")

var _compiler: Reference = preload("res://utils/nightscript/compiler/ns_compiler.gd").new()

onready var _parse_timer: Timer = $ParseTimer
onready var _source_edit: TextEdit = $HBoxContainer/SourceEdit
onready var _disassembly_edit: TextEdit = $HBoxContainer/DisassemblyEdit

# Virtual _ready method. Runs when the NightScript compiler test scene is
# entered. Sets the window's scale:
func _ready() -> void:
	Global.display.set_window_scale(0)


# Converts NightScript source code to a sequence of tokens:
func _source_to_tokens(source: String) -> Array:
	var lexer: Lexer = Lexer.new()
	return lexer.get_tokens(source)


# Compiles NightScript source code or deserializes NightScript hex bytecode to a
# NightScript machine:
func _source_to_machine(source: String) -> NSMachine:
	var bytecode: PoolByteArray = PoolByteArray()
	
	if source.begins_with("0"):
		var hex: PoolStringArray = source.split(" ", false)
		var size: int = hex.size()
		bytecode.resize(size)
		
		for i in range(size):
			bytecode[i] = ("0x%s" % hex[i]).hex_to_int() & 0xff
	else:
		bytecode = _compiler.compile_source(source, true)
	
	return NSMachine.new(bytecode, false)


# Compiles NightScript source code and returns a log for each phase of
# compilation:
func _source_to_log(source: String) -> String:
	var output: String = "# Token Stream:\n"
	var tokens: Array = _source_to_tokens(source)
	
	for token in tokens:
		output += "%s\n" % _token_to_string(token)
	
	output += "\n\n# Abstract Syntax Tree:\n%s" % _ast_node_to_string(_tokens_to_ast(tokens))
	
	return output


# Converts a token to a string representation:
func _token_to_string(token: Token) -> String:
	match token.type:
		Token.END_OF_FILE:
			return "[End of file]"
		Token.ERROR:
			return "[Error: %s]" % token.string_value
		Token.IDENTIFIER:
			return "[Identifier: %s]" % token.string_value
		Token.LITERAL_INT:
			return "[Literal int: %d]" % token.int_value
		Token.LITERAL_STRING:
			return "[Literal string: %s)" % _escape_string(token.string_value)
		Token.KEYWORD_AND:
			return "[and]"
		Token.KEYWORD_FALSE:
			return "[false]"
		Token.KEYWORD_NOT:
			return "[not]"
		Token.KEYWORD_OR:
			return "[or]"
		Token.KEYWORD_TRUE:
			return "[true]"
		Token.COLON:
			return "[:]"
		Token.PLUS:
			return "[+]"
		Token.MINUS:
			return "[-]"
		Token.STAR:
			return "[*]"
		Token.EQUALS_EQUALS:
			return "[==]"
		Token.BANG_EQUALS:
			return "[!=]"
		Token.GREATER:
			return "[>]"
		Token.GREATER_EQUALS:
			return "[>=]"
		Token.LESS:
			return "[<]"
		Token.LESS_EQUALS:
			return "[<=]"
		Token.OPEN_PARENTHESIS:
			return "[(]"
		Token.CLOSE_PARENTHESIS:
			return "[)]"
		_:
			return "[Unknown token]"


# Converts a sequence of tokens to an abstract syntax tree:
func _tokens_to_ast(tokens: Array) -> ASTNode:
	var parser: Parser = Parser.new()
	return parser.get_ast(tokens)


# Recursively converts an AST node and its children to a string representation:
func _ast_node_to_string(node: ASTNode, flags: Array = []) -> String:
	var output = ""
	var depth: int = flags.size()
	
	for i in range(depth):
		var flag: bool = flags[i]
		
		if i == depth - 1:
			output += "|-" if flag else "|_"
		else:
			output += "| " if flag else "  "
	
	output += "("
	
	match node.type:
		ASTNode.BLOCK:
			output += "Block"
		ASTNode.COMMAND:
			output += "Command: "
			
			match node.int_value:
				ASTNode.CMD_EXIT:
					output += "exit"
				ASTNode.CMD_DIALOG_SHOW:
					output += "dialog show"
				ASTNode.CMD_DIALOG_HIDE:
					output += "dialog hide"
				ASTNode.CMD_SAY:
					output += "say"
				ASTNode.CMD_PLAYER_FREEZE:
					output += "player freeze"
				ASTNode.CMD_PLAYER_UNFREEZE:
					output += "player unfreeze"
				_:
					output += "Unknown command"
		ASTNode.IDENTIFIER:
			output += "Identifier: %s" % node.string_value
		ASTNode.FLAG:
			output += "Flag: %s:%s" % [node.string_value, node.key_value]
		ASTNode.INT:
			output += "Int: %d" % node.int_value
		ASTNode.STRING:
			output += "String: %s" % _escape_string(node.string_value)
		ASTNode.UNARY_OPERATION:
			output += "Unary operation: "
			
			match node.int_value:
				ASTNode.UN_NEG:
					output += "-"
				ASTNode.UN_NOT:
					output += "not"
				_:
					output += "Unknown unary operator"
		ASTNode.BINARY_OPERATION:
			output += "Binary operation: "
			
			match node.int_value:
				ASTNode.BIN_ADD:
					output += "+"
				ASTNode.BIN_SUB:
					output += "-"
				ASTNode.BIN_MUL:
					output += "*"
				ASTNode.BIN_EQ:
					output += "=="
				ASTNode.BIN_NE:
					output += "!="
				ASTNode.BIN_GT:
					output += ">"
				ASTNode.BIN_GE:
					output += ">="
				ASTNode.BIN_LT:
					output += "<"
				ASTNode.BIN_LE:
					output += "<="
				ASTNode.BIN_AND:
					output += "and"
				ASTNode.BIN_OR:
					output += "or"
				_:
					output += "Unknown binary operator"
		_:
			output += "Unknown AST node"
	
	output += ")\n"
	
	var child_count: int = node.children.size()
	
	for i in range(child_count):
		flags.push_back(i != child_count - 1)
		output += _ast_node_to_string(node.children[i], flags)
		flags.remove(depth)
	
	return output


# Converts a NightScript machine to an assembly-level string:
func _machine_to_string(machine: NSMachine) -> String:
	var output: String = "meta cache %s\nmeta pause %s\n\n" % [
		"true" if machine.is_cacheable else "false", "true" if machine.is_pausable else "false"
	]
	
	# Find labels:
	var labels: Dictionary = {}
	
	labels[machine.vector_main] = "op_%d" % machine.vector_main
	labels[machine.vector_repeat] = "op_%d" % machine.vector_repeat
	
	for op in machine.ops:
		if NSMachine.get_operands(op.op) & NightScript.OPERAND_PTR:
			labels[op.val] = "op_%d" % op.val
	
	# Name labels:
	var label_count: int = 0
	
	for i in range(machine.ops.size()):
		if not labels.has(i):
			continue
		
		if machine.vector_main == i:
			labels[i] = "main"
		elif machine.vector_repeat == i:
			labels[i] = "repeat"
		else:
			label_count += 1
			labels[i] = "label_%d" % label_count
	
	var seen_label: bool = false
	
	for i in range(machine.ops.size()):
		if labels.has(i):
			if i > 0:
				output += "\n"
			
			if seen_label:
				output += "\n"
			
			output += "label %s\n" % labels[i]
			seen_label = true
		
		if seen_label:
			output += "\t"
		
		var op: NSOp = machine.ops[i]
		var val: int = op.val
		var lbl: String = labels.get(val, "op_%d" % val)
		var flg: String = "%s:%s" % [op.txt, op.key]
		var txt: String = _escape_string(op.txt)
		
		match op.op:
			# Control flow:
			NightScript.HLT: # Halt:
				output += "exit"
			NightScript.CLP: # Call program:
				output += "call %s" % txt
			NightScript.RUN: # Run:
				output += "run %s" % txt
			NightScript.SLP: # Sleep:
				output += "SLP"
			NightScript.JMP: # Jump:
				output += "goto %s" % lbl
			NightScript.BNZ: # Branch not zero:
				output += "BNZ %s" % lbl
			
			# Stack operations:
			NightScript.PHC:
				output += "PHC %d" % val
			NightScript.PHF:
				output += "PHF %s" % flg
			NightScript.STF:
				output += "STF %s" % flg
			NightScript.NEG:
				output += "NEG"
			NightScript.ADD:
				output += "ADD"
			NightScript.SUB:
				output += "SUB"
			NightScript.MUL:
				output += "MUL"
			NightScript.CEQ:
				output += "CEQ"
			NightScript.CNE:
				output += "CNE"
			NightScript.CGT:
				output += "CGT"
			NightScript.CGE:
				output += "CGE"
			NightScript.CLT:
				output += "CLT"
			NightScript.CLE:
				output += "CLE"
			NightScript.NOT:
				output += "NOT"
			NightScript.AND:
				output += "AND"
			NightScript.LOR:
				output += "LOR"
			
			# Dialog operations:
			NightScript.DGS: # Dialog show:
				output += "dialog show"
			NightScript.DGH: # Dialog hide:
				output += "dialog hide"
			NightScript.DNC: # Dialog name clear:
				output += "name"
			NightScript.DND: # Dialog name display:
				output += "name %s" % txt
			NightScript.DGM: # Dialog message:
				output += "say %s" % txt
			NightScript.MNO: # Menu option:
				output += "MNO %s %s" % [lbl, txt]
			NightScript.MNS: # Menu show:
				output += "MNS"
			
			# Actor operations:
			NightScript.LAK: # Load actor key:
				output += "LAK %s" % txt
			NightScript.AFD: # Actor face direction:
				output += "AFD"
			NightScript.APF: # Actor path find:
				output += "APF %s" % txt
			NightScript.APR: # Actor path run:
				output += "APR"
			NightScript.APA: # Actor path await:
				output += "APA"
			NightScript.PLF: # Player freeze:
				output += "player freeze"
			NightScript.PLT: # Player thaw:
				output += "player unfreeze"
			NightScript.QTT: # Quit to title:
				output += "quit title"
			NightScript.PSE: # Pause:
				output += "pause"
			NightScript.UNP: # Unpause:
				output += "unpause"
			NightScript.SAV: # Save:
				output += "save"
			NightScript.CKP: # Checkpoint:
				output += "checkpoint"
		
		output += "\n"
	
	machine.destruct()
	machine.free()
	return output


# Escapes a string to a NightScript source code string:
func _escape_string(string: String) -> String:
	var string_type: String = '"' if string.count("'") >= string.count('"') else "'"
	var output: String = string_type
	
	for character in string:
		match character:
			"\t":
				output += "\\t"
			"\n":
				output += "\\n"
			"\\", string_type:
				output += "\\%s" % character
			_:
				output += character
	
	output += string_type
	return output


# Signal callback for timeout on the parse timer. Runs when the parse timer
# times out. Shows the disassembly of the NightScript source code:
func _on_parse_timer_timeout() -> void:
	_disassembly_edit.text = _source_to_log(_source_edit.text)
	_disassembly_edit.show()


# Signal callback for text_changed on the source edit. Runs when the source
# edit's text is changed. Hides the disassembly edit and restarts the parse
# timer:
func _on_source_edit_text_changed() -> void:
	_disassembly_edit.hide()
	_parse_timer.start()
