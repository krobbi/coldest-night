extends Control

# Title Screen Scene
# The title screen scene is a scene that contains the game's logo and main menu.

# Virtual _ready method. Runs when the title screen scene is entered. Ensures
# the game is not paused and plays background music:
func _ready() -> void:
	Global.tree.paused = false
	Global.audio.play_music("menu")


# Signal callback for pressed on the continue game button. Runs when the
# continue game button is pressed. Loads the selected slot and changes to the
# loader scene:
func _on_continue_game_button_pressed() -> void:
	Global.save.load_slot()
	Global.change_scene("loader")


# Signal callback for pressed on the new game button. Runs when the new game
# button is pressed. Saves a new game and changes to the loader scene:
func _on_new_game_button_pressed() -> void:
	Global.save.save_new_game()
	Global.change_scene("loader")


# Signal callback for pressed on the settings button. Runs when the settings
# button is pressed. Changes to the settings scene:
func _on_settings_button_pressed() -> void:
	Global.change_scene("settings")


# Signal callback for pressed on the credits button. Runs when the credits
# button is pressed. Changes to the credits scene:
func _on_credits_button_pressed() -> void:
	Global.change_scene("credits")


# Signal callback for pressed on the quit game button. Runs when the quit game
# button is pressed. Quits the game:
func _on_quit_game_button_pressed() -> void:
	Global.quit()
