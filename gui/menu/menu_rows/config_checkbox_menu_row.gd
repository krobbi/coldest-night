class_name ConfigCheckboxMenuRow
extends CheckboxMenuRow

# Configuration Checkbox Menu Row
# A configuration checkbox menu row is a checkbox menu row that sets a bool
# configuration value.

export(String) var config: String setget set_config

# Virtual _ready method. Runs when the configuration checkbox menu row finishes
# entering the scene tree. Sets the checkbox's configuration value:
func _ready() -> void:
	set_config(config)


# Virtual _exit_tree method. Runs when the configuration checkbox menu row exits
# the scene tree. Disconnects the configuration checkbox menu row from the
# configuration bus:
func _exit_tree() -> void:
	Global.config.disconnect_value(config, self, "set_pressed_no_signal")


# Virtual _toggle method. Runs when the checkbox is toggled. Sets the connected
# configuration value:
func _toggle(value: bool) -> void:
	Global.config.set_bool(config, value)


# Sets the checkbox's configuration value:
func set_config(value: String) -> void:
	Global.config.disconnect_value(config, self, "set_pressed_no_signal")
	config = value
	
	if _checkbox:
		set_pressed_no_signal(Global.config.get_bool(config, is_pressed))
		Global.config.connect_bool(config, self, "set_pressed_no_signal")
	
	set_text("CHECKBOX.%s" % config.to_upper())
	tooltip = "TOOLTIP.CHECKBOX.%s" % config.to_upper()
