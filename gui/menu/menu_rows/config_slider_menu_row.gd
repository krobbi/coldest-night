extends SliderMenuRow

# Configuration Slider Menu Row
# A configuration slider menu row is a slider menu row that sets a float
# configuration value.

@export var _config: String

# Run when the configuration slider menu row finishes entering the scene tree.
# Subscribe the configuration slider menu row to the configuration bus and set
# the configuration slider menu row's text and tooltip.
func _ready() -> void:
	_slider.min_value = _min_value
	_slider.max_value = _max_value
	_slider.step = _step
	ConfigBus.subscribe_node_float(_config, set_value_no_signal)
	_label.text = "SLIDER.%s" % _config.to_upper()
	tooltip = "TOOLTIP.SLIDER.%s" % _config.to_upper()


# Run when the slider's value changes. Set the subscribed configuration value.
func _on_value_changed(value: float) -> void:
	ConfigBus.set_float(_config, value)
