class_name SliderMenuRow
extends MenuRow

# Slider Menu Row
# A slider menu row is a menu row that contains a slider.

signal value_changed(value)

export(float) var slider_value: float = 0.0 setget set_value
export(float) var min_value: float = 0.0 setget set_min_value
export(float) var max_value: float = 100.0 setget set_max_value
export(float) var step: float = 1.0 setget set_step
export(String) var text: String setget set_text

onready var _label: Label = $Content/Label
onready var _slider: HSlider = $Content/HSlider
onready var _changed_player: AudioStreamPlayer = $ChangedPlayer

# Run when the slider menu row finishes entering the scene tree. Set the
# slider's values and text.
func _ready() -> void:
	set_min_value(min_value)
	set_max_value(max_value)
	set_step(step)
	set_value_no_signal(slider_value)
	set_text(text)


# Run when the slider menu row exits the scene tree. Disconnect the slider's
# `value_changed` signal from the slider menu row.
func _exit_tree() -> void:
	if _slider.is_connected("value_changed", self, "_on_slider_value_changed"):
		_slider.disconnect("value_changed", self, "_on_slider_value_changed")


# Run when the slider's value is changed.
func _change_value(_value: float) -> void:
	pass


# Set the slider's value.
func set_value(value: float) -> void:
	slider_value = value
	
	if _slider:
		_slider.value = slider_value


# Set the slider's value without emitting the `value_changed` signal.
func set_value_no_signal(value: float) -> void:
	slider_value = value
	
	if _slider.is_connected("value_changed", self, "_on_slider_value_changed"):
		_slider.disconnect("value_changed", self, "_on_slider_value_changed")
	
	_slider.value = slider_value
	var error: int = _slider.connect("value_changed", self, "_on_slider_value_changed")
	
	if error and _slider.is_connected("value_changed", self, "_on_slider_value_changed"):
		_slider.disconnect("value_changed", self, "_on_slider_value_changed")


# Set the slider's minimum value.
func set_min_value(value: float) -> void:
	min_value = value
	
	if _slider:
		_slider.min_value = min_value


# Set the slider's maximum value.
func set_max_value(value: float) -> void:
	max_value = value
	
	if _slider:
		_slider.max_value = max_value


# Set the slider's step.
func set_step(value: float) -> void:
	step = value
	
	if _slider:
		_slider.step = step


# Set the slider's text.
func set_text(value: String) -> void:
	text = value
	
	if _label:
		_label.text = text


# Run when the slider's value changes. Emit the `value_changed` signal.
func _on_slider_value_changed(value: float) -> void:
	_change_value(value)
	_changed_player.play()
	emit_signal("value_changed", value)
