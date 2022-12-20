extends Reference

# IR Operation
# An IR operation is a structure used by the NightScript compiler that
# represents one or more NightScript operations.

enum {
	HALT,
	RUN_PROGRAM,
	RUN_PROGRAM_KEY,
	CALL_PROGRAM,
	CALL_PROGRAM_KEY,
	SLEEP,
	JUMP_LABEL,
	JUMP_ZERO_LABEL,
	JUMP_NOT_ZERO_LABEL,
	DROP,
	DUPLICATE,
	PUSH_IS_REPEAT,
	PUSH_INT,
	PUSH_STRING,
	LOAD_FLAG_NAMESPACE_KEY,
	STORE_FLAG_NAMESPACE_KEY,
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
	BINARY_AND,
	BINARY_OR,
	SHOW_DIALOG,
	HIDE_DIALOG,
	CLEAR_DIALOG_NAME,
	DISPLAY_DIALOG_NAME,
	DISPLAY_DIALOG_NAME_TEXT,
	DISPLAY_DIALOG_MESSAGE,
	DISPLAY_DIALOG_MESSAGE_TEXT,
	STORE_DIALOG_MENU_OPTION_LABEL,
	STORE_DIALOG_MENU_OPTION_TEXT_LABEL,
	SHOW_DIALOG_MENU,
	ACTOR_FACE_DIRECTION,
	ACTOR_FIND_PATH,
	ACTOR_FIND_PATH_KEY_POINT,
	RUN_ACTOR_PATHS,
	AWAIT_ACTOR_PATHS,
	FREEZE_PLAYER,
	THAW_PLAYER,
	QUIT_TO_TITLE,
	PAUSE_GAME,
	UNPAUSE_GAME,
	SAVE_GAME,
	SAVE_CHECKPOINT,
}

var type: int
var int_value_a: int = 0
var str_value_a: String = ""
var str_value_b: String = ""

# Set the IR operation's type.
func _init(type_val: int) -> void:
	type = type_val


# Return the IR operation's string representation.
func _to_string() -> String:
	match type:
		HALT:
			return "halt;"
		RUN_PROGRAM:
			return "run_program;"
		RUN_PROGRAM_KEY:
			return 'run_program "%s";' % str_value_a.c_escape()
		CALL_PROGRAM:
			return "call_program;"
		CALL_PROGRAM_KEY:
			return 'call_program "%s";' % str_value_a.c_escape()
		SLEEP:
			return "sleep;"
		JUMP_LABEL:
			return "jump %s;" % str_value_a
		JUMP_ZERO_LABEL:
			return "jump_zero %s;" % str_value_a
		JUMP_NOT_ZERO_LABEL:
			return "jump_not_zero %s;" % str_value_a
		DROP:
			return "drop;"
		DUPLICATE:
			return "duplicate;"
		PUSH_IS_REPEAT:
			return "push_is_repeat;"
		PUSH_INT:
			return "push_int %d;" % int_value_a
		PUSH_STRING:
			return 'push_string "%s";' % str_value_a.c_escape()
		LOAD_FLAG_NAMESPACE_KEY:
			return "load_flag %s.%s;" % [str_value_a, str_value_b]
		STORE_FLAG_NAMESPACE_KEY:
			return "store_flag %s.%s;" % [str_value_a, str_value_b]
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
		BINARY_AND:
			return "binary_and;"
		BINARY_OR:
			return "binary_or;"
		SHOW_DIALOG:
			return "show_dialog;"
		HIDE_DIALOG:
			return "hide_dialog;"
		CLEAR_DIALOG_NAME:
			return "clear_dialog_name;"
		DISPLAY_DIALOG_NAME:
			return "display_dialog_name;"
		DISPLAY_DIALOG_NAME_TEXT:
			return 'display_dialog_name "%s";' % str_value_a.c_escape()
		DISPLAY_DIALOG_MESSAGE:
			return "display_dialog_message;"
		DISPLAY_DIALOG_MESSAGE_TEXT:
			return 'display_dialog_message "%s";' % str_value_a.c_escape()
		STORE_DIALOG_MENU_OPTION_LABEL:
			return "store_dialog_menu_option %s;" % str_value_a
		STORE_DIALOG_MENU_OPTION_TEXT_LABEL:
			return 'store_dialog_menu_option "%s" %s;' % [str_value_a.c_escape(), str_value_b]
		SHOW_DIALOG_MENU:
			return "show_dialog_menu;"
		ACTOR_FACE_DIRECTION:
			return "actor_face_direction;"
		ACTOR_FIND_PATH:
			return "actor_find_path;"
		ACTOR_FIND_PATH_KEY_POINT:
			return 'actor_find_path %s "%s";' % [str_value_a, str_value_b.c_escape()]
		RUN_ACTOR_PATHS:
			return "run_actor_paths;"
		AWAIT_ACTOR_PATHS:
			return "await_actor_paths;"
		FREEZE_PLAYER:
			return "freeze_player;"
		THAW_PLAYER:
			return "thaw_player;"
		QUIT_TO_TITLE:
			return "quit_to_title;"
		PAUSE_GAME:
			return "pause_game;"
		UNPAUSE_GAME:
			return "unpause_game;"
		SAVE_GAME:
			return "save_game;"
		SAVE_CHECKPOINT:
			return "save_checkpoint;"
	
	return "// UNKNOWN: %d" % type


# Get the IR operation's size in native NightScript operations.
func get_size() -> int:
	if type in [
			RUN_PROGRAM_KEY, CALL_PROGRAM_KEY, JUMP_LABEL, JUMP_ZERO_LABEL, JUMP_NOT_ZERO_LABEL,
			DISPLAY_DIALOG_NAME_TEXT, DISPLAY_DIALOG_MESSAGE_TEXT, STORE_DIALOG_MENU_OPTION_LABEL]:
		return 2
	elif type in [
			LOAD_FLAG_NAMESPACE_KEY, STORE_FLAG_NAMESPACE_KEY,
			STORE_DIALOG_MENU_OPTION_TEXT_LABEL, ACTOR_FIND_PATH_KEY_POINT]:
		return 3
	
	return 1
