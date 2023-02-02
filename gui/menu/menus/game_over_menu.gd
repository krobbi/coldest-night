extends ColorRect

# Game Over Menu
# The game over menu is a menu that is displayed on game over and handles game
# over operations.

var _is_open: bool = false

onready var _menu_stack: MenuStack = $MenuStack

# Run when the game over menu finishes entering the scene tree. Subscribe the
# game over menu to the event bus.
func _ready() -> void:
	EventBus.subscribe_node("game_over_request", self, "open_menu", [], CONNECT_ONESHOT)


# Open the game over menu and handle game over operations.
func open_menu() -> void:
	if _is_open:
		return
	
	_is_open = true
	EventBus.emit_player_freeze_request()
	AudioManager.play_music("game_over", false)
	show()
	var tween: SceneTreeTween = create_tween()
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(self, "modulate", Color.white, 4.5).set_trans(Tween.TRANS_SINE)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_callback(self, "_on_tween_callback")


# Run when the game over menu has finished appearing. Play menu music and push
# the game over menu card to the menu stack.
func _on_tween_callback() -> void:
	get_tree().paused = true
	AudioManager.play_music("menu")
	_menu_stack.push_card("game_over")
