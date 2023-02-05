extends Reference

# Optimizer
# The optimizer is a component of the NightScript compiler that optimizes IR
# code.

const IRBlock: GDScript = preload("ir_block.gd")
const IRCode: GDScript = preload("ir_code.gd")
const IROp: GDScript = preload("ir_op.gd")

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
	elif op.type == IROp.STORE_DIALOG_MENU_OPTION_TEXT_LABEL:
		return op.str_value_b
	
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


# Get whether an IR operation references a label.
func is_op_label(op: IROp) -> bool:
	return op.type in [
		IROp.JUMP_LABEL,
		IROp.JUMP_ZERO_LABEL,
		IROp.JUMP_NOT_ZERO_LABEL,
		IROp.CALL_FUNCTION_COUNT_LABEL,
		IROp.STORE_DIALOG_MENU_OPTION_LABEL,
		IROp.STORE_DIALOG_MENU_OPTION_TEXT_LABEL,
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
			"optimize_merge_subsequent_blocks",
			"optimize_eliminate_unreachable_ops",
			"optimize_eliminate_unreachable_blocks",
			"optimize_eliminate_push_drops",
		]:
			var method_iterations: int = 256
			
			while call(method, code) and method_iterations > 0:
				is_optimized = true
				method_iterations -= 1


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
