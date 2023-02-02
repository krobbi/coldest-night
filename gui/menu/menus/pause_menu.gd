extends ColorRect

# Pause Menu
# The pause menu is a menu that is displayed when the game is paused.

var _is_open: bool = false
var _opacity: float = 80.0

onready var _menu_stack: MenuStack = $MenuStack

# Run when the pause menu finishes entering the scene tree. Subscribe the pause
# menu to the configuration bus and event bus.
func _ready() -> void:
	EventBus.subscribe_node("pause_game_request", self, "_open_menu")
	ConfigBus.subscribe_node_float("accessibility.pause_opacity", self, "_set_opacity")


# Set the pause menu's opacity.
func _set_opacity(value: float) -> void:
	if value < 0.0:
		value = 0.0
	elif value > 100.0 or is_inf(value) or is_nan(value):
		value = 100.0
	
	_opacity = value
	color.a = _opacity * 0.01


# Open the pause menu.
func _open_menu() -> void:
	if _is_open:
		return
	
	_is_open = true
	Global.tree.paused = true
	_menu_stack.push_card("pause")
	show()
	AudioManager.play_clip("sfx.menu_move")


# Run when the menu stack's root is popped. Close the menu.
func _on_menu_stack_root_popped() -> void:
	if not _is_open:
		return
	
	_is_open = false
	hide()
	_menu_stack.clear()
	Global.tree.set_deferred("paused", false)
