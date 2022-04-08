class_name PauseMenu
extends ColorRect

# Pause Menu
# The pause menu is a menu that is displayed when the game is paused.

onready var _menu_stack: MenuStack = $MenuStack

var _is_enabled: bool = true
var _is_open: bool = false

# Virtual _ready method. Runs when the pause menu finishes entering the scene
# tree. Connects the pause menu to the event bus:
func _ready() -> void:
	Global.events.safe_connect("player_freeze_request", self, "disable")
	Global.events.safe_connect("player_thaw_request", self, "enable")


# Virtual _input method. Runs when the pause menu receives an input event.
# Handles controls for toggling the pause menu:
func _input(event: InputEvent) -> void:
	if _is_enabled and event.is_action_pressed("pause"):
		if _is_open:
			close_menu()
		else:
			open_menu()


# Virtual _exit_tree method. Runs when the pause menu exits the scene tree.
# Disconnects the pause menu from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("player_freeze_request", self, "disable")
	Global.events.safe_disconnect("player_thaw_request", self, "enable")


# Enables the pause menu:
func enable() -> void:
	_is_enabled = true


# Disables the pause menu:
func disable() -> void:
	_is_enabled = false


# Opens the pause menu:
func open_menu() -> void:
	if _is_open:
		return
	
	_is_open = true
	Global.tree.paused = true
	show()
	Global.audio.play_clip("sfx.menu_move")
	_menu_stack.set_root("pause")


# Closes the pause menu:
func close_menu() -> void:
	if not _is_open:
		return
	
	_is_open = false
	Global.tree.paused = false
	hide()
	_menu_stack.clear()
	Global.audio.play_clip("sfx.menu_cancel")


# Signal callback for key_button_pressed on the menu stack. Runs when a key
# button is pressed. Performs pause menu actions:
func _on_menu_stack_key_button_pressed(button_key: String) -> void:
	match button_key:
		"pause.resume_game":
			close_menu()
		"pause.quick_save":
			Global.save.save_game()
		"pause.quick_load":
			Global.save.load_slot()
			Global.change_scene("loader")
		"pause.load_checkpoint":
			Global.save.load_checkpoint()
			Global.change_scene("loader")
		"pause.quit_to_title":
			Global.change_scene("title")
