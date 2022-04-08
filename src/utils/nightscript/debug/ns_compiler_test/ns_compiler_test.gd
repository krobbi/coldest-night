extends Control

# NightScript Compiler Test Scene
# The NightScript compiler test scene is a test scene that tests the integrity
# of the NightScript compiler by compiling and disassembling NightScript source
# code.

var _compiler: Reference = preload("res://utils/nightscript/debug/ns_compiler.gd").new()
var _program: NSProgram = NSProgram.new()

onready var _parse_timer: Timer = $ParseTimer
onready var _source_edit: TextEdit = $HBoxContainer/SourceEdit
onready var _disassembly_edit: TextEdit = $HBoxContainer/DisassemblyEdit

# Virtual _exit_tree method. Runs when the NightScript compiler test scene is
# exited. Destructs and frees the NightScript compiler test scene's NightScript
# program:
func _exit_tree() -> void:
	_program.destruct()
	_program.free()


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


# Compiles and disassembles NightScript source code:
func _disassemble_source(source: String) -> String:
	_program.deserialize_bytecode(_compiler.compile_source(source))
	var output: String = ""
	
	# Find labels:
	var labels: Dictionary = {}
	
	labels[_program.vector_main] = "op_%d" % _program.vector_main
	labels[_program.vector_repeat] = "op_%d" % _program.vector_repeat
	
	for op in _program.ops:
		if NSOp.get_operands(op.op) & NSOp.OPERAND_PTR:
			labels[op.val] = "op_%d" % op.val
	
	# Name labels:
	var label_count: int = 0
	
	for i in range(_program.ops.size()):
		if not labels.has(i):
			continue
		
		if _program.vector_main == i:
			labels[i] = "main"
		elif _program.vector_repeat == i:
			labels[i] = "repeat"
		else:
			label_count += 1
			labels[i] = "label_%d" % label_count
	
	var seen_label: bool = false
	
	for i in range(_program.ops.size()):
		if labels.has(i):
			if i > 0:
				output += "\n"
			
			if seen_label:
				output += "\n"
			
			output += "label %s\n" % labels[i]
			seen_label = true
		
		if seen_label:
			output += "\t"
		
		var op: NSOp = _program.ops[i]
		var val: int = op.val
		var lbl: String = labels.get(val, "op_%d" % val)
		var flg: String = "%s:%s" % [op.txt, op.key]
		var txt: String = _escape_string(op.txt)
		
		match op.op:
			NSOp.HLT: # Halt:
				output += "exit"
			NSOp.RUN: # Run:
				output += "run %s" % txt
			NSOp.SLP: # Sleep:
				output += "sleep %d cs" % val
			NSOp.JMP: # Jump:
				output += "goto %s" % lbl
			NSOp.BEQ: # Branch equals:
				output += "BEQ %s" % lbl
			NSOp.BNE: # Branch not equals:
				output += "BNE %s" % lbl
			NSOp.BGT: # Branch greater than:
				output += "BGT %s" % lbl
			NSOp.BGE: # Branch greater equals:
				output += "BGE %s" % lbl
			NSOp.LXC: # Load X constant:
				output += "LXC %d" % val
			NSOp.LXF: # Load X flag:
				output += "LXF %s" % flg
			NSOp.STX: # Store X:
				output += "STX %s" % flg
			NSOp.LYC: # Load Y constant:
				output += "LYC %d" % val
			NSOp.LYF: # Load Y flag:
				output += "LYF %s" % flg
			NSOp.STY: # Store Y:
				output += "STY %s" % flg
			NSOp.DGS: # Dialog show:
				output += "dialog show"
			NSOp.DGH: # Dialog hide:
				output += "dialog hide"
			NSOp.DNC: # Dialog name clear:
				output += "name"
			NSOp.DND: # Dialog name display:
				output += "name %s" % txt
			NSOp.DGM: # Dialog message:
				output += "say %s" % txt
			NSOp.MNO: # Menu option:
				output += "menu option %s goto %s" % [txt, lbl]
			NSOp.MNS: # Menu show:
				output += "menu show"
			NSOp.LAK: # Load actor key:
				output += "LAK %s" % txt
			NSOp.AFD: # Actor face direction:
				output += "AFD"
			NSOp.APF: # Actor path find:
				output += "APF %s" % txt
			NSOp.APR: # Actor path run:
				output += "APR"
			NSOp.APA: # Actor path await:
				output += "APA"
			NSOp.PLF: # Player freeze:
				output += "player freeze"
			NSOp.PLT: # Player thaw:
				output += "player unfreeze"
			NSOp.QTT: # Quit to title:
				output += "quit title"
			NSOp.PSE: # Pause:
				output += "pause"
			NSOp.UNP: # Unpause:
				output += "unpause"
			NSOp.SAV: # Save:
				output += "save"
			NSOp.CKP: # Checkpoint:
				output += "checkpoint"
		
		output += "\n"
	
	return output


# Signal callback for timeout on the parse timer. Runs when the parse timer
# times out. Shows the disassembly of the NightScript source code:
func _on_parse_timer_timeout() -> void:
	_disassembly_edit.text = _disassemble_source(_source_edit.text)
	_disassembly_edit.show()


# Signal callback for text_changed on the source edit. Runs when the source
# edit's text is changed. Hides the disassembly edit and restarts the parse
# timer:
func _on_source_edit_text_changed() -> void:
	_disassembly_edit.hide()
	_parse_timer.start()
