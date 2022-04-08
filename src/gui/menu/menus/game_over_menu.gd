class_name GameOverMenu
extends ColorRect

# Game Over Menu
# The game over menu is a menu that is displayed on game over and handles game
# over operations.

var _is_game_over: bool = false

onready var _tween: Tween = $Tween
onready var _menu_stack: MenuStack = $MenuStack

# Virtual _ready method. Runs when the game over menu finishes entering the
# scene tree. Connects the game over menu to the event bus:
func _ready() -> void:
	Global.events.safe_connect("game_over_request", self, "open_menu")


# Virtual _exit_tree method. Runs when the game over menu exits the scene tree.
# Disconnects the game over menu from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("game_over_request", self, "open_menu")


# Opens the game over menu and handles game over operations:
func open_menu() -> void:
	if _is_game_over:
		return
	
	_is_game_over = true
	Global.events.emit_signal("player_freeze_request")
	Global.audio.play_music("game_over", false)
	show()
	# warning-ignore: RETURN_VALUE_DISCARDED
	_tween.interpolate_property(self, "modulate", modulate, Color.white, 4.5)
	_tween.start() # warning-ignore: RETURN_VALUE_DISCARDED
	yield(_tween, "tween_all_completed")
	Global.tree.paused = true
	_menu_stack.set_root("game_over")
	Global.audio.play_music("menu")


# Signal callback for key_button_pressed on the menu stack. Runs when a key
# button is pressed. Performs pause menu actions:
func _on_menu_stack_key_button_pressed(button_key: String) -> void:
	_menu_stack.clear()
	var is_continue: bool = button_key == "game_over.game_over_continue"
	
	if is_continue:
		Global.save.load_checkpoint()
	else:
		Global.save.load_slot_checkpoint()
	
	Global.events.emit_signal("accumulate_alert_count_request")
	
	if is_continue:
		Global.change_scene("loader")
	else:
		Global.save.save_file()
		Global.change_scene("title")
