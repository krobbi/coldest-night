extends Reference

# NightScript Compiler
# A NightScript compiler is a NightScript utility that compiles NightScript
# source code to NightScript bytecode.

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
	
	
	# Returns whether the parse flag equals another parse flag by value:
	func equals(other: ParseFlag) -> bool:
		return namespace == other.namespace and key == other.key


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
	
	
	# Returns whether the IR node is a branch operation:
	func is_branch() -> bool:
		match op:
			NSOp.JMP, NSOp.BEQ, NSOp.BNE, NSOp.BGT, NSOp.BGE:
				return true
			_:
				return false
	
	
	# Returns whether the IR node has a pointer operand:
	func has_pointer() -> bool:
		return NSOp.get_operands(op) & NSOp.OPERAND_PTR != 0
	
	
	# Returns whether the IR node functionally equals another IR node by value:
	func equals(other: IRNode, head_label: String = "", other_head_label: String = "") -> bool:
		if op != other.op:
			return false
		
		var operands: int = NSOp.get_operands(op)

		if operands & NSOp.OPERAND_VAL and val != other.val:
			return false
		
		if operands & NSOp.OPERAND_PTR and lbl != other.lbl:
			if lbl != head_label or other.lbl != other_head_label:
				return false
		
		if operands & NSOp.OPERAND_FLG and not flg.equals(other.flg):
			return false
		
		if operands & NSOp.OPERAND_TXT and txt != other.txt:
			return false
		
		return true


class IntTrace extends Reference:
	
	# Int Trace
	# An int trace is a helper structure used by a NightScript compiler that
	# traces the state of an int register. It is used to optimize out
	# unnecessary writes to int registers.
	
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
	var block_next: IRBlock = null
	var is_dead: bool = false
	var nodes: Array = []
	var x_trace: IntTrace = IntTrace.new()
	var y_trace: IntTrace = IntTrace.new()
	var dialog_name_trace: StringTrace = StringTrace.new()
	var actor_key_trace: StringTrace = StringTrace.new()
	
	# Constructor. Sets the IR block's label:
	func _init(label_val: String) -> void:
		label = label_val
	
	
	# Gets whether the IR block is important. An IR block is important if it
	# should never be removed or adopted into another IR block:
	func is_important() -> bool:
		return label == "main" or label == "repeat" or label.begins_with("$$")
	
	
	# Returns whether the IR block is empty:
	func empty() -> bool:
		return nodes.empty()
	
	
	# Returns the size of the IR block:
	func size() -> int:
		return nodes.size()
	
	
	# Returns whether the IR block functionally equals another IR block by
	# value:
	func equals(other: IRBlock) -> bool:
		var size: int = size()
		var other_size: int = other.size()
		var exit: String = block_next.label if block_next else ""
		var other_exit: String = other.block_next.label if other.block_next else ""

		if is_dead:
			if nodes[-1].op == NSOp.JMP:
				size -= 1
				exit = nodes[-1].lbl
			else:
				exit = ""
		
		if other.is_dead:
			if other.nodes[-1].op == NSOp.JMP:
				other_size -= 1
				other_exit = other.nodes[-1].lbl
			else:
				other_exit = ""
		
		if size != other_size or exit != other_exit:
			return false
		
		for i in range(size):
			if not nodes[i].equals(other.nodes[i], label, other.label):
				return false
		
		return true
	
	# Clears the IR block's IR nodes and traces:
	func clear() -> void:
		nodes.clear()
		is_dead = false
		x_trace.untrace()
		y_trace.untrace()
		dialog_name_trace.untrace()
		actor_key_trace.untrace()
	
	
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
	
	
	# Adopts a copy of an IR node into the IR block if the IR block is not dead:
	func adopt_node(node: IRNode) -> void:
		match node.op:
			NSOp.HLT:
				make_hlt()
			NSOp.RUN:
				make_run(node.txt)
			NSOp.SLP:
				make_slp(node.val)
			NSOp.JMP:
				make_jmp(node.lbl)
			NSOp.BEQ:
				make_beq(node.lbl)
			NSOp.BNE:
				make_bne(node.lbl)
			NSOp.BGT:
				make_bgt(node.lbl)
			NSOp.BGE:
				make_bge(node.lbl)
			NSOp.LXC:
				make_lxc(node.val)
			NSOp.LXF:
				make_lxf(node.flg)
			NSOp.STX:
				make_stx(node.flg)
			NSOp.LYC:
				make_lyc(node.val)
			NSOp.LYF:
				make_lyf(node.flg)
			NSOp.STY:
				make_sty(node.flg)
			NSOp.DGS:
				make_dgs()
			NSOp.DGH:
				make_dgh()
			NSOp.DNC:
				make_dnc()
			NSOp.DND:
				make_dnd(node.txt)
			NSOp.DGM:
				make_dgm(node.txt)
			NSOp.MNO:
				make_mno(node.lbl, node.txt)
			NSOp.MNS:
				make_mns()
			NSOp.LAK:
				make_lak(node.txt)
			NSOp.AFD:
				make_afd()
			NSOp.APF:
				make_apf(node.txt)
			NSOp.APR:
				make_apr()
			NSOp.APA:
				make_apa()
			NSOp.PLF:
				make_plf()
			NSOp.PLT:
				make_plt()
			NSOp.QTT:
				make_qtt()
			NSOp.PSE:
				make_pse()
			NSOp.UNP:
				make_unp()
			NSOp.SAV:
				make_sav()
			NSOp.CKP:
				make_ckp()
	
	
	# Adopts an array of nodes into the IR block:
	func adopt_nodes(nodes_val: Array) -> void:
		for node in nodes_val:
			adopt_node(node)
	
	
	# Readopts the IR block's IR nodes:
	func readopt_nodes() -> void:
		var nodes_val: Array = nodes.duplicate()
		clear()
		adopt_nodes(nodes_val)
	
	
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
	
	
	# Makes an APF IR node at the back of the IR block:
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
	
	
	# Makes a CKP IR node at the back of the IR block:
	func make_ckp() -> void:
		make_standalone(NSOp.CKP)


class Statement extends Reference:

	# Statement Base
	# A statement is a helper structure used by a NightScript compiler that is
	# an intermediate representation of a statement in the statement stack.

	var pos_line: int
	var block_entry: IRBlock
	var block_exit: IRBlock = null

	# Constructor. Sets the statement's line position and entry IR block:
	func _init(pos_line_val: int, block_entry_ref: IRBlock) -> void:
		pos_line = pos_line_val
		block_entry = block_entry_ref


class StatementIf extends Statement:

	# If Statement
	# An if statement is a statement that represents an if statement in the
	# statement stack.

	var seen_else: bool = false
	var block_test: IRBlock = null
	var block_bodies: Array = []

	# Constructor. Passes the if statement's line position and entry IR block to
	# the if statement:
	func _init(pos_line: int, block_entry: IRBlock).(pos_line, block_entry) -> void:
		pass


class StatementWhile extends Statement:

	# While Statement
	# A while statement is a statement that represents a while statement in the
	# statement stack.

	var block_body: IRBlock = null
	var block_test: IRBlock = null

	# Constructor. Passes the while statement's line position and entry IR block
	# to the while statement:
	func _init(pos_line: int, block_entry: IRBlock).(pos_line, block_entry) -> void:
		pass


class StatementMenu extends Statement:

	# Menu Statement
	# A menu statement is a statement that represents a menu statement in the
	# statement stack.

	var block_body: IRBlock = null

	# Constructor. Passes the menu statement's line position and entry IR block
	# to the menu statement:
	func _init(pos_line: int, block_entry: IRBlock).(pos_line, block_entry) -> void:
		pass


class StatementOption extends Statement:

	# Option Statement
	# An option statement is a statement that represents an option statement in
	# the statement stack.

	var text: String
	var block_body: IRBlock = null
	var block_skip: IRBlock = null

	# Constructor. Passes the option statement's menu statement, text, line
	# position, and entry IR block to the option statement:
	func _init(menu: StatementMenu, text_val: String, pos_line: int, block_entry: IRBlock).(
			pos_line, block_entry
	) -> void:
		text = text_val
		block_exit = menu.block_exit


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

const RESERVED_CONSTS: Dictionary = {"false": 0, "true": 1}
const DEFAULT_METADATA: Dictionary = {
	"cache": 1,
	"optimize": 1,
	"optimize_adopt_child_blocks": 1,
	"optimize_deduplicate_blocks": 1,
	"optimize_eliminate_empty_blocks": 1,
	"optimize_eliminate_subsequent_branches": 1,
	"optimize_eliminate_subsequent_halts": 1,
	"optimize_eliminate_unreachable_blocks": 1,
	"optimize_thread_halts": 1,
	"optimize_thread_pointers": 1,
}

var _pos_line: int = 0
var _temp_block_count: int = 0
var _metadata: Dictionary = {}
var _scope_stack: Array = [{}]
var _statement_stack: Array = []
var _blocks: Array = []
var _error_block: IRBlock = null
var _current_block: IRBlock = null

# Compiles a NightScript source file to NightScript bytecode from its path:
func compile_path(path: String, optimize: bool) -> PoolByteArray:
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

	if optimize:
		_optimize()
	
	return _generate_bytecode()


# Compiles NightScript source code to NightScript bytecode:
func compile_source(source: String, optimize: bool) -> PoolByteArray:
	_reset()
	_parse_source(source)
	_finalize()

	if optimize:
		_optimize()
	
	return _generate_bytecode()


# Gets a metadata value from its key:
func _get_metadata(key: String) -> int:
	if _metadata.has(key):
		return _metadata[key]
	else:
		return DEFAULT_METADATA.get(key, 0)


# Gets an IR block from its label. Returns null if the IR block does not exist:
func _get_block(label: String) -> IRBlock:
	for block in _blocks:
		if block.label == label:
			return block
	
	return null


# Gets the topmost menu statement. Returns null if there are no menu statements
# in the statement stack:
func _get_statement_menu() -> StatementMenu:
	for i in range(_statement_stack.size() - 1, -1, -1):
		if _statement_stack[i] is StatementMenu:
			return _statement_stack[i]
	
	return null


# Gets the index of the topmost menu statement. Returns -1 if there are no menu
# statements in the statement stack:
func _get_statement_menu_index() -> int:
	for i in range(_statement_stack.size() - 1, -1, -1):
		if _statement_stack[i] is StatementMenu:
			return i
	
	return -1


# Gets the index of the topmost option statement. Returns -1 if there are no
# option statements in the statement stack:
func _get_statement_option_index() -> int:
	for i in range(_statement_stack.size() - 1, -1, -1):
		if _statement_stack[i] is StatementOption:
			return i
	
	return -1


# Gets whether the NightScript compiler's IR code is inside an if statement:
func _is_in_statement_if() -> bool:
	return not _statement_stack.empty() and _statement_stack[-1] is StatementIf


# Gets whether the NightScript compiler's IR code is inside a while statement:
func _is_in_statement_while() -> bool:
	return not _statement_stack.empty() and _statement_stack[-1] is StatementWhile


# Gets whether the NightScript compiler's IR code is inside a menu statement:
func _is_in_statement_menu() -> bool:
	return not _statement_stack.empty() and _statement_stack[-1] is StatementMenu


# Gets whether a menu statement exists in the statement stack:
func _is_in_statement_menu_deep() -> bool:
	for statement in _statement_stack:
		if statement is StatementMenu:
			return true
	
	return false


# Gets whether the NightScript compiler's IR code is inside an option statement:
func _is_in_statement_option() -> bool:
	return not _statement_stack.empty() and _statement_stack[-1] is StatementOption


# Returns whether an IR block exists from its label:
func _has_block(label: String) -> bool:
	for block in _blocks:
		if block.label == label:
			return true
	
	return false


# Returns whether a label is valid:
func _validate_label(label: String) -> bool:
	if label.empty():
		_err("Label is empty!")
		return false
	elif not label.is_valid_identifier():
		_err("Label '%s' is invalid!" % label)
		return false
	else:
		return true


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

	if index > 0:
		_blocks[index - 1].block_next = block
	
	if index < _blocks.size() - 1:
		block.block_next = _blocks[index + 1]

	return block


# Creates a new temporary IR block after the current IR block:
func _create_block_temp() -> IRBlock:
	_temp_block_count += 1
	return _create_block("$temp_%d" % _temp_block_count)


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
func _scan_value(symbol: String, scope_peek: int = -1) -> ParseValue:
	if symbol.empty():
		return _create_error("Value is empty!")
	elif RESERVED_CONSTS.has(symbol):
		return ParseValue.create_const(RESERVED_CONSTS[symbol])
	elif symbol.is_valid_identifier():
		if scope_peek < 0:
			scope_peek += _scope_stack.size()
		
		for i in range(scope_peek, -1, -1):
			var scope: Dictionary = _scope_stack[i]
			
			if scope.has(symbol):
				return scope[symbol]
		
		return _create_error("Identifier '%s' is undeclared in the current scope!" % symbol)
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
	# Open error block:
	if _error_block.empty():
		Global.logger.msg("NightScript compiler error log:")
		_error_block.make_plf()
		_error_block.make_pse()
		_error_block.make_dgs()
	
	if _pos_line:
		Global.logger.err("\t%d: %s" % [_pos_line, message])
		_error_block.make_dgm("ERROR ON LINE %d:{p=0.5}\n%s" % [_pos_line, message])
	else:
		Global.logger.err("\t%s" % message)
		_error_block.make_dgm("ERROR:{p=0.5}\n%s" % message)


# Resets the NightScript compiler's IR code:
func _reset() -> void:
	_pos_line = 0
	_temp_block_count = 0
	_metadata.clear()
	_scope_stack = [{}]
	_statement_stack.clear()
	_blocks.clear()
	_error_block = _create_block("$$error")
	_current_block = _create_block("$$main")


# Makes a conditional branch from the current IR block to a target label:
func _make_branch(label: String, left: ParseValue, comparator: int, right: ParseValue) -> void:
	if left.is_error():
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


# Parses NightScript source code to IR code:
func _parse_source(source: String) -> void:
	_pos_line = 0

	for line in source.split("\n"):
		_pos_line += 1
		_parse_line(line)
	
	_pos_line = 0


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
		"if":
			match args.size():
				1:
					_parse_if(_scan_value(args[0]), Comparator.NE, ParseValue.create_const(0))
				3:
					_parse_if(_scan_value(args[0]), _scan_comparator(args[1]), _scan_value(args[2]))
				_:
					_err("Command 'if' expects 1 or 3 arguments!")
		"elif":
			match args.size():
				1:
					_parse_elif(_scan_value(args[0], -2), Comparator.NE, ParseValue.create_const(0))
				3:
					_parse_elif(
							_scan_value(args[0], -2), _scan_comparator(args[1]),
							_scan_value(args[2], -2)
					)
				_:
					_err("Command 'elif' expects 1 or 3 arguments!")
		"else":
			if args.size() == 0:
				_parse_else()
			else:
				_err("Command 'else' expects no arguments!")
		"while":
			match args.size():
				1:
					_parse_while(_scan_value(args[0]), Comparator.NE, ParseValue.create_const(0))
				3:
					_parse_while(
							_scan_value(args[0]), _scan_comparator(args[1]), _scan_value(args[2])
					)
				_:
					_err("Command 'while' expects 1 or 3 arguments!")
		"menu":
			if args.size() == 0:
				_parse_menu()
			else:
				_err("Command 'menu' expects no arguments!")
		"option":
			match args.size():
				2, 3, 4:
					_parse_option(args)
				_:
					_err("Command 'option' expects 2, 3, or 4 arguments!")
		"end":
			match args.size():
				0:
					_parse_end_implicit()
				1:
					_parse_end(args[0])
				_:
					_err("Command 'end' expects 0 or 1 arguments!")
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


# Parses a define command from NightScript source code to IR code:
func _parse_define(identifier: String, value: ParseValue):
	if identifier.empty():
		_err("Identifier is empty!")
	elif not identifier.is_valid_identifier():
		_err("Identifier '%s' is invalid!" % identifier)
	elif RESERVED_CONSTS.has(identifier):
		_err("Identifier '%s' is reserved!" % identifier)
	elif _scope_stack[-1].has(identifier):
		_err("Identifier '%s' is already declared in the current scope!" % identifier)
	elif value.is_error():
		return
	else:
		_scope_stack[-1][identifier] = value


# Parses a label command from NightScript source code to IR code:
func _parse_label(label: String) -> void:
	if not _validate_label(label):
		return
	elif _has_block(label):
		_err("Label '%s' already exists!" % label)
	elif _is_in_statement_menu_deep():
		_err("Labels cannot be created inside menu statements!")
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
	if _validate_label(label):
		if _get_statement_menu_index() > _get_statement_option_index():
			_err("Command 'goto' cannot be used directly inside menu statements!")
		else:
			_make_branch(label, left, comparator, right)


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


# Parses an if command from NightScript source code to IR code:
func _parse_if(left: ParseValue, comparator: int, right: ParseValue) -> void:
	var statement: StatementIf = StatementIf.new(_pos_line, _current_block)
	statement.block_exit = _create_block_temp()
	var block_body: IRBlock = _create_block_temp()
	statement.block_bodies.push_back(block_body)
	statement.block_test = _create_block_temp()
	_current_block.make_jmp(statement.block_test.label)
	_current_block = statement.block_test
	_make_branch(block_body.label, left, comparator, right)
	_current_block = block_body
	_push_scope()
	_statement_stack.push_back(statement)


# Parses an elif command from NightScript source code to IR code:
func _parse_elif(left: ParseValue, comparator: int, right: ParseValue) -> void:
	if not _is_in_statement_if():
		_err("Command 'elif' was used outside of an if statement!")
		return
	
	var statement: StatementIf = _statement_stack[-1]

	if statement.seen_else:
		_err("Command 'elif' was used after 'else' in the current if statement!")
		return
	
	_current_block.make_jmp(statement.block_exit.label)
	_pop_scope()
	var block_body: IRBlock = _create_block_temp()
	statement.block_bodies.push_back(block_body)
	_current_block = statement.block_test
	_make_branch(block_body.label, left, comparator, right)
	_current_block = block_body
	_push_scope()


# Parses an else command from NightScript source code to IR code:
func _parse_else() -> void:
	if not _is_in_statement_if():
		_err("Command 'else' was used outside of an if statement!")
		return
	
	var statement: StatementIf = _statement_stack[-1]

	if statement.seen_else:
		_err("Command 'else' was already used in the current if statement!")
		return
	
	statement.seen_else = true
	_current_block.make_jmp(statement.block_exit.label)
	_pop_scope()
	var block_body: IRBlock = _create_block_temp()
	statement.block_bodies.push_back(block_body)
	statement.block_test.make_jmp(block_body.label)
	_current_block = block_body
	_push_scope()


# Parses a while command from NightScript source code to IR code:
func _parse_while(left: ParseValue, comparator: int, right: ParseValue) -> void:
	var statement: StatementWhile = StatementWhile.new(_pos_line, _current_block)
	statement.block_exit = _create_block_temp()
	statement.block_test = _create_block_temp()
	statement.block_body = _create_block_temp()
	_current_block.make_jmp(statement.block_test.label)
	_current_block = statement.block_test
	_make_branch(statement.block_body.label, left, comparator, right)
	_current_block.make_jmp(statement.block_exit.label)
	_current_block = statement.block_body
	_push_scope()
	_statement_stack.push_back(statement)


# Parses a menu command from NightScript source code to IR code:
func _parse_menu() -> void:
	if _get_statement_menu_index() > _get_statement_option_index():
		_err("Menu statements cannot be directly nested!")
		return
	
	var statement: StatementMenu = StatementMenu.new(_pos_line, _current_block)
	statement.block_exit = _create_block_temp()
	statement.block_body = _create_block_temp()
	_current_block.make_jmp(statement.block_body.label)
	_current_block = statement.block_body
	_push_scope()
	_statement_stack.push_back(statement)


# Parses an option command from NightScript source code to IR code:
func _parse_option(args: PoolStringArray) -> void:
	var statement: StatementMenu = _get_statement_menu()

	if not statement:
		_err("Command 'option' was used outside of a menu statement!")
		return
	
	var text: String = args[0]
	var type: String = args[1]
	args.remove(1)
	args.remove(0)

	match type:
		"none":
			if args.size() == 0:
				_parse_option_none(statement, text)
			else:
				_err("Command 'option none' expects no arguments!")
		"goto":
			if args.size() == 1:
				_parse_option_goto(text, args[0])
			else:
				_err("Command 'option goto' expects 1 argument!")
		"set":
			if args.size() == 2:
				_parse_option_set(statement, text, _scan_value(args[0]), _scan_value(args[1]))
			else:
				_err("Command 'option set' expects 2 arguments!")
		"do":
			if args.size() == 0:
				_parse_option_do(statement, text)
			else:
				_err("Command 'option do' expects no arguments!")
		_:
			_err("Command 'option' expects a 'none', 'goto', 'set', or 'do' type!")


# Parses an option none command from NightScript source code to IR code:
func _parse_option_none(statement: StatementMenu, text: String) -> void:
	_current_block.make_mno(statement.block_exit.label, text)


# Parses an option goto command from NightScript source code to IR code:
func _parse_option_goto(text: String, label: String) -> void:
	if _validate_label(label):
		_current_block.make_mno(label, text)


# Parses an option set command from NightScript source code to IR code:
func _parse_option_set(
		statement: StatementMenu, text: String, left: ParseValue, right: ParseValue
) -> void:
	if not left.is_flag():
		_err("Command 'option set' expects a variable left-hand value!")
	elif not right.is_error():
		var option_block: IRBlock = _create_block_temp()
		option_block.load_x(right)
		option_block.make_stx(left.flag)
		option_block.make_jmp(statement.block_exit.label)
		_current_block.make_mno(option_block.label, text)


# Parses an option do command from NightScript source code to IR code:
func _parse_option_do(menu: StatementMenu, text: String) -> void:
	if _get_statement_option_index() > _get_statement_menu_index():
		_err("Option statements cannot be directly nested!")
		return

	var statement: StatementOption = StatementOption.new(menu, text, _pos_line, _current_block)
	statement.block_skip = _create_block_temp()
	statement.block_body = _create_block_temp()
	_current_block.make_jmp(statement.block_skip.label)
	_current_block = statement.block_body
	_push_scope()
	_statement_stack.push_back(statement)


# Parses an implicit end command from NightScript source code to IR code:
func _parse_end_implicit() -> void:
	if _is_in_statement_if():
		_parse_end_if()
	elif _is_in_statement_while():
		_parse_end_while()
	elif _is_in_statement_menu():
		_parse_end_menu()
	elif _is_in_statement_option():
		_parse_end_option()
	else:
		_err("Command 'end' was used outside of a statement!")


# Parses an end command from NightScript source code to IR code:
func _parse_end(type: String) -> void:
	match type:
		"if":
			_parse_end_if()
		"while":
			_parse_end_while()
		"menu":
			_parse_end_menu()
		"option":
			_parse_end_option()
		_:
			_err("Command 'end' expects 'if', 'while', 'menu', or 'option'!")


# Parses an end if command from NightScript source code to IR code:
func _parse_end_if() -> void:
	if not _is_in_statement_if():
		_err("Command 'end if' was used outside of an if statement!")
		return
	
	var statement: StatementIf = _statement_stack.pop_back()
	_current_block.make_jmp(statement.block_exit.label)
	_pop_scope()
	statement.block_test.make_jmp(statement.block_exit.label)
	_current_block = statement.block_exit


# Parses an end while command from NightScript source code to IR code:
func _parse_end_while() -> void:
	if not _is_in_statement_while():
		_err("Command 'end while' was used outside of a while statement!")
		return
	
	var statement: StatementWhile = _statement_stack.pop_back()
	_current_block.make_jmp(statement.block_test.label)
	_pop_scope()
	_current_block = statement.block_exit


# Parses an end menu command from NightScript source code to IR code:
func _parse_end_menu() -> void:
	if not _is_in_statement_menu():
		_err("Command 'end menu' was used outside of a menu statement!")
		return
	
	var statement: StatementMenu = _statement_stack.pop_back()
	_current_block.make_mns()
	_pop_scope()
	_current_block = statement.block_exit


# Parses an end option command from NightScript source code to IR code:
func _parse_end_option() -> void:
	if not _is_in_statement_option():
		_err("Command 'end option' was used outside of an option statement!")
		return
	
	var statement: StatementOption = _statement_stack.pop_back()
	_current_block.make_jmp(statement.block_exit.label)
	_pop_scope()
	_current_block = statement.block_skip
	_current_block.make_mno(statement.block_body.label, statement.text)


# Finalizes the NightScript compiler's IR code:
func _finalize() -> void:
	_finalize_end_statements()
	_finalize_validate_labels()
	_finalize_error_block()
	_finalize_clear_main()
	_finalize_terminate()


# Ends open statements and logs error messages:
func _finalize_end_statements() -> void:
	while not _statement_stack.empty():
		_pos_line = _statement_stack[-1].pos_line

		if _is_in_statement_if():
			_err("If statement was not ended!")
			_parse_end_if()
		elif _is_in_statement_while():
			_err("While statement was not ended!")
			_parse_end_while()
		elif _is_in_statement_menu():
			_err("Menu statement was not ended!")
			_parse_end_menu()
		elif _is_in_statement_option():
			_err("Option statement was not ended!")
			_parse_end_option()
		else:
			_statement_stack.remove(_statement_stack.size() - 1)
	
	_pos_line = 0


# Validates that all referenced labels exist and logs error messages:
func _finalize_validate_labels() -> void:
	var block_default: IRBlock = null

	for block in _blocks:
		for node in block.nodes:
			if not node.has_pointer() or _has_block(node.lbl):
				continue
			
			_err("Label '%s' does not exist!" % node.lbl)

			if not block_default:
				block_default = _create_block_temp()
				block_default.make_hlt()
			
			node.lbl = block_default.label


# Finalizes the error IR block in the NightScript compiler's IR code:
func _finalize_error_block() -> void:
	if _error_block.empty():
		return
	
	_error_block.make_dgh()
	_error_block.make_unp()
	_error_block.make_plt()

	if _has_block("repeat"):
		var error_nodes: Array = _error_block.nodes.duplicate()
		_error_block.clear()
		_error_block.make_lxc(1)
		_error_block.make_stx(ParseFlag.new("$", "r"))
		_error_block.adopt_nodes(error_nodes)
		_error_block.make_lxf(ParseFlag.new("$", "r"))
		_error_block.make_lyc(0)
		_error_block.make_bne("repeat")
	
	_error_block.make_jmp("main" if _has_block("main") else "$$main")


# Clears the '$$main' parse block if a 'main' parse block exists:
func _finalize_clear_main() -> void:
	if _has_block("main"):
		_get_block("$$main").clear()


# Adds a terminal HLT operation to the final parse block:
func _finalize_terminate() -> void:
	var block: IRBlock = _blocks[-1]
	block.make_hlt()


# Recreates the link references between IR blocks in the NightScript compiler's
# IR code:
func _link_blocks() -> void:
	for i in range(_blocks.size()):
		if i < _blocks.size() - 1:
			_blocks[i].block_next = _blocks[i + 1]
		else:
			_blocks[i].block_next = null


# Performs post-parsing optimizations on the NightScript compiler's IR code
# until no changes occur:
func _optimize() -> void:
	if not _get_metadata("optimize"):
		return
	
	var is_optimized: bool = true
	var iterations: int = 256
	
	while is_optimized and iterations:
		is_optimized = false
		iterations -= 1

		for optimization in [
			"deduplicate_blocks",
			"thread_pointers",
			"thread_halts",
			"eliminate_unreachable_blocks",
			"eliminate_subsequent_branches",
			"eliminate_subsequent_halts",
			"eliminate_empty_blocks",
			"adopt_child_blocks",
		]:
			if not _get_metadata("optimize_%s" % optimization):
				continue
			
			var method: String = "_optimize_%s" % optimization
			var sub_iterations: int = 256

			while call(method) and sub_iterations:
				is_optimized = true
				sub_iterations -= 1


# Redirects IR node's pointers to functionally identical IR blocks to the first
# or most important duplicate IR block. Returns whether any optimization was
# performed:
func _optimize_deduplicate_blocks() -> bool:
	var is_optimized: bool = false

	for i in range(_blocks.size() - 1):
		var block_a: IRBlock = _blocks[i]

		for j in range(i + 1, _blocks.size()):
			var block_b: IRBlock = _blocks[j]

			if not block_a.equals(block_b):
				continue
			
			var source_label: String = block_b.label
			var target_label: String = block_a.label

			if block_b.is_important():
				if block_a.is_important():
					continue
				else:
					source_label = block_a.label
					target_label = block_b.label
			
			for block in _blocks:
				if(
						not block.is_dead and block.block_next
						and block.block_next.label == source_label
				):
					block.make_jmp(target_label)
					is_optimized = true
				
				for node in block.nodes:
					if node.has_pointer() and node.lbl == source_label:
						node.lbl = target_label
						is_optimized = true
	
	return is_optimized


# Redirects IR node's pointers to jump operations to the target jump operation's
# target. Returns whether any optimization was performed:
func _optimize_thread_pointers() -> bool:
	var is_optimized: bool = false

	for source_block in _blocks:
		if source_block.empty():
			continue
		
		var source_node: IRNode = source_block.nodes[0]
		var source_label: String = source_block.label
		var target_label: String = source_node.lbl

		if source_node.op != NSOp.JMP or source_label == target_label:
			continue
		
		for block in _blocks:
			for node in block.nodes:
				if node.has_pointer() and node.lbl == source_label:
					node.lbl = target_label
					is_optimized = true
	
	return is_optimized


# Replaces jump operations to halt operations with halt operations. Returns
# whether any optimization was performed:
func _optimize_thread_halts() -> bool:
	var is_optimized: bool = false

	for source_block in _blocks:
		if source_block.empty() or source_block.nodes[0].op != NSOp.HLT:
			continue
		
		var source_label: String = source_block.label

		for block in _blocks:
			for node in block.nodes:
				if node.op == NSOp.JMP and node.lbl == source_label:
					node.op = NSOp.HLT
					is_optimized = true
	
	return is_optimized


# Eliminates IR blocks that are not important and can never be reached. Returns
# whether any optimization was performed:
func _optimize_eliminate_unreachable_blocks() -> bool:
	var pending_blocks: Array = []
	var reachable_blocks: Array = []
	pending_blocks.push_back(_get_block("main") if _has_block("main") else _get_block("$$main"))
	pending_blocks.push_back(_get_block("repeat"))

	while not pending_blocks.empty():
		var block: IRBlock = pending_blocks.pop_back()

		if not block or reachable_blocks.has(block):
			continue
		
		reachable_blocks.push_back(block)

		if not block.is_dead:
			pending_blocks.push_back(block.block_next)
		
		for node in block.nodes:
			if node.has_pointer():
				pending_blocks.push_back(_get_block(node.lbl))
	
	var is_optimized: bool = false

	for i in range(_blocks.size() - 1, -1, -1):
		var block: IRBlock = _blocks[i]

		if not block.is_important() and not reachable_blocks.has(block):
			_blocks.remove(i)
			is_optimized = true
	
	if is_optimized:
		_link_blocks()
	
	return is_optimized


# Eliminates IR nodes that branch directly to the subsequent IR block. Returns
# whether any optimization was performed:
func _optimize_eliminate_subsequent_branches() -> bool:
	var is_optimized: bool = false

	for i in range(_blocks.size() - 2, -1, -1):
		var is_block_optimized: bool = false
		var block: IRBlock = _blocks[i]
		var next_label: String = block.block_next.label

		for j in range(block.size() - 1, -1, -1):
			var node: IRNode = block.nodes[j]

			if node.is_branch() and node.lbl == next_label:
				block.nodes.remove(j)
				is_block_optimized = true
			else:
				break

		if is_block_optimized:
			block.readopt_nodes()
			is_optimized = true
	
	return is_optimized


# Eliminates HLT IR nodes that precede HLT IR nodes. Returns whether any
# optimization was performed:
func _optimize_eliminate_subsequent_halts() -> bool:
	var is_optimized: bool = false

	for i in range(_blocks.size() - 2, -1, -1):
		var block: IRBlock = _blocks[i]
		var next_block: IRBlock = _blocks[i + 1]

		if block.empty() or next_block.empty():
			continue
		
		if block.nodes[-1].op == NSOp.HLT and next_block.nodes[0].op == NSOp.HLT:
			block.nodes.remove(block.size() - 1)
			block.readopt_nodes()
			is_optimized = true

	return is_optimized


# Eliminates IR blocks that are not important and are empty. Returns whether any
# optimization was performed:
func _optimize_eliminate_empty_blocks() -> bool:
	var is_optimized: bool = false

	for i in range(_blocks.size() - 1, -1, -1):
		var block: IRBlock = _blocks[i]

		if not block.is_important() and block.empty():
			_blocks.remove(i)
			is_optimized = true
	
	if is_optimized:
		_link_blocks()
	
	return is_optimized


# Adopts IR blocks that are not important and have a single entry point at the
# end of another IR block into their parent IR block. Returns whether any
# optimization was performed:
func _optimize_adopt_child_blocks() -> bool:
	var is_optimized: bool = false

	for i in range(_blocks.size() - 1, -1, -1):
		var child_block: IRBlock = _blocks[i]

		if child_block.is_important():
			continue
		
		var is_invalid: bool = false
		var parent_blocks: Array = []
		
		for parent_block in _blocks:
			if parent_block == _error_block and _error_block.empty():
				continue
			elif parent_block.label == "$$main" and _has_block("main"):
				continue
			elif parent_block.is_dead:
				var parent_node: IRNode = parent_block.nodes[-1]

				if parent_node.op == NSOp.JMP and parent_node.lbl == child_block.label:
					parent_blocks.push_back(parent_block)
			elif parent_block.block_next == child_block:
				parent_blocks.push_back(parent_block)
			
			if parent_blocks.size() > 1:
				break
			
			var body_end: int = parent_block.size()

			while body_end > 0:
				var parent_node: IRNode = parent_block.nodes[body_end - 1]

				if parent_node.is_branch() and parent_node.lbl == child_block.label:
					body_end -= 1
				else:
					break
			
			for j in range(body_end):
				var parent_node: IRNode = parent_block.nodes[j]

				if parent_node.has_pointer() and parent_node.lbl == child_block.label:
					is_invalid = true
					break
		
		if is_invalid or parent_blocks.size() != 1:
			continue
		
		var parent_block: IRBlock = parent_blocks[0]

		for j in range(parent_block.size() - 1, -1, -1):
			var parent_node: IRNode = parent_block.nodes[j]

			if parent_node.is_branch() and parent_node.lbl == child_block.label:
				parent_block.nodes.remove(j)
			else:
				break
		
		parent_block.readopt_nodes()
		parent_block.adopt_nodes(child_block.nodes.duplicate())

		if not child_block.is_dead:
			if child_block.block_next:
				parent_block.make_jmp(child_block.block_next.label)
			else:
				parent_block.make_hlt()

		_blocks.remove(i)
		_link_blocks()
		is_optimized = true

	return is_optimized


# Generates NightScript bytecode from the NightScript compiler's IR code:
func _generate_bytecode() -> PoolByteArray:
	var node_count: int = 0
	var pointers: Dictionary = {}
	
	for block in _blocks:
		pointers[block.label] = node_count
		node_count += block.size()
	
	var table: BytecodeTable = BytecodeTable.new()
	var stream: SerialWriteStream = SerialWriteStream.new()
	var vector_main: int = pointers.get("main", pointers.get("$$main", 0))
	var vector_repeat: int = pointers.get("repeat", vector_main)

	if not _error_block.empty():
		if vector_main == vector_repeat:
			vector_main = pointers.get("$$error", vector_main)
			vector_repeat = vector_main
		else:
			vector_repeat = pointers.get("$$error", vector_repeat)
			vector_main = vector_repeat + 2

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
