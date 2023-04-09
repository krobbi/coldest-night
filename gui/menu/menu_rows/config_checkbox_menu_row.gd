extends CheckboxMenuRow

# Configuration Checkbox Menu Row
# A configuration checkbox menu row is a checkbox menu row that sets a bool
# configuration value.

@export var _config: String

# Run when the configuration checkbox menu row finishes entering the scene tree.
# Subscribe the configuration checkbox menu row to the configuration bus and set
# the checkbox configuration menu row's text and tooltip.
func _ready() -> void:
	ConfigBus.subscribe_node_bool(_config, _checkbox.set_pressed_no_signal)
	_checkbox.text = "CHECKBOX.%s" % _config.to_upper()
	tooltip = "TOOLTIP.CHECKBOX.%s" % _config.to_upper()


# Run when the checkbox is toggled. Set the subscribed configuration value.
func _on_toggled(value: bool) -> void:
	ConfigBus.set_bool(_config, value)
