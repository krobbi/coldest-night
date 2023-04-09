extends ColorRect

# Pause Menu
# The pause menu is a menu that is displayed when the game is paused.

var _is_open: bool = false

@onready var _paused_player: AudioStreamPlayer = $PausedPlayer
@onready var _menu_stack: MenuStack = $MenuStack

# Run when the pause menu finishes entering the scene tree. Set the pause menu's
# opacity and subscribe the pause menu to the configuration bus and event bus.
func _ready() -> void:
	ConfigBus.subscribe_node_float("accessibility.pause_opacity", _set_opacity)
	EventBus.subscribe_node(EventBus.pause_game_request, _open_menu)


# Set the pause menu's opacity.
func _set_opacity(value: float) -> void:
	if value < 30.0:
		ConfigBus.set_float("accessibility.pause_opacity", 30.0)
		return
	elif value > 100.0:
		ConfigBus.set_float("accessibility.pause_opacity", 100.0)
		return
	
	color.a = value * 0.01


# Open the pause menu.
func _open_menu() -> void:
	if _is_open:
		return
	
	_is_open = true
	get_tree().paused = true
	_menu_stack.push_card("pause")
	show()
	_paused_player.play()


# Run when the menu stack's root is popped. Close the menu.
func _on_menu_stack_root_popped() -> void:
	if not _is_open:
		return
	
	_is_open = false
	hide()
	_menu_stack.clear()
	get_tree().set_deferred("paused", false)
