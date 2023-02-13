extends MenuCard

# Game Over Menu Card
# The game over menu card is a fixed menu card that is the root menu card of the
# game over menu.

var _is_continuing: bool = false
var _save_data: SaveData = SaveManager.get_working_data()

# Run when the game over retry button is pressed. Pull from the checkpoint save
# data, increment the alert count, and change to the loader scene.
func _on_game_over_retry_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	SaveManager.pull_from_checkpoint()
	_save_data.stats.accumulate_alert_count()
	Global.change_scene("loader")


# Run when the quit to main menu button is pressed. Overwrite the current
# working save data with the slot save data while preserving the current
# statistics, increment the alert count, save the game, and change to the menu
# scene.
func _on_quit_to_main_menu_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	var stats_data: Dictionary = _save_data.stats.serialize()
	SaveManager.pull_from_slot()
	_save_data.stats.deserialize(stats_data)
	_save_data.stats.accumulate_alert_count()
	SaveManager.push_to_slot()
	SaveManager.save_file()
	Global.change_scene("menu")
