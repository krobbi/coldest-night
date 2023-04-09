class_name ConfigOptionMenuRow
extends OptionMenuRow

# Configuration Option Menu Row
# A configuration option menu row is an option menu row that sets a
# configuration value.

@export var _config: String

# Run when the configuration option menu row finishes entering the scene tree.
# Connect the configuration option menu row to the configuration bus and set the
# configuration option menu row's text and tooltip.
func _ready() -> void:
	refresh_options()
	ConfigBus.subscribe_node(_config, _refresh_value)
	_label.text = "OPTION.%s" % _config.to_upper()
	tooltip = "TOOLTIP.OPTION.%s" % _config.to_upper()


# Run when the selected option's value changes. Set the subscribed configuration
# value.
func _on_value_changed(value: Variant) -> void:
	ConfigBus.set_value(_config, value)
