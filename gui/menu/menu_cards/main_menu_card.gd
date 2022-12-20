class_name MainMenuCard
extends MenuCard

# Main Menu Card
# The main menu card is a menu card that contains the main menu and its
# functionality.

# Signal callback for pressed on the continue game button. Runs when the
# continue game button is pressed. Loads the selected save slot and changes to
# the loader scene:
func _on_continue_game_button_pressed() -> void:
	Global.save.load_slot()
	Global.change_scene("loader")


# Signal callback for pressed on the new game button. Runs when the new game
# button is pressed. Saves a new game and changes to the loader scene:
func _on_new_game_button_pressed() -> void:
	Global.save.save_new_game()
	Global.change_scene("loader")


# Signal callback for pressed on the credits button. Runs when the credits
# button is pressed. Changes to the credits scene:
func _on_credits_button_pressed() -> void:
	Global.change_scene("credits")


# Signal callback for pressed on the devlog button. Runs when the devlog button
# is pressed. Changes to the devlog scene:
func _on_devlog_button_pressed() -> void:
	Global.change_scene("devlog")


# Signal callback for pressed on the quit game button. Runs when the quit game
# button is pressed. Quits the game:
func _on_quit_game_button_pressed() -> void:
	Global.tree.quit()
