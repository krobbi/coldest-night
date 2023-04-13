extends MenuCard

# The pause quit menu card is a fixed menu card that is displayed when the user
# quits from the pause menu.

@export_file("*.tscn") var _quit_scene_path: String

# Run when the quit to main menu button is pressed. Change to the quit scene.
func _on_quit_to_main_menu_button_pressed() -> void:
	SceneManager.change_scene_to_file(_quit_scene_path)
