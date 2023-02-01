class_name ConfigCheckboxMenuRow
extends CheckboxMenuRow

# Configuration Checkbox Menu Row
# A configuration checkbox menu row is a checkbox menu row that sets a bool
# configuration value.

export(String) var config: String setget set_config

# Run when the configuration checkbox menu row finishes entering the scene tree.
# Set the checkbox's configuration value.
func _ready() -> void:
	set_config(config)


# Run when the configuration checkbox menu row exits the scene tree. Unsubscribe
# the configuration checkbox menu row from the configuration bus.
func _exit_tree() -> void:
	ConfigBus.unsubscribe(config, self, "set_pressed_no_signal")


# Run when the checkbox is toggled. Set the subscribed configuration value:
func _toggle(value: bool) -> void:
	ConfigBus.set_bool(config, value)


# Sets the checkbox's configuration value.
func set_config(value: String) -> void:
	ConfigBus.unsubscribe(config, self, "set_pressed_no_signal")
	config = value
	
	if _checkbox:
		set_pressed_no_signal(ConfigBus.get_bool(config, is_pressed))
		ConfigBus.subscribe_bool(config, self, "set_pressed_no_signal")
	
	set_text("CHECKBOX.%s" % config.to_upper())
	tooltip = "TOOLTIP.CHECKBOX.%s" % config.to_upper()
