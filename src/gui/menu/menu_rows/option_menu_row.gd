class_name OptionMenuRow
extends MenuRow

# Option Menu Row
# An option menu row is a menu row that contains an options control for a
# configuration value.

enum OptionSource {OPTIONS, WINDOW_SCALE, LOCALE}

export(String) var _config_key: String
export(OptionSource) var _option_source: int = OptionSource.OPTIONS
export(Dictionary) var _options: Dictionary

var _option_values: Array
var _option_count: int
var _selected_option: int = -1

onready var _button: Button = $Content/Button

# Virtual _ready method. Runs when the option menu row finishes entering the
# scene tree. Sets the option's text and state:
func _ready() -> void:
	$Content/Label.text = "OPTION.%s" % _config_key.to_upper()
	
	match _option_source:
		OptionSource.WINDOW_SCALE:
			_options = Global.display.get_window_scale_options()
		OptionSource.LOCALE:
			_options = Global.lang.get_locale_options()
	
	_option_values = _options.keys()
	_option_count = _option_values.size()
	
	_select_value(Global.config.get_value(_config_key))
	Global.config.connect_value(_config_key, self, "_select_value")


# Virtual _input event. Runs when the option menu row receives an input event.
# Handles controls for selecting the previous and next options:
func _input(event: InputEvent) -> void:
	if not is_selected():
		return
	elif event.is_action_pressed("ui_left", true):
		_select_previous()
	elif event.is_action_pressed("ui_right", true):
		_select_next()


# Virtual _exit_tree method. Runs when the option menu row exits the scene tree.
# Disconnects the connected configuration value from the option's state:
func _exit_tree() -> void:
	Global.config.disconnect_value(_config_key, self, "_select_value")


# Selects an option from its option index and sets the connected configuration
# value:
func _select_option(option_index: int) -> void:
	if _selected_option == option_index or option_index < 0 or option_index > _option_count:
		return
	
	if _selected_option != -1:
		Global.audio.play_clip("sfx.menu_move")
	
	_selected_option = option_index
	_button.text = _options[_option_values[_selected_option]]
	Global.config.set_value(_config_key, _option_values[_selected_option])


# Selects an option from its option value:
func _select_value(option_value) -> void:
	for i in range(_option_count):
		if typeof(_option_values[i]) == typeof(option_value) and _option_values[i] == option_value:
			_select_option(i)
			return


# Selects the previous option:
func _select_previous() -> void:
	if _option_count > 1:
		_select_option((_selected_option - 1 + _option_count) % _option_count)


# Selects the next option:
func _select_next() -> void:
	if _option_count > 1:
		_select_option((_selected_option + 1) % _option_count)


# Signal callback for pressed on the button. Runs when the button is pressed.
# Selects the next option:
func _on_button_pressed() -> void:
	_select_next()
