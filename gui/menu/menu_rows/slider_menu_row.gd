class_name SliderMenuRow
extends MenuRow

# Slider Menu Row
# A slider menu row is a menu row that contains a slider.

signal value_changed(value: float)

@export var _slider_value: float = 0.0
@export var _min_value: float = 0.0
@export var _max_value: float = 100.0
@export var _step: float = 1.0
@export var _text: String

@onready var _label: Label = $Content/Label
@onready var _slider: HSlider = $Content/HSlider
@onready var _changed_player: AudioStreamPlayer = $ChangedPlayer

# Run when the slider menu row finishes entering the scene tree. Set the
# slider's values and text.
func _ready() -> void:
	_slider.min_value = _min_value
	_slider.max_value = _max_value
	_slider.step = _step
	set_value_no_signal(_slider_value)
	_label.text = _text


## Run when the slider menu row receives an input event. Debounce analog input.
func _input(event: InputEvent) -> void:
	if not _is_selected or not event is InputEventJoypadMotion:
		return
	
	if event.is_action("ui_left") or event.is_action("ui_right"):
		get_viewport().set_input_as_handled()
		
		if Input.is_action_just_pressed("ui_left"):
			_slider.value -= _step
		elif Input.is_action_just_pressed("ui_right"):
			_slider.value += _step


# Run when the slider menu row exits the scene tree. Disconnect the slider's
# `value_changed` signal from the slider menu row.
func _exit_tree() -> void:
	if _slider.value_changed.is_connected(_on_slider_value_changed):
		_slider.value_changed.disconnect(_on_slider_value_changed)


# Set the slider's value without emitting the `value_changed` signal.
func set_value_no_signal(value: float) -> void:
	if _slider.value_changed.is_connected(_on_slider_value_changed):
		_slider.value_changed.disconnect(_on_slider_value_changed)
	
	_slider.value = value
	
	if _slider.value_changed.connect(_on_slider_value_changed) != OK:
		if _slider.value_changed.is_connected(_on_slider_value_changed):
			_slider.value_changed.disconnect(_on_slider_value_changed)


# Run when the slider's value changes. Play the changed sound and emit the
# `value_changed` signal.
func _on_slider_value_changed(value: float) -> void:
	_changed_player.play()
	value_changed.emit(value)
