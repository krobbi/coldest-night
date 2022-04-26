class_name GameOverMenu
extends ColorRect

# Game Over Menu
# The game over menu is a menu that is displayed on game over and handles game
# over operations.

var _is_open: bool = false

onready var _menu_stack: MenuStack = $MenuStack

# Virtual _ready method. Runs when the game over menu finishes entering the
# scene tree. Connects the game over menu to the event bus:
func _ready() -> void:
	Global.events.safe_connect("game_over_request", self, "open_menu", [], CONNECT_ONESHOT)


# Virtual _exit_tree method. Runs when the game over menu exits the scene tree.
# Disconnects the game over menu from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("game_over_request", self, "open_menu")


# Opens the game over menu and handles game over operations:
func open_menu() -> void:
	if _is_open:
		return
	
	_is_open = true
	Global.events.emit_signal("player_freeze_request")
	Global.audio.play_music("game_over", false)
	show()
	var tween: SceneTreeTween = create_tween()
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(self, "modulate", Color.white, 4.5).set_trans(Tween.TRANS_SINE)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_callback(self, "_on_tween_callback")


# Tween callback for the game over menu's tween. Runs when the game over menu
# has finished appearing. Plays menu music and pushes the game over menu card to
# the menu stack:
func _on_tween_callback() -> void:
	Global.tree.paused = true
	Global.audio.play_music("menu")
	_menu_stack.push_card("game_over")
