extends Reference

# IR Operation
# An IR operation is a structure used by the NightScript compiler that
# represents one or more NightScript operations.

enum {
	HALT,
	RUN_PROGRAM,
	CALL_PROGRAM,
	SLEEP,
	JUMP_LABEL,
	JUMP_ZERO_LABEL,
	JUMP_NOT_ZERO_LABEL,
	CALL_FUNCTION_LABEL,
	RETURN_FROM_FUNCTION,
	DROP,
	DUPLICATE,
	PUSH_IS_REPEAT,
	PUSH_INT,
	PUSH_STRING,
	LOAD_LOCAL_OFFSET,
	STORE_LOCAL_OFFSET,
	LOAD_FLAG,
	STORE_FLAG,
	UNARY_NEGATE,
	UNARY_NOT,
	BINARY_ADD,
	BINARY_SUBTRACT,
	BINARY_MULTIPLY,
	BINARY_EQUALS,
	BINARY_NOT_EQUALS,
	BINARY_GREATER,
	BINARY_GREATER_EQUALS,
	BINARY_LESS,
	BINARY_LESS_EQUALS,
	FORMAT_STRING_COUNT,
	SHOW_DIALOG,
	HIDE_DIALOG,
	CLEAR_DIALOG_NAME,
	DISPLAY_DIALOG_NAME,
	DISPLAY_DIALOG_MESSAGE,
	STORE_DIALOG_MENU_OPTION_LABEL,
	SHOW_DIALOG_MENU,
	ACTOR_FACE_DIRECTION,
	ACTOR_FIND_PATH,
	RUN_ACTOR_PATHS,
	AWAIT_ACTOR_PATHS,
	FREEZE_PLAYER,
	UNFREEZE_PLAYER,
	PAUSE_GAME,
	UNPAUSE_GAME,
	SAVE_GAME,
	SAVE_CHECKPOINT,
}

var type: int
var int_value: int = 0
var str_value: String = ""

# Set the IR operation's type.
func _init(type_val: int) -> void:
	type = type_val


# Copy another IR operation by value.
func copy(other: Reference) -> void:
	type = other.type
	int_value = other.int_value
	str_value = other.str_value


# Return the IR operation's string representation.
func _to_string() -> String:
	match type:
		HALT:
			return "halt;"
		RUN_PROGRAM:
			return "run_program;"
		CALL_PROGRAM:
			return "call_program;"
		SLEEP:
			return "sleep;"
		JUMP_LABEL:
			return "jump %s;" % str_value
		JUMP_ZERO_LABEL:
			return "jump_zero %s;" % str_value
		JUMP_NOT_ZERO_LABEL:
			return "jump_not_zero %s;" % str_value
		CALL_FUNCTION_LABEL:
			return "call_function %s;" % str_value
		RETURN_FROM_FUNCTION:
			return "return_from_function;"
		DROP:
			return "drop;"
		DUPLICATE:
			return "duplicate;"
		PUSH_IS_REPEAT:
			return "push_is_repeat;"
		PUSH_INT:
			return "push_int %d;" % int_value
		PUSH_STRING:
			return 'push_string "%s";' % str_value.c_escape()
		LOAD_LOCAL_OFFSET:
			return "load_local %d;" % int_value
		STORE_LOCAL_OFFSET:
			return "store_local %d;" % int_value
		LOAD_FLAG:
			return "load_flag;"
		STORE_FLAG:
			return "store_flag;"
		UNARY_NEGATE:
			return "unary_negate;"
		UNARY_NOT:
			return "unary_not;"
		BINARY_ADD:
			return "binary_add;"
		BINARY_SUBTRACT:
			return "binary_subtract;"
		BINARY_MULTIPLY:
			return "binary_multiply;"
		BINARY_EQUALS:
			return "binary_equals;"
		BINARY_NOT_EQUALS:
			return "binary_not_equals;"
		BINARY_GREATER:
			return "binary_greater;"
		BINARY_GREATER_EQUALS:
			return "binary_greater_equals;"
		BINARY_LESS:
			return "binary_less;"
		BINARY_LESS_EQUALS:
			return "binary_less_equals;"
		FORMAT_STRING_COUNT:
			return "format_string %d;" % int_value
		SHOW_DIALOG:
			return "show_dialog;"
		HIDE_DIALOG:
			return "hide_dialog;"
		CLEAR_DIALOG_NAME:
			return "clear_dialog_name;"
		DISPLAY_DIALOG_NAME:
			return "display_dialog_name;"
		DISPLAY_DIALOG_MESSAGE:
			return "display_dialog_message;"
		STORE_DIALOG_MENU_OPTION_LABEL:
			return "store_dialog_menu_option %s;" % str_value
		SHOW_DIALOG_MENU:
			return "show_dialog_menu;"
		ACTOR_FACE_DIRECTION:
			return "actor_face_direction;"
		ACTOR_FIND_PATH:
			return "actor_find_path;"
		RUN_ACTOR_PATHS:
			return "run_actor_paths;"
		AWAIT_ACTOR_PATHS:
			return "await_actor_paths;"
		FREEZE_PLAYER:
			return "freeze_player;"
		UNFREEZE_PLAYER:
			return "unfreeze_player;"
		PAUSE_GAME:
			return "pause_game;"
		UNPAUSE_GAME:
			return "unpause_game;"
		SAVE_GAME:
			return "save_game;"
		SAVE_CHECKPOINT:
			return "save_checkpoint;"
	
	return "// UNKNOWN: %d" % type
