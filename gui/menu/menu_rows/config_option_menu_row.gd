class_name ConfigOptionMenuRow
extends OptionMenuRow

# Configuration Option Menu Row
# A configuration option menu row is an option menu row that sets a
# configuration value.

export(String) var config: String setget set_config

# Run when the configuration option menu row finishes entering the scene tree.
# Set the option's configuration value.
func _ready() -> void:
	set_config(config)


# Run when the configuration option menu row exits the scene tree. Unsubscribe
# the configuration option menu row from the configuration bus.
func _exit_tree() -> void:
	ConfigBus.unsubscribe(config, self, "set_value")


# Run when the selected option's value is changed. Set the subscribed
# configuration value.
func _change_value(value) -> void:
	ConfigBus.set_value(config, value)


# Set the option's configuration value.
func set_config(value: String) -> void:
	ConfigBus.unsubscribe(config, self, "set_value")
	config = value
	
	if _button:
		ConfigBus.subscribe(config, self, "set_value", TYPE_NIL, [true])
	
	set_text("OPTION.%s" % config.to_upper())
	tooltip = "TOOLTIP.OPTION.%s" % config.to_upper()
