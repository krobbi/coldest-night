extends Reference

# NightScript Compiler
# A NightScript compiler is a NightScript utility that compiles NightScript
# source code from NightScript bytecode.

class ParseFlag extends Reference:
	
	# Parse Flag
	# A parse flag is a helper structure used by a NightScript compiler that
	# represents a flag in NightScript source code.
	
	var namespace: String
	var key: String
	
	# Constructor. Sets the parse flag's namespace and key:
	func _init(namespace_val: String, key_val: String) -> void:
		namespace = namespace_val
		key = key_val


class ParseValue extends Reference:
	
	# Parse Value
	# A parse value is a helper structure used by a NightScript compiler that
	# represents a value in NightScript source code.
	
	enum Type {ERROR, CONST, FLAG}
	
	var type: int
	var value: int
	var flag: ParseFlag = null
	
	# Constructor. Sets the parse value's type and value:
	func _init(type_val: int, value_val: int, namespace: String, key: String) -> void:
		type = type_val
		value = value_val
		
		if type == Type.FLAG:
			flag = ParseFlag.new(namespace, key)
	
	
	# Gets whether the parse value is an error parse value:
	func is_error() -> bool:
		return type == Type.ERROR
	
	
	# Gets whether the parse value is a constant parse value:
	func is_const() -> bool:
		return type == Type.CONST
	
	
	# Gets whether the parse value is a flag parse value:
	func is_flag() -> bool:
		return type == Type.FLAG
	
	
	# Creates a new error parse value:
	static func create_error() -> ParseValue:
		return ParseValue.new(Type.ERROR, 0, "", "")
	
	
	# Creates a new constant parse value:
	static func create_const(value_val: int) -> ParseValue:
		return ParseValue.new(Type.CONST, value_val, "", "")
	
	
	# Creates a new flag parse value:
	static func create_flag(namespace: String, key: String) -> ParseValue:
		return ParseValue.new(Type.FLAG, 0, namespace, key)


class IRNode extends Reference:
	
	# IR Node
	# An IR node is a helper structure used by a NightScript compiler that is an
	# intermediate representation of a NightScript operation.
	
	var op: int
	var val: int
	var lbl: String
	var flg: ParseFlag
	var txt: String
	
	# Constructor. Sets the IR node's opcode:
	func _init(op_val: int) -> void:
		op = op_val


class IntTrace extends Reference:
	
	# Int Trace
	# An int trace is a helper structure used by a NightScript compiler that
	# traces the state of an int register. It is used to optimize out
	# unnecessary writes to int registers:
	
	var is_traced: bool = false
	var value: int = 0
	
	# Traces that the int register has a known value:
	func trace(value_val: int) -> void:
		value = value_val
		is_traced = true
	
	
	# Traces that the int register has an unknown value:
	func untrace() -> void:
		is_traced = false


class StringTrace extends Reference:
	
	# String Trace
	# A string trace is a helper structure used by a NightScript compiler that
	# traces the state of a string register. It is used to optimize out
	# unnecessary writes to string registers.
	
	var is_traced: bool = false
	var value: String = ""
	
	# Traces that the string register has a known value:
	func trace(value_val: String) -> void:
		value = value_val
		is_traced = true
	
	
	# Traces that the string register has an unknown value:
	func untrace() -> void:
		is_traced = false


class IRBlock extends Reference:
	
	# IR Block
	# An IR block is a helper structure used by a NightScript compiler that is
	# an intermediate representation of a jump target and its subsequent
	# NightScript operations.
	
	var label: String
	var is_dead: bool = false
	var nodes: Array = []
	var x_trace: IntTrace = IntTrace.new()
	var y_trace: IntTrace = IntTrace.new()
	var dialog_name_trace: StringTrace = StringTrace.new()
	var actor_key_trace: StringTrace = StringTrace.new()
	
	# Constructor. Sets the IR block's label:
	func _init(label_val: String) -> void:
		label = label_val
	
	
	# Marks the IR block as dead. An IR block becomes dead if any subsequent IR
	# nodes in the IR block will never be reachable due to a logical
	# impossibility:
	func kill() -> void:
		is_dead = true
	
	
	# Loads the X register with a parse value:
	func load_x(value: ParseValue) -> void:
		if value.is_const():
			make_lxc(value.value)
		elif value.is_flag():
			make_lxf(value.flag)
	
	
	# Loads the Y register with a parse value:
	func load_y(value: ParseValue) -> void:
		if value.is_const():
			make_lyc(value.value)
		elif value.is_flag():
			make_lyf(value.flag)
	
	
	# Makes an IR node at the back of the IR block if the IR block is not dead:
	func make_node(node: IRNode) -> void:
		if not is_dead:
			nodes.push_back(node)
	
	
	# Makes an IR node with a standalone operation at the back of the IR block:
	func make_standalone(op: int) -> void:
		make_node(IRNode.new(op))
	
	
	# Makes an IR node with a value operation at the back of the IR block:
	func make_value(op: int, val: int) -> void:
		var node: IRNode = IRNode.new(op)
		node.val = val
		make_node(node)
	
	
	# Makes an IR node with a pointer operaton at the back of the IR block:
	func make_pointer(op: int, lbl: String) -> void:
		var node: IRNode = IRNode.new(op)
		node.lbl = lbl
		make_node(node)
	
	
	# Makes an IR node with a flag operation at the back of the IR block:
	func make_flag(op: int, flg: ParseFlag) -> void:
		var node: IRNode = IRNode.new(op)
		node.flg = flg
		make_node(node)
	
	
	# Makes an IR node with a text operation at the back of the IR block:
	func make_text(op: int, txt: String) -> void:
		var node: IRNode = IRNode.new(op)
		node.txt = txt
		make_node(node)
	
	
	# Makes an IR node with a pointer and text operation at the back of the IR
	# block:
	func make_pointer_text(op: int, lbl: String, txt: String) -> void:
		var node: IRNode = IRNode.new(op)
		node.lbl = lbl
		node.txt = txt
		make_node(node)
	
	
	# Makes an HLT IR node at the back of the IR block:
	func make_hlt() -> void:
		make_standalone(NSOp.HLT)
		kill()
	
	
	# Makes an RUN IR node at the back of the IR block:
	func make_run(txt: String) -> void:
		make_text(NSOp.RUN, txt)
	
	
	# Makes an SLP IR node at the back of the IR block:
	func make_slp(val: int) -> void:
		make_value(NSOp.SLP, val)
	
	
	# Makes a JMP IR node at the back of the IR block:
	func make_jmp(lbl: String) -> void:
		make_pointer(NSOp.JMP, lbl)
		kill()
	
	
	# Makes a BEQ IR node at the back of the IR block:
	func make_beq(lbl: String) -> void:
		if x_trace.is_traced and y_trace.is_traced:
			if x_trace.value == y_trace.value:
				make_jmp(lbl)
			
			return
		
		make_pointer(NSOp.BEQ, lbl)
	
	
	# Makes a BNE IR node at the back of the IR block:
	func make_bne(lbl: String) -> void:
		if x_trace.is_traced and y_trace.is_traced:
			if x_trace.value != y_trace.value:
				make_jmp(lbl)
			
			return
		
		make_pointer(NSOp.BNE, lbl)
	
	
	# Makes a BGT IR node at the back of the IR block:
	func make_bgt(lbl: String) -> void:
		if x_trace.is_traced and y_trace.is_traced:
			if x_trace.value > y_trace.value:
				make_jmp(lbl)
			
			return
		
		make_pointer(NSOp.BGT, lbl)
	
	
	# Makes a BGE IR node at the back of the IR block:
	func make_bge(lbl: String) -> void:
		if x_trace.is_traced and y_trace.is_traced:
			if x_trace.value >= y_trace.value:
				make_jmp(lbl)
			
			return
		
		make_pointer(NSOp.BGE, lbl)
	
	
	# Makes an LXC IR node at the back of the IR block:
	func make_lxc(val: int) -> void:
		if x_trace.is_traced and x_trace.value == val:
			return
		
		make_value(NSOp.LXC, val)
		x_trace.trace(val)
	
	
	# Makes an LXF IR node at the back of the IR block:
	func make_lxf(flg: ParseFlag) -> void:
		make_flag(NSOp.LXF, flg)
		x_trace.untrace()
	
	
	# Makes an STX IR node at the back of the IR block:
	func make_stx(flg: ParseFlag) -> void:
		make_flag(NSOp.STX, flg)
	
	
	# Makes an LYC IR node at the back of the IR block:
	func make_lyc(val: int) -> void:
		if y_trace.is_traced and y_trace.value == val:
			return
		
		make_value(NSOp.LYC, val)
		y_trace.trace(val)
	
	
	# Makes an LYF IR node at the back of the IR block:
	func make_lyf(flg: ParseFlag) -> void:
		make_flag(NSOp.LYF, flg)
		y_trace.untrace()
	
	
	# Makes an STY IR node at the back of the IR block:
	func make_sty(flg: ParseFlag) -> void:
		make_flag(NSOp.STY, flg)
	
	
	# Makes a DGS IR node at the back of the IR block:
	func make_dgs() -> void:
		make_standalone(NSOp.DGS)
	
	
	# Makes a DGH IR node at the back of the IR block:
	func make_dgh() -> void:
		make_standalone(NSOp.DGH)
	
	
	# Makes a DNC IR node at the back of the IR block:
	func make_dnc() -> void:
		make_standalone(NSOp.DNC)
		dialog_name_trace.untrace()
	
	
	# Makes a DND IR node at the back of the IR block:
	func make_dnd(txt: String) -> void:
		if dialog_name_trace.is_traced and dialog_name_trace.value == txt:
			return
		
		make_text(NSOp.DND, txt)
		dialog_name_trace.trace(txt)
	
	
	# Makes a DGM IR node at the back of the IR block:
	func make_dgm(txt: String) -> void:
		make_text(NSOp.DGM, txt)
	
	
	# Makes an MNO IR node at the back of the IR block:
	func make_mno(lbl: String, txt: String) -> void:
		make_pointer_text(NSOp.MNO, lbl, txt)
	
	
	# Makes an MNS IR node at the back of the IR block:
	func make_mns() -> void:
		make_standalone(NSOp.MNS)
		kill()
	
	
	# Makes an LAK IR node at the back of the IR block:
	func make_lak(txt: String) -> void:
		if actor_key_trace.is_traced and actor_key_trace.value == txt:
			return
		
		make_text(NSOp.LAK, txt)
		actor_key_trace.trace(txt)
	
	
	# Makes an AFD IR node at the back of the IR block:
	func make_afd() -> void:
		make_standalone(NSOp.AFD)
	
	
	# Makes an APF IR node at the back of the IR blocK:
	func make_apf(txt: String) -> void:
		make_text(NSOp.APF, txt)
	
	
	# Makes an APR IR node at the back of the IR block:
	func make_apr() -> void:
		make_standalone(NSOp.APR)
	
	
	# Makes an APA IR node at the back of the IR block:
	func make_apa() -> void:
		make_standalone(NSOp.APA)
	
	
	# Makes a PLF IR node at the back of the IR block:
	func make_plf() -> void:
		make_standalone(NSOp.PLF)
	
	
	# Makes a PLT IR node at the back of the IR block:
	func make_plt() -> void:
		make_standalone(NSOp.PLT)
	
	
	# Makes a QTT IR node at the back of the IR block:
	func make_qtt() -> void:
		make_standalone(NSOp.QTT)
		kill()
	
	
	# Makes a PSE IR node at the back of the IR block:
	func make_pse() -> void:
		make_standalone(NSOp.PSE)
	
	
	# Makes a UNP IR node at the back of the IR block:
	func make_unp() -> void:
		make_standalone(NSOp.UNP)
	
	
	# Makes an SAV IR node at the back of the IR block:
	func make_sav() -> void:
		make_standalone(NSOp.SAV)
	
	
	# Makes a CKP IR node at the back of the IR blocK:
	func make_ckp() -> void:
		make_standalone(NSOp.CKP)


class TableFlag extends Reference:
	
	# Table Flag
	# A table flag is a helper structure used by a NightScript compiler that
	# represents a flag entry in a NightScript bytecode table.
	
	var namespace: int
	var key: int
	
	# Constructor. Sets the table flag's namespace and key:
	func _init(namespace_val: int, key_val: int) -> void:
		namespace = namespace_val
		key = key_val
	
	
	# Returns whether the table flag equals another table flag by value:
	func equals(other: TableFlag) -> bool:
		return namespace == other.namespace and key == other.key


class BytecodeTable extends Reference:
	
	# Bytecode Table
	# A bytecode table is a helper structure used by a NightScript compiler that
	# is used for generating the table section of NightScript bytecode:
	
	var strings: PoolStringArray = PoolStringArray()
	var flags: Array = []
	
	# Gets the ID of a string from the bytecode table. Registers the string to
	# the bytecode table if it does not exist:
	func get_string_id(string: String) -> int:
		var size: int = strings.size()
		
		for i in range(size):
			if strings[i] == string:
				return i
		
		strings.push_back(string)
		return size
	
	
	# Gets the ID of a flag from the bytecode table. Registers the flag to the
	# bytecode table if it does not exist:
	func get_flag_id(flag: ParseFlag) -> int:
		var table_flag: TableFlag = create_flag(flag)
		var size: int = flags.size()
		
		for i in range(size):
			if flags[i].equals(table_flag):
				return i
		
		flags.push_back(table_flag)
		return size
	
	
	# Creates a table flag from a parse flag and the bytecode table's strings:
	func create_flag(flag: ParseFlag) -> TableFlag:
		return TableFlag.new(get_string_id(flag.namespace), get_string_id(flag.key))


enum CommandScanState {NORMAL, STRING, ESCAPE}
enum Comparator {ERROR, EQ, NE, GT, GE, LT, LE}

const DEFAULT_CONSTS: Dictionary = {"false": 0, "true": 1}
const DEFAULT_METADATA: Dictionary = {"cache": 1}

var _metadata: Dictionary = {}
var _scope_stack: Array = [{}]
var _blocks: Array = []
var _current_block: IRBlock = null

# Compiles a NightScript source file to NightScript bytecode from its path:
func compile_path(path: String) -> PoolByteArray:
	_reset()
	var file: File = File.new()
	
	if file.file_exists(path):
		var error: int = file.open(path, File.READ)
		
		if error:
			if file.is_open():
				file.close()
			
			_err("Failed to read from NightScript source file '%s'! Error: %s (%d)" % [
				path, Global.logger.get_err_name(error), error
			])
		else:
			var source: String = file.get_as_text()
			file.close()
			_parse_source(source)
	else:
		_err("NightScript source file '%s' does not exist!" % path)
	
	_finalize()
	_optimize()
	return _generate_bytecode()


# Compiles NightScript source code to NightScript bytecode:
func compile_source(source: String) -> PoolByteArray:
	_reset()
	_parse_source(source)
	_finalize()
	_optimize()
	return _generate_bytecode()


# Gets a metadata value from its key:
func _get_metadata(key: String) -> int:
	if _metadata.has(key):
		return _metadata[key]
	else:
		return DEFAULT_METADATA.get(key, 0)


# Returns whether an IR block exists from its label:
func _has_block(label: String) -> bool:
	for block in _blocks:
		if block.label == label:
			return true
	
	return false


# Pushes a new current scope to the scope stack:
func _push_scope() -> void:
	_scope_stack.push_back({})


# Pops the current scope from the scope stack if it is not the global scope:
func _pop_scope() -> void:
	if _scope_stack.size() > 1:
		_scope_stack.remove(_scope_stack.size() - 1)


# Evaluates a comparison between two constant values:
func _eval_comparison(left: int, comparator: int, right: int) -> bool:
	match comparator:
		Comparator.EQ:
			return left == right
		Comparator.NE:
			return left != right
		Comparator.GT:
			return left > right
		Comparator.GE:
			return left >= right
		Comparator.LT:
			return left < right
		Comparator.LE:
			return left <= right
		Comparator.ERROR, _:
			return false


# Creates a new error parse value and logs an error message:
func _create_error(message: String) -> ParseValue:
	_err(message)
	return ParseValue.create_error()


# Creates a new IR block after the current IR block from its label:
func _create_block(label: String) -> IRBlock:
	var index: int = _blocks.size()
	
	for i in range(index):
		if _blocks[i] == _current_block:
			index = i + 1
			break
	
	var block: IRBlock = IRBlock.new(label)
	_blocks.insert(index, block)
	return block


# Scans an array of commands and arguments from a line of NightScript source
# code:
func _scan_commands(line: String) -> Array:
	var state: int = CommandScanState.NORMAL
	var string_type: String = '"'
	var commands: Array = []
	var args: PoolStringArray = PoolStringArray()
	var arg: String = ""
	
	for character in line:
		match state:
			CommandScanState.NORMAL:
				match character:
					'"', "'": # Start of string:
						if not arg.empty():
							args.push_back(arg)
							arg = ""
						
						string_type = character
						state = CommandScanState.STRING
					"#": # Comment:
						if not arg.empty():
							args.push_back(arg)
						
						if not args.empty():
							commands.push_back(args)
						
						return commands
					",": # Delimiter
						args.push_back(arg)
						arg = ""
					";": # End of command:
						if not arg.empty():
							args.push_back(arg)
							arg = ""
						
						if not args.empty():
							commands.push_back(args)
							args.resize(0)
					_:
						if ord(character) <= 32: # Whitespace:
							if not arg.empty():
								args.push_back(arg)
								arg = ""
						else: # Other:
							arg += character
			CommandScanState.STRING:
				match character:
					"\\": # Start of escape sequence:
						state = CommandScanState.ESCAPE
					string_type: # End of string:
						args.push_back(arg)
						arg = ""
						state = CommandScanState.NORMAL
					_: # Other:
						arg += character
			CommandScanState.ESCAPE:
				match character:
					"a", "b", "f", "r", "v": # Ignored:
						pass
					"n": # Line break:
						arg += "\n"
					"t": # Tab:
						arg += "\t"
					_: # Other:
						arg += character
				
				state = CommandScanState.STRING
	
	match state:
		CommandScanState.STRING, CommandScanState.ESCAPE:
			_err("String argument was not closed!")
		CommandScanState.NORMAL:
			if not arg.empty():
				args.push_back(arg)
			
			if not args.empty():
				commands.push_back(args)
	
	return commands


# Scans a parse value from its symbol:
func _scan_value(symbol: String) -> ParseValue:
	if symbol.empty():
		return _create_error("Value is empty!")
	elif DEFAULT_CONSTS.has(symbol):
		return ParseValue.create_const(DEFAULT_CONSTS[symbol])
	elif symbol.is_valid_identifier():
		for i in range(_scope_stack.size() - 1, -1, -1):
			var scope: Dictionary = _scope_stack[i]
			
			if scope.has(symbol):
				return scope[symbol]
		
		return _create_error("Value '%s' is undefined in the current scope!" % symbol)
	elif symbol.is_valid_integer():
		return ParseValue.create_const(int(symbol))
	elif symbol.count(":") == 1:
		var flag_parts: PoolStringArray = symbol.split(":", true, 1)
		var namespace: String = flag_parts[0]
		var key: String = flag_parts[1]
		
		if namespace.empty():
			return _create_error("Flag '%s' has an empty namespace!" % symbol)
		elif not namespace.is_valid_identifier():
			return _create_error("Flag '%s' has an invalid namespace!" % symbol)
		elif key.empty():
			return _create_error("Flag '%s' has an empty key!" % symbol)
		elif not key.is_valid_identifier():
			return _create_error("Flag '%s' has an invalid key!" % symbol)
		else:
			return ParseValue.create_flag(namespace, key)
	else:
		return _create_error("Value '%s' is invalid!" % symbol)


# Scans a comparator from its symbol:
func _scan_comparator(symbol: String) -> int:
	match symbol:
		"==":
			return Comparator.EQ
		"!=":
			return Comparator.NE
		">":
			return Comparator.GT
		">=":
			return Comparator.GE
		"<":
			return Comparator.LT
		"<=":
			return Comparator.LE
		_:
			if symbol.empty():
				_err("Comparator is empty!")
			else:
				_err("Comparator '%s' is invalid!" % symbol)
			
			return Comparator.ERROR


# Logs an error message:
func _err(message: String) -> void:
	Global.logger.err(message)


# Resets the NightScript compiler's IR code:
func _reset() -> void:
	_metadata.clear()
	_scope_stack = [{}]
	_blocks.clear()
	_current_block = _create_block("$$main")


# Parses NightScript source code to IR code:
func _parse_source(source: String) -> void:
	for line in source.split("\n"):
		_parse_line(line)


# Parses a line of NightScript source code to IR code:
func _parse_line(line: String) -> void:
	line = line.strip_edges()
	
	if line.empty() or line.begins_with("#"):
		return
	
	for args in _scan_commands(line):
		if args.empty():
			continue
		
		var command: String = args[0]
		args.remove(0)
		_parse_command(command, args)


# Parses a command from NightScript source code to IR code:
func _parse_command(command: String, args: PoolStringArray) -> void:
	match command:
		"meta":
			if args.size() == 2:
				_parse_meta(args[0], _scan_value(args[1]))
			else:
				_err("Command 'meta' expects 2 arguments!")
		"define":
			if args.size() == 2:
				_parse_define(args[0], _scan_value(args[1]))
			else:
				_err("Command 'define' expects 2 arguments!")
		"label":
			if args.size() == 1:
				_parse_label(args[0])
			else:
				_err("Command 'label' expects 1 argument!")
		"exit":
			if args.size() == 0:
				_current_block.make_hlt()
			else:
				_err("Command 'exit' expects no arguments!")
		"run":
			if args.size() == 1:
				_current_block.make_run(args[0])
			else:
				_err("Command 'run' expects 1 argument!")
		"sleep":
			match args.size():
				1:
					_parse_sleep(_scan_value(args[0]), "s")
				2:
					_parse_sleep(_scan_value(args[0]), args[1])
				_:
					_err("Command 'sleep' expects 1 or 2 arguments!")
		"goto":
			match args.size():
				1:
					_parse_goto(
							args[0], ParseValue.create_const(1), Comparator.NE,
							ParseValue.create_const(0)
					)
				2:
					_parse_goto(
							args[0], _scan_value(args[1]), Comparator.NE, ParseValue.create_const(0)
					)
				4:
					_parse_goto(
							args[0], _scan_value(args[1]),
							_scan_comparator(args[2]), _scan_value(args[3])
					)
				_:
					_err("Command 'goto' expects 1, 2, or 4 arguments!")
		"set":
			if args.size() == 2:
				_parse_set(_scan_value(args[0]), _scan_value(args[1]))
			else:
				_err("Command 'set' expects 2 arguments!")
		"dialog":
			if args.size() == 1:
				_parse_dialog(args[0])
			else:
				_err("Command 'dialog' expects 1 argument!")
		"name":
			match args.size():
				0:
					_parse_name("")
				1:
					_parse_name(args[0])
				_:
					_err("Command 'name' expects 0 or 1 arguments!")
		"say":
			if args.size() == 1:
				_current_block.make_dgm(args[0])
			else:
				_err("Command 'say' expects 1 argument!")
		"menu":
			match args.size():
				1, 4:
					_parse_menu(args)
				_:
					_err("Command 'menu' expects 1 or 4 arguments!")
		"look":
			if args.size() == 2:
				_parse_look(args[0], args[1])
			else:
				_err("Command 'look' expects 2 arguments!")
		"path":
			if args.size() == 3:
				_parse_path(args)
			else:
				_err("Command 'path' expects 3 arguments!")
		"player":
			if args.size() == 1:
				_parse_player(args[0])
			else:
				_err("Command 'player' expects 1 argument!")
		"quit":
			if args.size() == 1:
				_parse_quit(args[0])
			else:
				_err("Command 'quit' expects 1 argument!")
		"pause":
			if args.size() == 0:
				_current_block.make_pse()
			else:
				_err("Command 'pause' expects no arguments!")
		"unpause":
			if args.size() == 0:
				_current_block.make_unp()
			else:
				_err("Command 'unpause' expects no arguments!")
		"save":
			if args.size() == 0:
				_current_block.make_sav()
			else:
				_err("Command 'save' expects no arguments!")
		"checkpoint":
			if args.size() == 0:
				_current_block.make_ckp()
			else:
				_err("Command 'checkpoint' expects no arguments!")
		_:
			if command.empty():
				_err("Command is empty!")
			else:
				_err("Command '%s' is invalid!" % command)


# Parses a meta command from NightScript source code to IR code:
func _parse_meta(key: String, value: ParseValue) -> void:
	if key.empty():
		_err("Metadata key is empty!")
	elif not key.is_valid_identifier():
		_err("Metadata key '%s' is invalid!" % key)
	elif _metadata.has(key):
		_err("Metadata key '%s' is already defined!" % key)
	elif not value.is_const():
		_err("Command 'meta' expects a constant value!")
	else:
		_metadata[key] = value.value


# Parses a define command from NightScirpt source code to IR code:
func _parse_define(identifier: String, value: ParseValue):
	if identifier.empty():
		_err("Identifier is empty!")
	elif not identifier.is_valid_identifier():
		_err("Identifier '%s' is invalid!" % identifier)
	elif DEFAULT_CONSTS.has(identifier):
		_err("Value '%s' cannot be redefined!" % identifier)
	elif _scope_stack[-1].has(identifier):
		_err("Value '%s' is already defined in the current scope!" % identifier)
	elif value.is_error():
		return
	else:
		_scope_stack[-1][identifier] = value


# Parses a label command from NightScript source code to IR code:
func _parse_label(label: String) -> void:
	if label.empty():
		_err("Label is empty!")
	elif not label.is_valid_identifier():
		_err("Label '%s' is invalid!" % label)
	elif _has_block(label):
		_err("Label '%s' is already defined!" % label)
	else:
		_pop_scope()
		_current_block = _create_block(label)
		_push_scope()


# Parses a sleep command from NightScript source code to IR code:
func _parse_sleep(duration: ParseValue, unit: String) -> void:
	if not duration.is_const():
		_err("Command 'sleep' expects a constant duration!")
		return
	
	var multiplier: float
	
	match unit:
		"ms": # Milliseconds:
			multiplier = 0.1
		"cs": # Centiseconds:
			multiplier = 1.0
		"ds": # Deciseconds:
			multiplier = 10.0
		"s": # Seconds:
			multiplier = 100.0
		"m": # Minutes:
			multiplier = 6000.0
		_:
			_err("Command 'sleep' expects 'ms', 'cs', 'ds', 's', or 'm' time units!")
			return
	
	_current_block.make_slp(int(clamp(round(float(duration.value) * multiplier), 1.0, 30000.0)))


# Parses a goto command from NightScript source code to IR code:
func _parse_goto(label: String, left: ParseValue, comparator: int, right: ParseValue) -> void:
	if label.empty():
		_err("Label is empty!")
		return
	elif not label.is_valid_identifier():
		_err("Label '%s' is invalid!" % label)
		return
	elif left.is_error():
		_err("Left-hand value is invalid!")
		return
	elif comparator == Comparator.ERROR:
		_err("Comparator is invalid!")
		return
	elif right.is_error():
		_err("Right-hand value is invalid!")
		return
	elif left.is_const() and right.is_const():
		if _eval_comparison(left.value, comparator, right.value):
			_current_block.make_jmp(label)
		
		return
	
	match comparator:
		Comparator.EQ:
			_current_block.load_x(left)
			_current_block.load_y(right)
			_current_block.make_beq(label)
		Comparator.NE:
			_current_block.load_x(left)
			_current_block.load_y(right)
			_current_block.make_bne(label)
		Comparator.GT:
			_current_block.load_x(left)
			_current_block.load_y(right)
			_current_block.make_bgt(label)
		Comparator.GE:
			_current_block.load_x(left)
			_current_block.load_y(right)
			_current_block.make_bge(label)
		Comparator.LT:
			_current_block.load_y(left)
			_current_block.load_x(right)
			_current_block.make_bgt(label)
		Comparator.LE:
			_current_block.load_y(left)
			_current_block.load_x(right)
			_current_block.make_bge(label)


# Parses a set command from NightScript source code to IR code:
func _parse_set(left: ParseValue, right: ParseValue) -> void:
	if not left.is_flag():
		_err("Command 'set' expects a variable left-hand value!")
	elif not right.is_error():
		_current_block.load_x(right)
		_current_block.make_stx(left.flag)


# Parses a dialog command from NightScript source code to IR code:
func _parse_dialog(command: String) -> void:
	match command:
		"show":
			_current_block.make_dgs()
		"hide":
			_current_block.make_dgh()
		_:
			_err("Command 'dialog' expects 'show' or 'hide'!")


# Parses a name command from NightScript source code to IR code:
func _parse_name(name: String) -> void:
	if name.empty():
		_current_block.make_dnc()
	else:
		_current_block.make_dnd(name)


# Parses a menu command from NightScript source code to IR code:
func _parse_menu(args: PoolStringArray) -> void:
	var command: String = args[0]
	args.remove(0)
	
	match command:
		"option":
			if args.size() == 3:
				_parse_menu_option(args[0], args[1], args[2])
			else:
				_err("Command 'menu option' expects 3 arguments!")
		"show":
			if args.size() == 0:
				_current_block.make_mns()
			else:
				_err("Command 'menu show' expects no arguments!")
		_:
			_err("Command 'menu' expects 'option' or 'show'!")


# Parses a menu option command from NightScript source code to IR code:
func _parse_menu_option(text: String, type: String, label: String) -> void:
	if type != "goto":
		_err("Command 'menu option' expects a 'goto' type!")
	elif label.empty():
		_err("Label is empty!")
	elif not label.is_valid_identifier():
		_err("Label '%s' is invalid!" % label)
	else:
		_current_block.make_mno(label, text)


# Parses a look command from NightScript source code to IR code:
func _parse_look(actor_key: String, direction: String) -> void:
	var angle: int
	
	match direction:
		"up":
			angle = -90
		"right":
			angle = 0
		"down":
			angle = 90
		"left":
			angle = 180
		_:
			_err("Command 'look' expects 'up', 'right', 'down', or 'left' directions!")
			return
	
	_current_block.make_lak(actor_key)
	_current_block.make_lxc(angle)
	_current_block.make_afd()


# Parses a path command from NightScript source code to IR code:
func _parse_path(args: PoolStringArray) -> void:
	var command: String = args[0]
	args.remove(0)
	
	match command:
		"find":
			if args.size() == 2:
				_parse_path_find(args[0], args[1])
			else:
				_err("Command 'path find' expects 2 arguments!")
		"do":
			if args.size() == 2:
				_parse_path_do(args[0], args[1])
			else:
				_err("Command 'path do' expects 2 arguments!")
		_:
			_err("Command 'path' expects 'find' or 'do'!")


# Parses a path find command from NightScript source code to IR code:
func _parse_path_find(actor_key: String, point: String) -> void:
	_current_block.make_lak(actor_key)
	_current_block.make_apf(point)


# Parses a path do command from NightScript source code to IR code:
func _parse_path_do(actor_key: String, point: String) -> void:
	_current_block.make_lak(actor_key)
	_current_block.make_apf(point)
	_current_block.make_apr()
	_current_block.make_apa()


# Parses a player command from NightScript source code to IR code:
func _parse_player(command: String) -> void:
	match command:
		"freeze":
			_current_block.make_plf()
		"unfreeze":
			_current_block.make_plt()
		_:
			_err("Command 'player' expects 'freeze' or 'unfreeze'!")


# Parses a quit command from NightScript source code to IR code:
func _parse_quit(command: String) -> void:
	match command:
		"title":
			_current_block.make_qtt()
		_:
			_err("Command 'quit' expects 'title'!")


# Finalizes the NightScript compiler's IR code:
func _finalize() -> void:
	for i in range(_blocks.size()):
		var block: IRBlock = _blocks[i]
		
		if not block.is_dead:
			if i >= _blocks.size() - 1:
				block.make_hlt()
			else:
				block.make_jmp(_blocks[i + 1].label)


# Performs post-parsing optimizations on the NightScript compiler's IR code
# until no changes occur:
func _optimize() -> void:
	pass


# Generates NightScript bytecode from the NightScript compiler's IR code:
func _generate_bytecode() -> PoolByteArray:
	var node_count: int = 0
	var pointers: Dictionary = {}
	
	for block in _blocks:
		pointers[block.label] = node_count
		node_count += block.nodes.size()
	
	var table: BytecodeTable = BytecodeTable.new()
	var stream: SerialWriteStream = SerialWriteStream.new()
	var vector_main: int = pointers.get("main", 0)
	var vector_repeat: int = pointers.get("repeat", vector_main)
	stream.put_u16(vector_main)
	stream.put_u16(vector_repeat)
	stream.put_u16(node_count)
	
	for block in _blocks:
		for node in block.nodes:
			stream.put_u8(node.op)
			var operands: int = NSOp.get_operands(node.op)
			
			if operands & NSOp.OPERAND_VAL:
				stream.put_s16(node.val)
			
			if operands & NSOp.OPERAND_PTR:
				stream.put_u16(pointers.get(node.lbl, node_count - 1))
			
			if operands & NSOp.OPERAND_FLG:
				stream.put_u16(table.get_flag_id(node.flg))
			
			if operands & NSOp.OPERAND_TXT:
				stream.put_u16(table.get_string_id(node.txt))
	
	var header_stream: SerialWriteStream = SerialWriteStream.new()
	header_stream.put_u8(0x01 if _get_metadata("cache") else 0x00)
	header_stream.put_u16(table.strings.size())
	
	for string in table.strings:
		header_stream.put_utf8_u16(string)
	
	header_stream.put_u16(table.flags.size())
	
	for flag in table.flags:
		header_stream.put_u16(flag.namespace)
		header_stream.put_u16(flag.key)
	
	header_stream.put_data(stream.get_buffer())
	return header_stream.get_buffer()
