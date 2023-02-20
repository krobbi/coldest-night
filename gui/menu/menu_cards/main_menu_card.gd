extends MenuCard

# Main Menu Card
# The main menu card is a menu card that contains the main menu and its
# functionality.

export(String, FILE, "*.tscn") var _loader_scene_path: String
export(String, FILE, "*.tscn") var _credits_scene_path: String
export(String, FILE, "*.tscn") var _devlog_scene_path: String

# Run when the continue game button is pressed. Pull from the slot save data and
# change to the loader scene.
func _on_continue_game_button_pressed() -> void:
	SaveManager.pull_from_slot()
	SceneManager.change_scene(_loader_scene_path)


# Run when the new game button is pressed. Clear the current working save data,
# push it to the slot save data, and change to the loader scene.
func _on_new_game_button_pressed() -> void:
	SaveManager.get_working_data().clear()
	SaveManager.push_to_slot()
	SceneManager.change_scene(_loader_scene_path)


# Run when the credits button is pressed. Change to the credits scene.
func _on_credits_button_pressed() -> void:
	SceneManager.change_scene(_credits_scene_path)


# Run when the devlog button is pressed. Change to the devlog scene.
func _on_devlog_button_pressed() -> void:
	SceneManager.change_scene(_devlog_scene_path)


# Run when the quit game button is pressed. Quit the game.
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
