extends Reference

# Optimizer
# The optimizer is an optional component of the NightScript compiler that
# optimizes an IR program.

const IRBlock: GDScript = preload("ir_block.gd")
const IROp: GDScript = preload("ir_op.gd")
const IRProgram: GDScript = preload("ir_program.gd")

# Gets an IR block from an IR program from its label. Returns null if the IR
# block does not exist:
func get_block(program: IRProgram, label: String) -> IRBlock:
	for block in program.blocks:
		if block.label == label:
			return block
	
	return null


# Gets an IR block's next IR block. Returns null if the IR block is at the end
# of the IR program:
func get_next_block(program: IRProgram, block: IRBlock) -> IRBlock:
	for i in range(program.blocks.size() - 1):
		if program.blocks[i] == block:
			return program.blocks[i + 1]
	
	return null


# Gets whether an IR block is important. Important IR blocks should never be
# removed or adopted into another IR block:
func is_block_important(block: IRBlock) -> bool:
	return block.label == "main" or block.label == "repeat" or block.label.begins_with("$$")


# Gets whether an IR block is terminal. An IR block is terminal if any
# subsequent IR blocks will never be executed unless by a jump:
func is_block_terminal(block: IRBlock) -> bool:
	for i in range(block.ops.size() - 1, -1, -1):
		if is_op_terminal(block.ops[i]):
			return true
	
	return false


# Gets whether an IR operation is a branch operation:
func is_op_branch(op: IROp) -> bool:
	match op.type:
		NightScript.JMP, NightScript.BNZ:
			return true
		_:
			return false


# Gets whether an IR operation is a pointer operation:
func is_op_pointer(op: IROp) -> bool:
	match op.type:
		NightScript.JMP, NightScript.BNZ, NightScript.MNO:
			return true
		_:
			return false


# Gets whether an IR operation is a quit. A quit IR operation is a terminal IR
# operation that does not take any operands:
func is_op_quit(op: IROp) -> bool:
	match op.type:
		NightScript.HLT, NightScript.MNS, NightScript.QTT:
			return true
		_:
			return false


# Gets whether an IR operation is terminal. An IR operation is terminal if any
# subsequent IR operations will never be executed unless by a jump:
func is_op_terminal(op: IROp) -> bool:
	match op.type:
		NightScript.HLT, NightScript.JMP, NightScript.MNS, NightScript.QTT:
			return true
		_:
			return false


# Optimizes an IR program:
func optimize_program(program: IRProgram) -> void:
	var should_optimize: bool = true
	var iterations: int = 256
	
	while should_optimize and iterations > 0:
		should_optimize = false
		iterations -= 1
		
		for method in [
			"optimize_eliminate_unreachable_ops",
			"optimize_thread_jumps",
			"optimize_thread_quits",
			"optimize_eliminate_unreachable_blocks",
			"optimize_eliminate_subsequent_branches",
			"optimize_eliminate_subsequent_quits",
		]:
			var method_iterations: int = 256
			
			while call(method, program) and method_iterations > 0:
				should_optimize = true
				method_iterations -= 1
			
			if method_iterations <= 0:
				print_debug("Possible infinite loop in optimization method '%s'!" % method)
	
	if iterations <= 0:
		print_debug("Possible infinite loop in optimizer!")


# Eliminates IR operations from individual IR blocks that follow the first
# terminal IR operation in the IR block. Returns whether any optimization was
# performed:
func optimize_eliminate_unreachable_ops(program: IRProgram) -> bool:
	var was_optimized: bool = false
	
	for block in program.blocks:
		var end_index: int = block.ops.size() - 1
		
		for i in range(end_index):
			if is_op_terminal(block.ops[i]):
				for j in range(end_index, i, -1):
					block.ops.remove(j)
				
				was_optimized = true
				break
	
	return was_optimized


# Redirects IR operations with pointers to jump IR operations to the jump IR
# operation's target. Returns whether any optimization was performed:
func optimize_thread_jumps(program: IRProgram) -> bool:
	var was_optimized: bool = false
	
	for block in program.blocks:
		if block.ops.empty() or block.ops[0].type != NightScript.JMP:
			continue
		
		var source_label: String = block.label
		var target_label: String = block.ops[0].key_value
		
		if source_label == target_label:
			continue
		
		for other in program.blocks:
			for op in other.ops:
				if is_op_pointer(op) and op.key_value == source_label:
					op.key_value = target_label
					was_optimized = true
	
	return was_optimized


# Replaces jump IR operations to quit IR operations with the quit IR operation.
# Returns whether any optimization was performed:
func optimize_thread_quits(program: IRProgram) -> bool:
	var was_optimized: bool = false
	
	for block in program.blocks:
		if block.ops.empty() or not is_op_quit(block.ops[0]):
			continue
		
		var source_label: String = block.label
		var target_type: int = block.ops[0].type
		
		for other in program.blocks:
			for op in other.ops:
				if op.type == NightScript.JMP and op.key_value == source_label:
					op.type = target_type
					was_optimized = true
	
	return was_optimized


# Eliminates unimportant IR blocks that can never be reached. Returns whether
# any optimization was performed:
func optimize_eliminate_unreachable_blocks(program: IRProgram) -> bool:
	var pending_blocks: Array = []
	var reachable_blocks: Array = []
	
	if program.has_block("main"):
		pending_blocks.push_back(get_block(program, "main"))
	else:
		pending_blocks.push_back(get_block(program, "$$main"))
	
	pending_blocks.push_back(get_block(program, "repeat"))
	
	while not pending_blocks.empty():
		var block: IRBlock = pending_blocks.pop_back()
		
		if not block or reachable_blocks.has(block):
			continue
		
		reachable_blocks.push_back(block)
		
		if not is_block_terminal(block):
			pending_blocks.push_back(get_next_block(program, block))
		
		for op in block.ops:
			if is_op_pointer(op):
				pending_blocks.push_back(get_block(program, op.key_value))
	
	var was_optimized: bool = false
	
	for i in range(program.blocks.size() - 1, -1, -1):
		var block: IRBlock = program.blocks[i]
		
		if not reachable_blocks.has(block):
			if not is_block_important(block):
				program.blocks.remove(i)
				was_optimized = true
			elif not block.ops.empty():
				block.ops.clear()
				was_optimized = true
	
	return was_optimized


# Eliminates branch IR operations that lead directly to the subsequent IR block.
# Returns whether any optimization was performed:
func optimize_eliminate_subsequent_branches(program: IRProgram) -> bool:
	var was_optimized: bool = false
	
	for i in range(program.blocks.size() - 2, -1, -1):
		var block: IRBlock = program.blocks[i]
		var label: String = program.blocks[i + 1].label
		
		for j in range(block.ops.size() -1, -1, -1):
			var op: IROp = block.ops[j]
			
			if is_op_branch(op) and op.key_value == label:
				if op.type == NightScript.JMP:
					block.ops.remove(j)
				else:
					# Preserve stack size on conditional branches:
					op.type = NightScript.POP
				
				was_optimized = true
			else:
				break
	
	return was_optimized


# Eliminates quit IR operations that precede an identical quit IR operation in
# the subsequent IR block. Returns whether any optimization was performed:
func optimize_eliminate_subsequent_quits(program: IRProgram) -> bool:
	var was_optimized: bool = false
	
	for i in range(program.blocks.size() - 2, -1, -1):
		var block: IRBlock = program.blocks[i]
		var next: IRBlock = program.blocks[i + 1]
		
		if next.ops.empty() or not is_op_quit(next.ops[0]):
			continue
		
		var type: int = next.ops[0].type
		
		for j in range(block.ops.size() - 1, -1, -1):
			var op: IROp = block.ops[j]
			
			if op.type == type:
				block.ops.remove(j)
				was_optimized = true
			else:
				break
	
	return was_optimized
