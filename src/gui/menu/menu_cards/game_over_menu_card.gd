class_name GameOverMenuCard
extends MenuCard

# Game Over Menu Card
# The game over menu card is a fixed menu card that is the root menu card of the
# game over menu.

var _is_continuing: bool = false

# Signal callback for pressed on the game over retry button. Runs when the game
# over retry button is pressed. Loads the last checkpoint, increments the alert
# count, and changes to the loader scene:
func _on_game_over_retry_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	Global.save.load_checkpoint()
	Global.events.emit_signal("accumulate_alert_count_request")
	Global.change_scene("loader")


# Signal callback for pressed on the quit to main menu button. Runs when the
# quit to main menu button is pressed. Loads the selected save slot with the
# current statistics save data, increments the alert count, saves the game, and
# changes to the menu scene:
func _on_quit_to_main_menu_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	Global.save.load_slot_checkpoint()
	Global.events.emit_signal("accumulate_alert_count_request")
	Global.save.save_file()
	Global.change_scene("menu")
