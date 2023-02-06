extends Reference

# Optimizer
# The optimizer is a component of the NightScript compiler that optimizes IR
# code.

const IRBlock: GDScript = preload("ir_block.gd")
const IRCode: GDScript = preload("ir_code.gd")
const IROp: GDScript = preload("ir_op.gd")

# Set an IR operation's referenced label if it exists.
func set_op_label(op: IROp, label: String) -> void:
	if not is_op_label(op):
		return
	
	op.str_value_a = label


# Get an IR block from its label. Return null if the block does not exist.
func get_block(code: IRCode, label: String) -> IRBlock:
	for block in code.blocks:
		if block.label == label:
			return block
	
	return null


# Get an IR block's next block in IR code. Return null if no next block is
# found.
func get_next_block(code: IRCode, block: IRBlock) -> IRBlock:
	for index in range(code.blocks.size() - 1):
		if code.blocks[index] == block:
			return code.blocks[index + 1]
	
	return null


# Get an IR operation's referenced label.
func get_op_label(op: IROp) -> String:
	if not is_op_label(op):
		return ""
	
	return op.str_value_a


# Get whether an IR block is referenced in IR code.
func is_block_referenced(code: IRCode, block: IRBlock) -> bool:
	for other_block in code.blocks:
		for op in other_block.ops:
			if is_op_label(op) and get_op_label(op) == block.label:
				return true
	
	return false


# Get whether an IR block is terminated.
func is_block_terminated(block: IRBlock) -> bool:
	for index in range(block.ops.size() - 1, -1, -1):
		if is_op_terminator(block.ops[index]):
			return true
	
	return false


# Get whether an IR operation is a jump operation.
func is_op_jump(op: IROp) -> bool:
	return op.type in [IROp.JUMP_LABEL, IROp.JUMP_ZERO_LABEL, IROp.JUMP_NOT_ZERO_LABEL]


# Get whether an IR operation references a label.
func is_op_label(op: IROp) -> bool:
	return op.type in [
		IROp.JUMP_LABEL,
		IROp.JUMP_ZERO_LABEL,
		IROp.JUMP_NOT_ZERO_LABEL,
		IROp.CALL_FUNCTION_COUNT_LABEL,
		IROp.STORE_DIALOG_MENU_OPTION_LABEL,
	]


# Get whether an IR operation pushes a single value to the stack without causing
# any side effects.
func is_op_pure_push(op: IROp) -> bool:
	return op.type in [IROp.PUSH_IS_REPEAT, IROp.PUSH_INT, IROp.PUSH_STRING, IROp.LOAD_LOCAL_OFFSET]


# Get whether an IR operation is a terminator.
func is_op_terminator(op: IROp) -> bool:
	return op.type in [IROp.HALT, IROp.JUMP_LABEL, IROp.RETURN_FROM_FUNCTION, IROp.SHOW_DIALOG_MENU]


# Optimize IR code.
func optimize_code(code: IRCode) -> void:
	var is_optimized: bool = true
	var iterations: int = 256
	
	while is_optimized and iterations > 0:
		is_optimized = false
		iterations -= 1
		
		for method in [
			# Run optimizations that are confined to a single block. These may
			# benefit future optimizations, but never have any negative effect.
			"optimize_eliminate_unreachable_ops",
			"optimize_eliminate_push_drops",
			
			# Redirect operations that reference an empty block or a jump
			# operation to simplify control flow.
			"optimize_thread_labels",
			
			# Eliminate unreachable blocks created by the label threading
			# optimization to avoid blocking future optimizations that depend on
			# the control flow between blocks.
			"optimize_eliminate_unreachable_blocks",
			
			# Eliminate jump operations that lead directly to the subsequent
			# block. These are unnecessary and may block future optimizations.
			"optimize_eliminate_subsequent_jumps",
			
			# Merge unreferenced blocks that can only be accessed from the
			# previous block into the previous block. It is unclear if this is
			# actually beneficial, but it simplifies the IR code.
			"optimize_merge_subsequent_blocks",
			
			# Replace jumps to terminator operations with a copy of the
			# terminator operation. This is performed after the control flow
			# optimizations because it is more efficient to remove a jump and
			# fall through into the terminator operation if possible.
			"optimize_thread_terminators",
		]:
			var method_iterations: int = 256
			
			while call(method, code) and method_iterations > 0:
				is_optimized = true
				method_iterations -= 1

# Eliminate IR operations that follow a terminator operation and return whether
# any optimization was performed.
func optimize_eliminate_unreachable_ops(code: IRCode) -> bool:
	var is_optimized: bool = false
	
	for block in code.blocks:
		for terminator_index in range(block.ops.size() - 1):
			if is_op_terminator(block.ops[terminator_index]):
				for back_index in range(block.ops.size() - 1, terminator_index, -1):
					block.ops.remove(back_index)
				
				is_optimized = true
				break
	
	return is_optimized


# Eliminate pure push IR operations that are immediately followed by a drop IR
# operation and return whether any optimization was performed.
func optimize_eliminate_push_drops(code: IRCode) -> bool:
	var is_optimized: bool = false
	
	for block in code.blocks:
		var index: int = 0
		
		while index < block.ops.size() - 1:
			if is_op_pure_push(block.ops[index]) and block.ops[index + 1].type == IROp.DROP:
				block.ops.remove(index)
				block.ops.remove(index)
				is_optimized = true
			else:
				index += 1
	
	return is_optimized


# Redirect IR operations referencing empty IR blocks or jump operations to the
# subsequent IR block or jump target and return whether any optimization was
# performed.
func optimize_thread_labels(code: IRCode) -> bool:
	var is_optimized: bool = false
	
	for block in code.blocks:
		var target_label: String = ""
		
		if block.ops.empty():
			var next_block: IRBlock = get_next_block(code, block)
			
			if next_block:
				target_label = next_block.label
		elif block.ops[0].type == IROp.JUMP_LABEL:
			target_label = get_op_label(block.ops[0])
		
		if target_label.empty() or target_label == block.label:
			continue
		
		for other_block in code.blocks:
			for op in other_block.ops:
				if is_op_label(op) and get_op_label(op) == block.label:
					set_op_label(op, target_label)
					is_optimized = true
	
	return is_optimized


# Eliminate IR blocks that can never be reached and return whether any
# optimization was performed.
func optimize_eliminate_unreachable_blocks(code: IRCode) -> bool:
	var pending_blocks: Array = [code.blocks[0]]
	var reachable_blocks: Array = []
	
	while not pending_blocks.empty():
		var block: IRBlock = pending_blocks.pop_back()
		
		if not block or block in reachable_blocks:
			continue
		
		reachable_blocks.push_back(block)
		
		if not is_block_terminated(block):
			pending_blocks.push_back(get_next_block(code, block))
		
		for op in block.ops:
			if is_op_label(op):
				pending_blocks.push_back(get_block(code, get_op_label(op)))
	
	var is_optimized: bool = false
	
	for index in range(code.blocks.size() - 1, -1, -1):
		if not code.blocks[index] in reachable_blocks:
			code.blocks.remove(index)
			is_optimized = true
	
	return is_optimized


# Eliminate jump IR operations that lead to the subsequent IR block and return
# whether any optimization was performed.
func optimize_eliminate_subsequent_jumps(code: IRCode) -> bool:
	var is_optimized: bool = false
	
	for block in code.blocks:
		var next_block: IRBlock = get_next_block(code, block)
		
		if not next_block:
			continue
		
		for index in range(block.ops.size() - 1, -1, -1):
			var op: IROp = block.ops[index]
			
			if is_op_jump(op) and get_op_label(op) == next_block.label:
				block.ops.remove(index)
				
				# Preserve stack size on conditional jumps.
				if op.type != IROp.JUMP_LABEL:
					code.set_label(block.label)
					code.make_drop()
				
				is_optimized = true
			else:
				break
	
	return is_optimized


# Merge subsequent IR blocks if the second IR block is not referenced in IR code
# and return whether any optimization was performed.
func optimize_merge_subsequent_blocks(code: IRCode) -> bool:
	var is_optimized: bool = false
	
	for index in range(code.blocks.size() - 1, 0, -1):
		var block: IRBlock = code.blocks[index]
		
		if not is_block_referenced(code, block):
			code.blocks[index - 1].ops.append_array(block.ops)
			code.blocks.remove(index)
			is_optimized = true
	
	return is_optimized


# Replace jump IR operations to a terminator operation with a copy of the
# terminator operation and return whether any optimization was performed.
func optimize_thread_terminators(code: IRCode) -> bool:
	var is_optimized: bool = false
	
	for block in code.blocks:
		if block.ops.empty() or not is_op_terminator(block.ops[0]):
			continue
		
		for other_block in code.blocks:
			for op in other_block.ops:
				if(
						op.type == IROp.JUMP_LABEL and get_op_label(op) == block.label
						and op != block.ops[0]):
					op.copy(block.ops[0])
					is_optimized = true
	
	return is_optimized
