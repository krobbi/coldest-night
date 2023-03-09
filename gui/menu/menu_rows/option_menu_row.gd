class_name OptionMenuRow
extends MenuRow

# Option Menu Row
# An option menu row is a menu row that contains a set of options.

signal value_changed(value)

enum OptionSource {
	OPTIONS,
	ACCESSIBILITY_FONT,
	ACCESSIBILITY_COLOR_GRADING,
	DISPLAY_WINDOW_SCALE,
	DISPLAY_SCALE_MODE,
	LANGUAGE_LOCALE,
	RADAR_COLOR,
}

export(OptionSource) var option_source: int = OptionSource.OPTIONS setget set_option_source
export(Dictionary) var options: Dictionary = {} setget set_options
export(String) var text: String setget set_text

var _option_names: PoolStringArray = PoolStringArray()
var _option_values: Array = []
var _option_count: int = 0
var _selected_option: int = -1

onready var _label: Label = $Content/Label
onready var _button: Button = $Content/Button
onready var _previous_player: AudioStreamPlayer = $PreviousPlayer
onready var _next_player: AudioStreamPlayer = $NextPlayer

# Run when the option menu row finishes entering the scene tree. Set the
# option's values and text.
func _ready() -> void:
	refresh_options()
	set_options(options)
	set_text(text)


# Run when the option menu row receives an input event. Handle controls for
# selecting options if the option menu row is selected.
func _input(event: InputEvent) -> void:
	if is_selected:
		if event.is_action_pressed("ui_right", true):
			select_next()
		elif event.is_action_pressed("ui_left", true):
			select_previous()


# Run when the selected option's value is changed.
func _change_value(_value) -> void:
	pass


# Set the option's source.
func set_option_source(value: int) -> void:
	option_source = value
	
	if not _button:
		return
	
	match option_source:
		OptionSource.ACCESSIBILITY_FONT:
			set_options(DisplayManager.get_font_options())
		OptionSource.ACCESSIBILITY_COLOR_GRADING:
			set_options(ShaderManager.get_color_grading_options())
		OptionSource.DISPLAY_WINDOW_SCALE:
			set_options(DisplayManager.get_window_scale_options())
		OptionSource.DISPLAY_SCALE_MODE:
			set_options(DisplayManager.get_scale_mode_options())
		OptionSource.LANGUAGE_LOCALE:
			set_options(LangManager.get_locale_options())
		OptionSource.RADAR_COLOR:
			set_options(DisplayManager.get_color_options())
		OptionSource.OPTIONS, _:
			option_source = OptionSource.OPTIONS
			set_options(options)


# Set the option's options.
func set_options(value: Dictionary) -> void:
	var previous_value = get_value()
	options = value
	var option_keys: Array = options.keys()
	_option_names = PoolStringArray(option_keys)
	_option_count = option_keys.size()
	_option_values.resize(_option_count)
	
	for i in range(_option_count):
		_option_values[i] = options[option_keys[i]]
	
	if _button:
		set_value(previous_value, true)


# Set the option's text.
func set_text(value: String) -> void:
	text = value
	
	if _label:
		_label.text = text


# Set the selected option's value if an option with that value exists. Select
# the first option if no option is selected.
func set_value(value, no_signal: bool = false) -> void:
	for i in range(_option_count):
		var test_value = _option_values[i]
		
		if typeof(value) == typeof(test_value) and value == test_value:
			select_option(i, no_signal)
			return
	
	if _option_count == 0:
		_button.text = "OPTION.NONE"
	elif _selected_option >= 0 and _selected_option < _option_count:
		_button.text = _option_names[_selected_option]
	else:
		select_option(0, no_signal)


# Get the selected option's value. Return a default value if no option is
# selected.
func get_value(default = null):
	if _selected_option >= 0 and _selected_option < _option_count:
		return _option_values[_selected_option]
	else:
		return default


# Refresh the option's options.
func refresh_options() -> void:
	set_option_source(option_source)


# Select an option from its index and emits the value_changed signal.
func select_option(index: int, no_signal: bool = false) -> void:
	if _selected_option == index or index < 0 or index >= _option_count:
		return
	
	_selected_option = index
	_button.text = _option_names[_selected_option]
	
	if not no_signal:
		_change_value(_option_values[_selected_option])
		emit_signal("value_changed", _option_values[_selected_option])


# Select the previous option if there are multiple options.
func select_previous() -> void:
	if _option_count > 1:
		select_option((_selected_option - 1 + _option_count) % _option_count)
		_previous_player.play()


# Select the next option if there are multiple options.
func select_next() -> void:
	if _option_count > 1:
		select_option((_selected_option + 1) % _option_count)
		_next_player.play()
