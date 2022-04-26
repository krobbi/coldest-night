extends Object

# Menu Statement Wrapper
# Wrapper class for the NightScript compiler's StatementMenu class.

const Statement: GDScript = preload("./statement.gd").Statement

class StatementMenu extends Statement:

	# Menu Statement
	# A menu statement is a statement that represents a menu statement in the
	# statement stack.

	var block_body: IRBlock = null

	# Constructor. Passes the menu statement's line position and entry IR block
	# to the menu statement:
	func _init(pos_line: int, block_entry: IRBlock).(false, false, pos_line, block_entry) -> void:
		pass
