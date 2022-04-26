extends Object

# IR Block Wrapper
# Wrapper class for the NightScript compiler's IRBlock class.

class IRBlock extends Reference:
	
	# IR Block
	# An IR block is a helper structure used by a NightScript compiler that is
	# an intermediate representation of a jump target and its subsequent
	# NightScript operations.
	
	const IRNode: GDScript = preload("./ir_node.gd").IRNode
	const ParseFlag: GDScript = preload("../parse/parse_flag.gd").ParseFlag
	const ParseValue: GDScript = preload("../parse/parse_value.gd").ParseValue
	const StringTrace: GDScript = preload("./utils/string_trace.gd").StringTrace
	
	var label: String
	var block_next: IRBlock = null
	var is_dead: bool = false
	var nodes: Array = []
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
		dialog_name_trace.untrace()
		actor_key_trace.untrace()
	
	
	# Marks the IR block as dead. An IR block becomes dead if any subsequent IR
	# nodes in the IR block will never be reachable due to a logical
	# impossibility:
	func kill() -> void:
		is_dead = true
	
	
	# Pushes a parse value to the expression stack:
	func push_value(value: ParseValue) -> void:
		if value.is_const():
			make_phc(value.value)
		elif value.is_flag():
			make_phf(value.flag)
	
	
	# Adopts a copy of an IR node into the IR block if the IR block is not dead:
	func adopt_node(node: IRNode) -> void:
		match node.op:
			# Control flow:
			NightScript.HLT:
				make_hlt()
			NightScript.CLP:
				make_clp(node.txt)
			NightScript.RUN:
				make_run(node.txt)
			NightScript.SLP:
				make_slp()
			NightScript.JMP:
				make_jmp(node.lbl)
			NightScript.BNZ:
				make_bnz(node.lbl)
			
			# Stack operations:
			NightScript.PHC:
				make_phc(node.val)
			NightScript.PHF:
				make_phf(node.flg)
			NightScript.DUP:
				make_dup()
			NightScript.POP:
				make_pop()
			NightScript.STF:
				make_stf(node.flg)
			
			# Stack arithmetic and logic:
			NightScript.NEG:
				make_neg()
			NightScript.ADD:
				make_add()
			NightScript.SUB:
				make_sub()
			NightScript.MUL:
				make_mul()
			NightScript.CEQ:
				make_ceq()
			NightScript.CNE:
				make_cne()
			NightScript.CGT:
				make_cgt()
			NightScript.CGE:
				make_cge()
			NightScript.CLT:
				make_clt()
			NightScript.CLE:
				make_cle()
			NightScript.NOT:
				make_not()
			NightScript.AND:
				make_and()
			NightScript.LOR:
				make_lor()
			
			# Dialog operations:
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
			
			# Actor operations:
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
			
			# External operations:
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
	func make_slp() -> void:
		make_standalone(NightScript.SLP)
	
	
	# Makes a JMP IR node at the back of the IR block:
	func make_jmp(lbl: String) -> void:
		make_pointer(NightScript.JMP, lbl)
		kill()
	
	
	# Makes a BNZ IR node at the back of the IR block:
	func make_bnz(lbl: String) -> void:
		make_pointer(NightScript.BNZ, lbl)
	
	
	# Makes a PHC IR node at the back of the IR block:
	func make_phc(val: int) -> void:
		make_value(NightScript.PHC, val)
	
	
	# Makes a PHF IR node at the back of the IR block:
	func make_phf(flg: ParseFlag) -> void:
		make_flag(NightScript.PHF, flg)
	
	
	# Makes a DUP IR node at the back of the IR block:
	func make_dup() -> void:
		make_standalone(NightScript.DUP)
	
	
	# Makes a POP IR node at the back of the IR block:
	func make_pop() -> void:
		make_standalone(NightScript.POP)
	
	
	# Makes a STF IR node at the back of the IR block:
	func make_stf(flg: ParseFlag) -> void:
		make_flag(NightScript.STF, flg)
	
	
	# Makes an NEG IR node at the back of the IR block:
	func make_neg() -> void:
		make_standalone(NightScript.NEG)
	
	
	# Makes an ADD IR node at the back of the IR block:
	func make_add() -> void:
		make_standalone(NightScript.ADD)
	
	
	# Makes an SUB IR node at the back of the IR block:
	func make_sub() -> void:
		make_standalone(NightScript.SUB)
	
	
	# Makes an MUL IR node at the back of the IR block:
	func make_mul() -> void:
		make_standalone(NightScript.MUL)
	
	
	# Makes a CEQ IR node at the back of the IR block:
	func make_ceq() -> void:
		make_standalone(NightScript.CEQ)
	
	
	# Makes a CNE IR node at the back of the IR block:
	func make_cne() -> void:
		make_standalone(NightScript.CNE)
	
	
	# Makes a CGT IR node at the back of the IR block:
	func make_cgt() -> void:
		make_standalone(NightScript.CGT)
	
	
	# Makes a CGE IR node at the back of the IR block:
	func make_cge() -> void:
		make_standalone(NightScript.CGE)
	
	
	# Makes a CLT IR node at the back of the IR block:
	func make_clt() -> void:
		make_standalone(NightScript.CLT)
	
	
	# Makes a CLE IR node at the back of the IR block:
	func make_cle() -> void:
		make_standalone(NightScript.CLE)
	
	
	# Makes an NOT IR node at the back of the IR block:
	func make_not() -> void:
		make_standalone(NightScript.NOT)
	
	
	# Makes an AND IR node at the back of the IR block:
	func make_and() -> void:
		make_standalone(NightScript.AND)
	
	
	# Makes an LOR IR node at the back of the IR block:
	func make_lor() -> void:
		make_standalone(NightScript.LOR)
	
	
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
