extends Control

# NightScript Compiler Test Scene
# The NightScript compiler test scene is a test scene that tests the integrity
# of the NightScript compiler by compiling and disassembling NightScript source
# code.

const NSMachine: GDScript = NightScript.NSMachine
const NSOp: GDScript = NightScript.NSOp

var _compiler: Reference = preload("res://utils/nightscript/compiler/ns_compiler.gd").new()

onready var _parse_timer: Timer = $ParseTimer
onready var _source_edit: TextEdit = $HBoxContainer/SourceEdit
onready var _disassembly_edit: TextEdit = $HBoxContainer/DisassemblyEdit

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


# Deserializes NightScript source code or NightScript hex bytecode to a
# NightScript machine:
func _deserialize_source(source: String) -> NSMachine:
	var bytecode: PoolByteArray = PoolByteArray()

	if source.begins_with("00 ") or source.begins_with("01 "):
		var hex: PoolStringArray = source.split(" ", false)
		var size: int = hex.size()
		bytecode.resize(size)

		for i in range(size):
			bytecode[i] = ("0x%s" % hex[i]).hex_to_int() & 0xff
	else:
		bytecode = _compiler.compile_source(source, true)
	
	return NSMachine.new(bytecode, false)


# Compiles and disassembles NightScript source code:
func _disassemble_source(source: String) -> String:
	var machine: NSMachine = _deserialize_source(source)
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
			NightScript.HLT: # Halt:
				output += "exit"
			NightScript.CLP: # Call program:
				output += "call %s" % txt
			NightScript.RUN: # Run:
				output += "run %s" % txt
			NightScript.SLP: # Sleep:
				output += "sleep %d cs" % val
			NightScript.JMP: # Jump:
				output += "goto %s" % lbl
			NightScript.BEQ: # Branch equals:
				output += "BEQ %s" % lbl
			NightScript.BNE: # Branch not equals:
				output += "BNE %s" % lbl
			NightScript.BGT: # Branch greater than:
				output += "BGT %s" % lbl
			NightScript.BGE: # Branch greater equals:
				output += "BGE %s" % lbl
			NightScript.LXC: # Load X constant:
				output += "LXC %d" % val
			NightScript.LXF: # Load X flag:
				output += "LXF %s" % flg
			NightScript.STX: # Store X:
				output += "STX %s" % flg
			NightScript.LYC: # Load Y constant:
				output += "LYC %d" % val
			NightScript.LYF: # Load Y flag:
				output += "LYF %s" % flg
			NightScript.STY: # Store Y:
				output += "STY %s" % flg
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
