extends MenuCard

# Main Menu Card
# The main menu card is a menu card that contains the main menu and its
# functionality.

@export_file("*.tscn") var _start_scene_path: String
@export_file("*.tscn") var _completed_scene_path: String
@export_file("*.tscn") var _credits_scene_path: String

# Start the game from the current working save data.
func _start_game() -> void:
	match SaveManager.get_working_data().state:
		SaveData.State.NEW_GAME:
			SaveManager.get_working_data().state = SaveData.State.NORMAL
			SaveManager.push_to_checkpoint()
			SceneManager.change_scene_to_file(_start_scene_path, true, false)
		SaveData.State.NORMAL:
			SceneManager.change_scene_to_file(_start_scene_path, true, false)
		SaveData.State.COMPLETED:
			SceneManager.change_scene_to_file(_completed_scene_path)


# Run when the continue game button is pressed. Pull from the slot save data and
# start the game.
func _on_continue_game_button_pressed() -> void:
	SaveManager.pull_from_slot()
	_start_game()


# Run when the new game button is pressed. Clear the current working save data
# and start the game.
func _on_new_game_button_pressed() -> void:
	SaveManager.get_working_data().clear()
	_start_game()


# Run when the credits button is pressed. Change to the credits scene.
func _on_credits_button_pressed() -> void:
	SceneManager.change_scene_to_file(_credits_scene_path)


# Run when the quit game button is pressed. Quit the game.
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
