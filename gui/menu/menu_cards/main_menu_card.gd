extends MenuCard

# Main Menu Card
# The main menu card is a menu card that contains the main menu and its
# functionality.

# Run when the continue game button is pressed. Load the selected save slot and
# change to the loader scene.
func _on_continue_game_button_pressed() -> void:
	SaveManager.load_slot()
	Global.change_scene("loader")


# Run when the new game button is pressed. Save a new game and change to the
# loader scene.
func _on_new_game_button_pressed() -> void:
	SaveManager.save_new_game()
	Global.change_scene("loader")


# Runs when the credits button is pressed. Change to the credits scene.
func _on_credits_button_pressed() -> void:
	Global.change_scene("credits")


# Run when the devlog button is pressed. Change to the devlog scene.
func _on_devlog_button_pressed() -> void:
	Global.change_scene("devlog")


# Run when the quit game button is pressed. Quit the game.
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
