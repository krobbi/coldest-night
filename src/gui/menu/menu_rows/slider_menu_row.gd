class_name SliderMenuRow
extends MenuRow

# Slider Menu Row
# A slider menu row is a menu row that contains a slider control for a float
# configuration value.

export(String) var _config_key: String
export(float) var _min_value: float = 0.0
export(float) var _max_value: float = 100.0
export(float) var _step: float = 5.0

onready var _slider: HSlider = $Content/Slider

# Virtual _ready method. Runs when the slider menu row finishes entering the
# scene tree. Sets the slider's text and value:
func _ready() -> void:
	$Content/Label.text = "SLIDER.%s" % _config_key.to_upper()
	_slider.min_value = _min_value
	_slider.max_value = _max_value
	_slider.step = _step
	_set_value_no_signal(Global.config.get_float(_config_key, _min_value))
	Global.config.connect_float(_config_key, self, "_set_value_no_signal")


# Virtual _exit_tree method. Runs when the slider menu row exits the scene tree.
# Disconnects the connected configuration value from the slider's state and
# disconnects the slider's value changed signal:
func _exit_tree() -> void:
	Global.config.disconnect_value(_config_key, self, "_set_value_no_signal")
	if _slider.is_connected("value_changed", self, "_on_slider_value_changed"):
		_slider.disconnect("value_changed", self, "_on_slider_value_changed")


# Sets the slider's value without emitting a value changed signal:
func _set_value_no_signal(value: float) -> void:
	if _slider.is_connected("value_changed", self, "_on_slider_value_changed"):
		_slider.disconnect("value_changed", self, "_on_slider_value_changed")
	
	_slider.value = value
	var error: int = _slider.connect("value_changed", self, "_on_slider_value_changed")
	
	if error and _slider.is_connected("value_changed", self, "_on_slider_value_changed"):
		_slider.disconnect("value_changed", self, "_on_slider_value_changed")


# Signal callback for value_changed on the slider. Runs when the slider's value
# is changed. Sets the connected configuration value:
func _on_slider_value_changed(value: float) -> void:
	Global.config.set_float(_config_key, value)
	Global.audio.play_clip("sfx.menu_move")
