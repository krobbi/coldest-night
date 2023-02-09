extends MenuCard

# Font Menu Card
# The font menu card is a menu card that contains font settings.

onready var _font_option: OptionMenuRow = (
		$CenterContainer/VBoxContainer/ScrollContainer/MenuList/FontOption)

# Run when the open custom fonts directory button is pressed. Open the custom
# fonts directory in the file browser.
func _on_open_custom_fonts_directory_button_pressed() -> void:
	# warning-ignore: RETURN_VALUE_DISCARDED
	OS.shell_open(ProjectSettings.globalize_path(DisplayManager.FONTS_DIR))


# Run when the refresh custom fonts button is pressed. Refresh the custom fonts,
# the custom fonts option menu row, and the font configuration value.
func _on_refresh_custom_fonts_button_pressed() -> void:
	var previous_font: String = ConfigBus.get_string("accessibility.font", "coldnight")
	ConfigBus.set_string("accessibility.font", "coldnight")
	
	DisplayManager.refresh_custom_fonts()
	_font_option.refresh_options()
	
	ConfigBus.set_string("accessibility.font", previous_font)
