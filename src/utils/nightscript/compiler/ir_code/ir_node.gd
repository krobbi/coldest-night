extends Object

# IR Node Wrapper
# Wrapper class for the NightScript compiler's IRNode class.

class IRNode extends Reference:
	
	# IR Node
	# An IR node is a helper structure used by a NightScript compiler that is an
	# intermediate representation of a NightScript operation.

	const ParseFlag: GDScript = preload("../parse/parse_flag.gd").ParseFlag
	
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
