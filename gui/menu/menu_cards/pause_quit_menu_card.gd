extends MenuCard

# The pause quit menu card is a fixed menu card that is displayed when the user
# quits to the main menu from the pause menu.

# Run when the quit to main menu button is pressed. Change to the menu scene.
func _on_quit_to_main_menu_button_pressed() -> void:
	Global.change_scene("menu")
