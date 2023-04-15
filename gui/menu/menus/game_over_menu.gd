extends ColorRect

# Game Over Menu
# The game over menu is a menu that is displayed on game over and handles game
# over operations.

@export var _game_over_music: AudioStream
@export var _menu_music: AudioStream

var _is_open: bool = false

@onready var _menu_stack: MenuStack = $MenuStack

# Run when the game over menu finishes entering the scene tree. Subscribe the
# game over menu to the event bus.
func _ready() -> void:
	EventBus.subscribe_node(EventBus.game_over_request, open_menu, CONNECT_ONE_SHOT)


# Open the game over menu and handle game over operations.
func open_menu() -> void:
	if _is_open:
		return
	
	_is_open = true
	EventBus.player_push_freeze_state_request.emit()
	AudioManager.play_music(_game_over_music, false)
	show()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 4.5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_on_tween_callback)


# Run when the game over menu has finished appearing. Play menu music and push
# the game over menu card to the menu stack.
func _on_tween_callback() -> void:
	get_tree().paused = true
	AudioManager.play_music(_menu_music)
	_menu_stack.push_card("game_over")
