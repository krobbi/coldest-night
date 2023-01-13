extends Reference

# Optimizer
# The optimizer is a component of the NightScript compiler that optimizes IR
# code.

const IRCode: GDScript = preload("ir_code.gd")
const IROp: GDScript = preload("ir_op.gd")

# Get whether an IR operation is a terminator.
func is_op_terminator(op: IROp) -> bool:
	return op.type in [IROp.HALT, IROp.JUMP_LABEL, IROp.SHOW_DIALOG_MENU, IROp.QUIT_TO_TITLE]


# Optimize IR code.
func optimize_code(code: IRCode) -> void:
	var is_optimized: bool = true
	var iterations: int = 256
	
	while is_optimized and iterations > 0:
		is_optimized = false
		iterations -= 1
		
		for method in ["optimize_eliminate_unreachable_ops"]:
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
