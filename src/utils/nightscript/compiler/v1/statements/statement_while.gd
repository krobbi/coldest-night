extends Object

# While Statement Wrapper
# Wrapper class for the NightScript compiler's StatementWhile class.

const Statement: GDScript = preload("./statement.gd").Statement

class StatementWhile extends Statement:

	# While Statement
	# A while statement is a statement that represents a while statement in the
	# statement stack.

	var block_body: IRBlock = null

	# Constructor. Passes the while statement's line position and entry IR block
	# to the while statement:
	func _init(pos_line: int, block_entry: IRBlock).(true, true, pos_line, block_entry) -> void:
		pass
