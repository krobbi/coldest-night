extends Reference

# IR Code
# An IR code is a structure used by the NightScript compiler that represents a
# NightScript program in labeled blocks.

const IRBlock: GDScript = preload("ir_block.gd")
const IROp: GDScript = preload("ir_op.gd")

var is_pausable: bool
var current: IRBlock
var blocks: Array
var unique_label_count: int

# Reset the IR code.
func _init() -> void:
	reset()


# Reset the IR code.
func reset() -> void:
	is_pausable = true
	current = IRBlock.new(".main")
	blocks = [current]
	unique_label_count = 0


# Set the current label.
func set_label(value: String) -> void:
	for block in blocks:
		if block.label == value:
			current = block
			return


# Get the current label.
func get_label() -> String:
	return current.label


# Get a unique label from its name.
func get_unique_label(name: String) -> String:
	unique_label_count += 1
	return ".L%d_%s" % [unique_label_count, name]


# Return whether a label exists.
func has_label(label: String) -> bool:
	for block in blocks:
		if block.label == label:
			return true
	
	return false


# Append a label at the end of the IR code.
func append_label(label: String) -> void:
	if has_label(label):
		return
	
	blocks.push_back(IRBlock.new(label))


# Append a unique label at the end of the IR code from its name and return it.
func append_unique_label(name: String) -> String:
	var label: String = get_unique_label(name)
	append_label(label)
	return label


# Insert a label after the current label.
func insert_label(label: String) -> void:
	if has_label(label):
		return
	
	var position: int = blocks.size()
	
	for i in range(position):
		if blocks[i] == current:
			position = i + 1
			break
	
	blocks.insert(position, IRBlock.new(label))


# Insert a unique label after the current label from its name and return it.
func insert_unique_label(name: String) -> String:
	var label: String = get_unique_label(name)
	insert_label(label)
	return label


# Make an IR operation in the current label.
func make_op(type: int) -> void:
	current.ops.push_back(IROp.new(type))


# Make an IR operation in the current label with an int value.
func make_op_int(type: int, value: int) -> void:
	var op: IROp = IROp.new(type)
	op.int_value_a = value
	current.ops.push_back(op)


# Make an IR operation in the current label with a string value.
func make_op_str(type: int, value: String) -> void:
	var op: IROp = IROp.new(type)
	op.str_value_a = value
	current.ops.push_back(op)


# Make an IR operation in the current label with two string values.
func make_op_str_str(type: int, value_a: String, value_b: String) -> void:
	var op: IROp = IROp.new(type)
	op.str_value_a = value_a
	op.str_value_b = value_b
	current.ops.push_back(op)


# Make a halt IR operation in the current label.
func make_halt() -> void:
	make_op(IROp.HALT)


# Make a run program IR operation in the current label.
func make_run_program() -> void:
	make_op(IROp.RUN_PROGRAM)


# Make a run program key IR operation in the current label.
func make_run_program_key(key: String) -> void:
	make_op_str(IROp.RUN_PROGRAM_KEY, key)


# Make a call program IR operation in the current label.
func make_call_program() -> void:
	make_op(IROp.CALL_PROGRAM)


# Make a call program key IR operation in the current label.
func make_call_program_key(key: String) -> void:
	make_op_str(IROp.CALL_PROGRAM_KEY, key)


# Make a sleep IR operation in the current label.
func make_sleep() -> void:
	make_op(IROp.SLEEP)


# Make a jump label IR operation in the current label.
func make_jump_label(label: String) -> void:
	make_op_str(IROp.JUMP_LABEL, label)


# Make a jump zero label IR operation in the current label.
func make_jump_zero_label(label: String) -> void:
	make_op_str(IROp.JUMP_ZERO_LABEL, label)


# Make a jump not zero label IR operation in the current label.
func make_jump_not_zero_label(label: String) -> void:
	make_op_str(IROp.JUMP_NOT_ZERO_LABEL, label)


# Make a drop IR operation in the current label.
func make_drop() -> void:
	make_op(IROp.DROP)


# Make a duplicate IR operation in the current label.
func make_duplicate() -> void:
	make_op(IROp.DUPLICATE)


# Make a push is repeat IR operation in the current label.
func make_push_is_repeat() -> void:
	make_op(IROp.PUSH_IS_REPEAT)


# Make a push int IR operation in the current label.
func make_push_int(value: int) -> void:
	make_op_int(IROp.PUSH_INT, value)


# Make a push string IR operation in the current label.
func make_push_string(value: String) -> void:
	make_op_str(IROp.PUSH_STRING, value)


# Make a load flag namespace key IR operation in the current label.
func make_load_flag_namespace_key(namespace: String, key: String) -> void:
	make_op_str_str(IROp.LOAD_FLAG_NAMESPACE_KEY, namespace, key)


# Make a store flag namespace key IR operation in the current label.
func make_store_flag_namespace_key(namespace: String, key: String) -> void:
	make_op_str_str(IROp.STORE_FLAG_NAMESPACE_KEY, namespace, key)


# Make a unary negate IR operation in the current label.
func make_unary_negate() -> void:
	make_op(IROp.UNARY_NEGATE)


# Make a unary not IR operation in the current label.
func make_unary_not() -> void:
	make_op(IROp.UNARY_NOT)


# Make a binary add IR operation in the current label.
func make_binary_add() -> void:
	make_op(IROp.BINARY_ADD)


# Make a binary subtract IR operation in the current label.
func make_binary_subtract() -> void:
	make_op(IROp.BINARY_SUBTRACT)


# Make a binary mutliply IR operation in the current label.
func make_binary_multiply() -> void:
	make_op(IROp.BINARY_MULTIPLY)


# Make a binary equals IR operation in the current label.
func make_binary_equals() -> void:
	make_op(IROp.BINARY_EQUALS)


# Make a binary not equals IR operation in the current label.
func make_binary_not_equals() -> void:
	make_op(IROp.BINARY_NOT_EQUALS)


# Make a binary greater IR operation in the current label.
func make_binary_greater() -> void:
	make_op(IROp.BINARY_GREATER)


# Make a binary greater equals IR operation in the current label.
func make_binary_greater_equals() -> void:
	make_op(IROp.BINARY_GREATER_EQUALS)


# Make a binary less IR operation in the current label.
func make_binary_less() -> void:
	make_op(IROp.BINARY_LESS)


# Make a binary less equals IR operation in the current label.
func make_binary_less_equals() -> void:
	make_op(IROp.BINARY_LESS_EQUALS)


# Make a binary and IR operation in the current label.
func make_binary_and() -> void:
	make_op(IROp.BINARY_AND)


# Make a binary or IR operation in the current label.
func make_binary_or() -> void:
	make_op(IROp.BINARY_OR)


# Make a show dialog IR operation in the current label.
func make_show_dialog() -> void:
	make_op(IROp.SHOW_DIALOG)


# Make a hide dialog IR operation in the current label.
func make_hide_dialog() -> void:
	make_op(IROp.HIDE_DIALOG)


# Make a clear dialog name IR operation in the current label.
func make_clear_dialog_name() -> void:
	make_op(IROp.CLEAR_DIALOG_NAME)


# Make a display dialog name IR operation in the current label.
func make_display_dialog_name() -> void:
	make_op(IROp.DISPLAY_DIALOG_NAME)


# Make a display dialog name text IR operation in the current label.
func make_display_dialog_name_text(text: String) -> void:
	make_op_str(IROp.DISPLAY_DIALOG_NAME_TEXT, text)


# Make a display dialog message IR operation in the current label.
func make_display_dialog_message() -> void:
	make_op(IROp.DISPLAY_DIALOG_MESSAGE)


# Make a display dialog message text IR operation in the current label.
func make_display_dialog_message_text(text: String) -> void:
	make_op_str(IROp.DISPLAY_DIALOG_MESSAGE_TEXT, text)


# Make a store dialog menu option label IR operation in the current label.
func make_store_dialog_menu_option_label(label: String) -> void:
	make_op_str(IROp.STORE_DIALOG_MENU_OPTION_LABEL, label)


# Make a store dialog menu option text label IR operation in the current label.
func make_store_dialog_menu_option_text_label(text: String, label: String) -> void:
	make_op_str_str(IROp.STORE_DIALOG_MENU_OPTION_TEXT_LABEL, text, label)


# Make a show dialog menu IR operation in the current label.
func make_show_dialog_menu() -> void:
	make_op(IROp.SHOW_DIALOG_MENU)


# Make an actor face direction IR operation in the current label.
func make_actor_face_direction() -> void:
	make_op(IROp.ACTOR_FACE_DIRECTION)


# Make an actor find path IR operation in the current label.
func make_actor_find_path() -> void:
	make_op(IROp.ACTOR_FIND_PATH)


# Make an actor find path key point IR operation in the current label.
func make_actor_find_path_key_point(key: String, point: String) -> void:
	make_op_str_str(IROp.ACTOR_FIND_PATH_KEY_POINT, key, point)


# Make a run actor paths IR operation in the current label.
func make_run_actor_paths() -> void:
	make_op(IROp.RUN_ACTOR_PATHS)


# Make an await actor paths IR operation in the current label.
func make_await_actor_paths() -> void:
	make_op(IROp.AWAIT_ACTOR_PATHS)


# Make a freeze player IR operation in the current label.
func make_freeze_player() -> void:
	make_op(IROp.FREEZE_PLAYER)


# Make a thaw player IR operation in the current label.
func make_thaw_player() -> void:
	make_op(IROp.THAW_PLAYER)


# Make a quit to title IR operation in the current label.
func make_quit_to_title() -> void:
	make_op(IROp.QUIT_TO_TITLE)


# Make a pause game IR operation in the current label.
func make_pause_game() -> void:
	make_op(IROp.PAUSE_GAME)


# Make an unpause game IR operation in the current label.
func make_unpause_game() -> void:
	make_op(IROp.UNPAUSE_GAME)


# Make a save game IR operation in the current label.
func make_save_game() -> void:
	make_op(IROp.SAVE_GAME)


# Make a save checkpoint IR operation in the current label.
func make_save_checkpoint() -> void:
	make_op(IROp.SAVE_CHECKPOINT)
