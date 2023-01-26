extends MenuCard

# Game Over Menu Card
# The game over menu card is a fixed menu card that is the root menu card of the
# game over menu.

var _is_continuing: bool = false
var _save_data: SaveData = Global.save.get_working_data()

# Run when the game over retry button is pressed. Load the last checkpoint,
# increment the alert count, and change to the loader scene.
func _on_game_over_retry_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	Global.save.load_checkpoint()
	_save_data.stats.accumulate_alert_count()
	Global.change_scene("loader")


# Run when the quit to main menu button is pressed. Overwrite the current
# working save data with the selected slot's save data while preserving the
# current statistics, increment the alert count, save the game, and change to
# the menu scene.
func _on_quit_to_main_menu_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	Global.save.load_slot_checkpoint()
	_save_data.stats.accumulate_alert_count()
	Global.save.save_file()
	Global.change_scene("menu")
