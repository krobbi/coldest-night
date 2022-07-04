extends Object

# Option Statement Wrapper
# Wrapper class for the NightScript compiler's StatementOption class.

const Statement: GDScript = preload("./statement.gd").Statement

class StatementOption extends Statement:

	# Option Statement
	# An option statement is a statement that represents an option statement in
	# the statement stack.

	const StatementMenu: GDScript = preload("./statement_menu.gd").StatementMenu

	var block_body: IRBlock = null
	var block_skip: IRBlock = null

	# Constructor. Passes the option statement's menu statement, line position,
	# and entry IR block to the option statement:
	func _init(menu: StatementMenu, pos_line: int, block_entry: IRBlock).(
			true, false, pos_line, block_entry
	) -> void:
		block_exit = menu.block_exit
