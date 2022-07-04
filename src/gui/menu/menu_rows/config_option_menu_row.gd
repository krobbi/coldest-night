class_name ConfigOptionMenuRow
extends OptionMenuRow

# Configuration Option Menu Row
# A configuration option menu row is an option menu row that sets a
# configuration value.

export(String) var config: String setget set_config

# Virtual _ready method. Runs when the configuration option menu row finishes
# entering the scene tree. Sets the option's configuration value:
func _ready() -> void:
	set_config(config)


# Virtual _exit_tree method. Runs when the configuration option menu row exits
# the scene tree. Disconnects the configuration option menu row from the
# configuration bus:
func _exit_tree() -> void:
	Global.config.disconnect_value(config, self, "set_value")


# Virtual _change_value method. Runs when the selected option's value is
# changed. Sets the connected configuration value:
func _change_value(value) -> void:
	Global.config.set_value(config, value)


# Sets the option's configuration value:
func set_config(value: String) -> void:
	Global.config.disconnect_value(config, self, "set_value")
	config = value
	
	if _button:
		set_value(Global.config.get_value(config), true)
		Global.config.connect_value(config, self, "set_value", TYPE_NIL, [true])
	
	set_text("OPTION.%s" % config.to_upper())
	tooltip = "TOOLTIP.OPTION.%s" % config.to_upper()
