extends Object

# Do Statement Wrapper
# Wrapper class for the NightScript compiler's StatementDo class.

const Statement: GDScript = preload("./statement.gd").Statement

class StatementDo extends Statement:

	# Do Statement
	# A do statement is a statement that represents a do statement in the
	# statement stack.

	var block_body: IRBlock = null

	# Constructor. Passes the do statement's line position and entry IR block to
	# the do statement:
	func _init(pos_line: int, block_entry: IRBlock).(true, true, pos_line, block_entry) -> void:
		pass
