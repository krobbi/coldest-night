class_name CheckboxMenuRow
extends MenuRow

# Checkbox Menu Row
# A checkbox menu row is a menu row that contains a checkbox control for a bool
# configuration value.

export(String) var _config_key: String

onready var _checkbox: CheckButton = $Content/CheckButton

# Virtual _ready method. Runs when the checkbox menu row enters the scene tree.
# Sets the checkbox's text and state:
func _ready() -> void:
	_checkbox.text = "CHECKBOX.%s" % _config_key.to_upper()
	_checkbox.set_pressed_no_signal(Global.config.get_bool(_config_key))
	Global.config.connect_bool(_config_key, _checkbox, "set_pressed_no_signal")


# Virtual _exit_tree method. Runs when the checkbox menu row exits the scene
# tree. Disconnects the connected configuration value from the checkbox's state:
func _exit_tree() -> void:
	Global.config.disconnect_value(_config_key, _checkbox, "set_pressed_no_signal")


# Signal callback for toggled on the checkbox. Runs when the checkbox is toggled
# Sets the connected configuration value:
func _on_checkbox_toggled(button_pressed: bool) -> void:
	Global.config.set_bool(_config_key, button_pressed)
	Global.audio.play_clip("sfx.menu_move" if button_pressed else "sfx.menu_cancel")
