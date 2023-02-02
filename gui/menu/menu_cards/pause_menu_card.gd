extends MenuCard

# Pause Menu Card
# The pause menu card is a fixed menu card that is the root menu card of the
# pause menu.

# Run when the quick save button is pressed. Save the game's state to the
# selected save slot.
func _on_quick_save_button_pressed() -> void:
	SaveManager.save_game()


# Run when the quick load button is pressed. Load the selected save slot and
# change to the loader scene.
func _on_quick_load_button_pressed() -> void:
	SaveManager.load_slot()
	Global.change_scene("loader")


# Run when the load checkpoint button is pressed. Load the previously saved
# checkpoint and change to the loader scene.
func _on_load_checkpoint_button_pressed() -> void:
	SaveManager.load_checkpoint()
	Global.change_scene("loader")
