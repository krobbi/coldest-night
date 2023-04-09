extends MenuCard

# Font Menu Card
# The font menu card is a menu card that contains font settings.

@onready var _family_option: OptionMenuRow = (
		$CenterContainer/VBoxContainer/ScrollContainer/MenuList/FamilyOption)

# Run when the open custom fonts directory button is pressed. Open the custom
# fonts directory in the file browser.
func _on_open_custom_fonts_directory_button_pressed() -> void:
	if not DirAccess.dir_exists_absolute(DisplayManager.FONTS_DIR):
		if DirAccess.make_dir_absolute(DisplayManager.FONTS_DIR) != OK:
			return
	
	OS.shell_open(ProjectSettings.globalize_path(DisplayManager.FONTS_DIR))


# Run when the refresh custom fonts button is pressed. Refresh the available
# custom fonts.
func _on_refresh_custom_fonts_button_pressed() -> void:
	DisplayManager.refresh_custom_fonts()
	_family_option.refresh_options()
