extends MenuCard

# Pause Menu Card
# The pause menu card is a fixed menu card that is the root menu card of the
# pause menu.

@export_file("*.tscn") var _load_scene_path: String

# Run when the quick save button is pressed. Save the game.
func _on_quick_save_button_pressed() -> void:
	SaveManager.save_game()


# Run when the quick load button is pressed. Pull from the slot save data and
# reload the overworld scene.
func _on_quick_load_button_pressed() -> void:
	SaveManager.pull_from_slot()
	SceneManager.change_scene_to_file(_load_scene_path, true, false)


# Run when the load checkpoint button is pressed. Pull from the checkpoint save
# and reload the overworld scene.
func _on_load_checkpoint_button_pressed() -> void:
	SaveManager.pull_from_checkpoint()
	SceneManager.change_scene_to_file(_load_scene_path, true, false)
