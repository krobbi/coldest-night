extends Reference

# Optimizer
# The optimizer is a component of the NightScript compiler that optimizes IR
# code.

const IRCode: GDScript = preload("ir_code.gd")

# Optimize IR code.
func optimize_code(code: IRCode) -> void:
	code.append_label("TODO: Implement optimizer")
