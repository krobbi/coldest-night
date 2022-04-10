extends Object

# If Statement Wrapper
# Wrapper class for the NightScript compiler's StatementIf class.

const Statement: GDScript = preload("./statement.gd").Statement

class StatementIf extends Statement:

	# If Statement
	# An if statement is a statement that represents an if statement in the
	# statement stack.

	var seen_else: bool = false
	var block_bodies: Array = []

	# Constructor. Passes the if statement's line position and entry IR block to
	# the if statement:
	func _init(pos_line: int, block_entry: IRBlock).(false, false, pos_line, block_entry) -> void:
		pass
