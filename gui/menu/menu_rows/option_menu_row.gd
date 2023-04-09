class_name OptionMenuRow
extends MenuRow

# Option Menu Row
# An option menu row is a menu row that contains a set of options.

signal value_changed(value: Variant)

enum OptionSource {COLOR, COLOR_GRADING, FONT_FAMILY, LOCALE, WINDOW_SCALE}

@export var _option_source: OptionSource = OptionSource.COLOR
@export var _text: String

var _option_names: PackedStringArray = PackedStringArray()
var _option_values: Array[Variant] = []
var _option_count: int = 0
var _selected_option: int = -1

@onready var _label: Label = $Content/Label
@onready var _button: Button = $Content/Button
@onready var _previous_player: AudioStreamPlayer = $PreviousPlayer
@onready var _next_player: AudioStreamPlayer = $NextPlayer

# Run when the option menu row finishes entering the scene tree. Set the
# option's values and text.
func _ready() -> void:
	refresh_options()
	_label.text = _text


# Run when the option menu row receives an input event. Handle controls for
# selecting options with the keyboard if the option menu row is selected.
func _input(event: InputEvent) -> void:
	if _is_selected:
		if event.is_action_pressed("ui_left", true):
			_select_previous()
		elif event.is_action_pressed("ui_right", true):
			_select_next()


# Refresh the option's options.
func refresh_options() -> void:
	var options: Dictionary = {}
	
	match _option_source:
		OptionSource.COLOR:
			options = DisplayManager.get_color_options()
		OptionSource.COLOR_GRADING:
			options = ShaderManager.get_color_grading_options()
		OptionSource.FONT_FAMILY:
			options = DisplayManager.get_font_options()
		OptionSource.LOCALE:
			options = LangManager.get_locale_options()
		OptionSource.WINDOW_SCALE:
			options = DisplayManager.get_window_scale_options()
	
	var previous_value: Variant = null
	
	if _selected_option >= 0 and _selected_option < _option_count:
		previous_value = _option_values[_selected_option]
	
	_option_names = PackedStringArray(options.keys())
	_option_count = _option_names.size()
	_option_values.resize(_option_count)
	
	for index in range(_option_count):
		_option_values[index] = options.get(_option_names[index])
	
	_refresh_value(previous_value)


# Refresh the selected option from its value without emitting the
# `value_changed` signal.
func _refresh_value(value: Variant) -> void:
	_selected_option = 0
	
	for index in range(_option_count):
		if is_same(value, _option_values[index]):
			_selected_option = index
			break
	
	if _selected_option >= 0 and _selected_option < _option_count:
		_button.text = _option_names[_selected_option]
	else:
		_button.text = "OPTION.NONE"


# Select an option from its index and emit the `value_changed` signal.
func _select_option(index: int) -> void:
	_selected_option = index
	_button.text = _option_names[_selected_option]
	value_changed.emit(_option_values[_selected_option])


# Play the previous sound and select the previous option if there is more than
# one option.
func _select_previous() -> void:
	if _option_count > 1:
		_previous_player.play()
		_select_option((_selected_option - 1 + _option_count) % _option_count)


# Play the next sound and select the next option if there is more than one
# option.
func _select_next() -> void:
	if _option_count > 1:
		_next_player.play()
		_select_option((_selected_option + 1) % _option_count)
