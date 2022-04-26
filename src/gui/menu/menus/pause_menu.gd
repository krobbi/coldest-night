class_name PauseMenu
extends ColorRect

# Pause Menu
# The pause menu is a menu that is displayed when the game is paused.

var is_open: bool = false setget set_open
var opacity: float = 80.0 setget set_opacity

onready var _menu_stack: MenuStack = $MenuStack

# Virtual _ready method. Runs when the pause menu finishes entering the scene
# tree. Connects the pause menu to the event bus and configuration bus:
func _ready() -> void:
	Global.events.safe_connect("pause_menu_open_menu_request", self, "open_menu")
	Global.config.connect_float("accessibility.pause_opacity", self, "set_opacity")


# Virtual _exit_tree method. Runs when the pause menu exits the scene tree.
# Disconnects the pause menu from the event bus and configuration bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("pause_menu_open_menu_request", self, "open_menu")
	Global.config.disconnect_value("accessibility.pause_opacity", self, "set_opacity")


# Sets whether the pause menu is open:
func set_open(value: bool) -> void:
	if value:
		open_menu()
	else:
		close_menu()


# Sets the pause menu's opacity:
func set_opacity(value: float) -> void:
	if value < 0.0:
		value = 0.0
	elif value > 100.0 or is_inf(value) or is_nan(value):
		value = 100.0
	
	opacity = value
	color.a = opacity * 0.01


# Opens the pause menu:
func open_menu() -> void:
	if is_open:
		return
	
	is_open = true
	Global.tree.paused = true
	_menu_stack.push_card("pause")
	show()
	Global.audio.play_clip("sfx.menu_move")


# Closes the pause menu:
func close_menu() -> void:
	if not is_open:
		return
	
	is_open = false
	hide()
	_menu_stack.clear()
	Global.tree.set_deferred("paused", false)
