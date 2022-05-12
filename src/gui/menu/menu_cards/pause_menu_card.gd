class_name PauseMenuCard
extends MenuCard

# Pause Menu Card
# The pause menu card is a fixed menu card that is the root menu card of the
# pause menu.

# Signal callback for pressed on the quick save button. Runs when the quick save
# button is pressed. Saves the game's state to the selected save slot:
func _on_quick_save_button_pressed() -> void:
	Global.save.save_game()


# Signal callback for pressed on the quick load button. Runs when the quick load
# button is pressed. Loads the selected save slot and changes to the loader
# scene:
func _on_quick_load_button_pressed() -> void:
	Global.save.load_slot()
	Global.change_scene("loader")


# Signal callback for pressed on the load checkpoint button. Runs when the load
# checkpoint button is pressed. Loads the previously saved checkpoint and
# changes to the loader scene:
func _on_load_checkpoint_button_pressed() -> void:
	Global.save.load_checkpoint()
	Global.change_scene("loader")
