class_name ConfigSliderMenuRow
extends SliderMenuRow

# Configuration Slider Menu Row
# A configuration slider menu row is a slider menu row that sets a float
# configuration value.

export(String) var config: String setget set_config

# Run when the configuration slider menu row finishes entering the scene tree.
# Set the slider's configuration value.
func _ready() -> void:
	set_config(config)


# Run when the configuration slider menu row exits the scene tree. Unsubscribe
# the configuration slider menu row from the configuration bus.
func _exit_tree() -> void:
	ConfigBus.unsubscribe(config, self, "set_value_no_signal")


# Run when the slider's value is changed. Set the subscribed configuration
# value.
func _change_value(value: float) -> void:
	ConfigBus.set_float(config, value)


# Set the slider's configuration value.
func set_config(value: String) -> void:
	ConfigBus.unsubscribe(config, self, "set_value_no_signal")
	config = value
	
	if _slider:
		set_value_no_signal(ConfigBus.get_float(config, slider_value))
		ConfigBus.subscribe_float(config, self, "set_value_no_signal")
	
	set_text("SLIDER.%s" % config.to_upper())
	tooltip = "TOOLTIP.SLIDER.%s" % config.to_upper()
