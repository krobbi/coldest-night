extends Object

# Statement Base Wrapper
# Wrapper class for the NightScript compiler's Statement class.

class Statement extends Reference:

	# Statement Base
	# A statement is a helper structure used by a NightScript compiler that is
	# an intermediate representation of a statement in the statement stack.
	
	const IRBlock = preload("../ir_code/ir_block.gd").IRBlock

	var is_breakable: bool
	var is_continuable: bool
	var pos_line: int
	var block_entry: IRBlock
	var block_test: IRBlock = null
	var block_exit: IRBlock = null

	# Constructor. Sets the whether the statement is breakable, whether the
	# statement is continuable, its line position, and its entry IR block:
	func _init(
			is_breakable_val: bool, is_continuable_val: bool, pos_line_val: int,
			block_entry_ref: IRBlock
	) -> void:
		is_breakable = is_breakable_val
		is_continuable = is_continuable_val
		pos_line = pos_line_val
		block_entry = block_entry_ref
