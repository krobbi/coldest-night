extends Object

# IR Block Wrapper
# Wrapper class for the NightScript compiler's IRBlock class.

class IRBlock extends Reference:
	
	# IR Block
	# An IR block is a helper structure used by a NightScript compiler that is
	# an intermediate representation of a jump target and its subsequent
	# NightScript operations.
	
	const IntTrace: GDScript = preload("./utils/int_trace.gd").IntTrace
	const IRNode: GDScript = preload("./ir_node.gd").IRNode
	const ParseFlag: GDScript = preload("../parse/parse_flag.gd").ParseFlag
	const ParseValue: GDScript = preload("../parse/parse_value.gd").ParseValue
	const StringTrace: GDScript = preload("./utils/string_trace.gd").StringTrace
	
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
			if nodes[-1].op == NightScript.JMP:
				size -= 1
				exit = nodes[-1].lbl
			else:
				exit = ""
		
		if other.is_dead:
			if other.nodes[-1].op == NightScript.JMP:
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
			NightScript.HLT:
				make_hlt()
			NightScript.CLP:
				make_clp(node.txt)
			NightScript.RUN:
				make_run(node.txt)
			NightScript.SLP:
				make_slp(node.val)
			NightScript.JMP:
				make_jmp(node.lbl)
			NightScript.BEQ:
				make_beq(node.lbl)
			NightScript.BNE:
				make_bne(node.lbl)
			NightScript.BGT:
				make_bgt(node.lbl)
			NightScript.BGE:
				make_bge(node.lbl)
			NightScript.LXC:
				make_lxc(node.val)
			NightScript.LXF:
				make_lxf(node.flg)
			NightScript.STX:
				make_stx(node.flg)
			NightScript.LYC:
				make_lyc(node.val)
			NightScript.LYF:
				make_lyf(node.flg)
			NightScript.STY:
				make_sty(node.flg)
			NightScript.DGS:
				make_dgs()
			NightScript.DGH:
				make_dgh()
			NightScript.DNC:
				make_dnc()
			NightScript.DND:
				make_dnd(node.txt)
			NightScript.DGM:
				make_dgm(node.txt)
			NightScript.MNO:
				make_mno(node.lbl, node.txt)
			NightScript.MNS:
				make_mns()
			NightScript.LAK:
				make_lak(node.txt)
			NightScript.AFD:
				make_afd()
			NightScript.APF:
				make_apf(node.txt)
			NightScript.APR:
				make_apr()
			NightScript.APA:
				make_apa()
			NightScript.PLF:
				make_plf()
			NightScript.PLT:
				make_plt()
			NightScript.QTT:
				make_qtt()
			NightScript.PSE:
				make_pse()
			NightScript.UNP:
				make_unp()
			NightScript.SAV:
				make_sav()
			NightScript.CKP:
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
		make_standalone(NightScript.HLT)
		kill()
	
	
	# Makes a CLP IR node at the back of the IR block:
	func make_clp(txt: String) -> void:
		make_text(NightScript.CLP, txt)
	
	
	# Makes an RUN IR node at the back of the IR block:
	func make_run(txt: String) -> void:
		make_text(NightScript.RUN, txt)
	
	
	# Makes an SLP IR node at the back of the IR block:
	func make_slp(val: int) -> void:
		make_value(NightScript.SLP, val)
	
	
	# Makes a JMP IR node at the back of the IR block:
	func make_jmp(lbl: String) -> void:
		make_pointer(NightScript.JMP, lbl)
		kill()
	
	
	# Makes a BEQ IR node at the back of the IR block:
	func make_beq(lbl: String) -> void:
		if x_trace.is_traced and y_trace.is_traced:
			if x_trace.value == y_trace.value:
				make_jmp(lbl)
			
			return
		
		make_pointer(NightScript.BEQ, lbl)
	
	
	# Makes a BNE IR node at the back of the IR block:
	func make_bne(lbl: String) -> void:
		if x_trace.is_traced and y_trace.is_traced:
			if x_trace.value != y_trace.value:
				make_jmp(lbl)
			
			return
		
		make_pointer(NightScript.BNE, lbl)
	
	
	# Makes a BGT IR node at the back of the IR block:
	func make_bgt(lbl: String) -> void:
		if x_trace.is_traced and y_trace.is_traced:
			if x_trace.value > y_trace.value:
				make_jmp(lbl)
			
			return
		
		make_pointer(NightScript.BGT, lbl)
	
	
	# Makes a BGE IR node at the back of the IR block:
	func make_bge(lbl: String) -> void:
		if x_trace.is_traced and y_trace.is_traced:
			if x_trace.value >= y_trace.value:
				make_jmp(lbl)
			
			return
		
		make_pointer(NightScript.BGE, lbl)
	
	
	# Makes an LXC IR node at the back of the IR block:
	func make_lxc(val: int) -> void:
		if x_trace.is_traced and x_trace.value == val:
			return
		
		make_value(NightScript.LXC, val)
		x_trace.trace(val)
	
	
	# Makes an LXF IR node at the back of the IR block:
	func make_lxf(flg: ParseFlag) -> void:
		make_flag(NightScript.LXF, flg)
		x_trace.untrace()
	
	
	# Makes an STX IR node at the back of the IR block:
	func make_stx(flg: ParseFlag) -> void:
		make_flag(NightScript.STX, flg)
	
	
	# Makes an LYC IR node at the back of the IR block:
	func make_lyc(val: int) -> void:
		if y_trace.is_traced and y_trace.value == val:
			return
		
		make_value(NightScript.LYC, val)
		y_trace.trace(val)
	
	
	# Makes an LYF IR node at the back of the IR block:
	func make_lyf(flg: ParseFlag) -> void:
		make_flag(NightScript.LYF, flg)
		y_trace.untrace()
	
	
	# Makes an STY IR node at the back of the IR block:
	func make_sty(flg: ParseFlag) -> void:
		make_flag(NightScript.STY, flg)
	
	
	# Makes a DGS IR node at the back of the IR block:
	func make_dgs() -> void:
		make_standalone(NightScript.DGS)
	
	
	# Makes a DGH IR node at the back of the IR block:
	func make_dgh() -> void:
		make_standalone(NightScript.DGH)
	
	
	# Makes a DNC IR node at the back of the IR block:
	func make_dnc() -> void:
		make_standalone(NightScript.DNC)
		dialog_name_trace.untrace()
	
	
	# Makes a DND IR node at the back of the IR block:
	func make_dnd(txt: String) -> void:
		if dialog_name_trace.is_traced and dialog_name_trace.value == txt:
			return
		
		make_text(NightScript.DND, txt)
		dialog_name_trace.trace(txt)
	
	
	# Makes a DGM IR node at the back of the IR block:
	func make_dgm(txt: String) -> void:
		make_text(NightScript.DGM, txt)
	
	
	# Makes an MNO IR node at the back of the IR block:
	func make_mno(lbl: String, txt: String) -> void:
		make_pointer_text(NightScript.MNO, lbl, txt)
	
	
	# Makes an MNS IR node at the back of the IR block:
	func make_mns() -> void:
		make_standalone(NightScript.MNS)
		kill()
	
	
	# Makes an LAK IR node at the back of the IR block:
	func make_lak(txt: String) -> void:
		if actor_key_trace.is_traced and actor_key_trace.value == txt:
			return
		
		make_text(NightScript.LAK, txt)
		actor_key_trace.trace(txt)
	
	
	# Makes an AFD IR node at the back of the IR block:
	func make_afd() -> void:
		make_standalone(NightScript.AFD)
	
	
	# Makes an APF IR node at the back of the IR block:
	func make_apf(txt: String) -> void:
		make_text(NightScript.APF, txt)
	
	
	# Makes an APR IR node at the back of the IR block:
	func make_apr() -> void:
		make_standalone(NightScript.APR)
	
	
	# Makes an APA IR node at the back of the IR block:
	func make_apa() -> void:
		make_standalone(NightScript.APA)
	
	
	# Makes a PLF IR node at the back of the IR block:
	func make_plf() -> void:
		make_standalone(NightScript.PLF)
	
	
	# Makes a PLT IR node at the back of the IR block:
	func make_plt() -> void:
		make_standalone(NightScript.PLT)
	
	
	# Makes a QTT IR node at the back of the IR block:
	func make_qtt() -> void:
		make_standalone(NightScript.QTT)
		kill()
	
	
	# Makes a PSE IR node at the back of the IR block:
	func make_pse() -> void:
		make_standalone(NightScript.PSE)
	
	
	# Makes a UNP IR node at the back of the IR block:
	func make_unp() -> void:
		make_standalone(NightScript.UNP)
	
	
	# Makes an SAV IR node at the back of the IR block:
	func make_sav() -> void:
		make_standalone(NightScript.SAV)
	
	
	# Makes a CKP IR node at the back of the IR block:
	func make_ckp() -> void:
		make_standalone(NightScript.CKP)
