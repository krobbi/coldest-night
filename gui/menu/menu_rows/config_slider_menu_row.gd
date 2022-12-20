class_name ConfigSliderMenuRow
extends SliderMenuRow

# Configuration Slider Menu Row
# A configuration slider menu row is a slider menu row that sets a float
# configuration value.

export(String) var config: String setget set_config

# Virtual _ready method. Runs when the configuration slider menu row finishes
# entering the scene tree. Sets the slider's configuration value:
func _ready() -> void:
	set_config(config)


# Virtual _exit_tree method. Runs when the configuration slider menu row exits
# the scene tree. Disconnects the configuration slider menu row from the
# configuration bus:
func _exit_tree() -> void:
	Global.config.disconnect_value(config, self, "set_value_no_signal")


# Virtual _change_value method. Runs when the slider's value is changed. Sets
# the connected configuration value:
func _change_value(value: float) -> void:
	Global.config.set_float(config, value)


# Sets the slider's configuration value:
func set_config(value: String) -> void:
	Global.config.disconnect_value(config, self, "set_value_no_signal")
	config = value
	
	if _slider:
		set_value_no_signal(Global.config.get_float(config, slider_value))
		Global.config.connect_float(config, self, "set_value_no_signal")
	
	set_text("SLIDER.%s" % config.to_upper())
	tooltip = "TOOLTIP.SLIDER.%s" % config.to_upper()

