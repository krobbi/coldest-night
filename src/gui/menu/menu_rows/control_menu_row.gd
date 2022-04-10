extends MenuRow

# Control Menu Row
# A control menu row is a menu row that contains a control mapping control.

export(String) var _action: String

var _is_awaiting_input: bool = false

onready var _button: Button = $Content/Button
onready var _input_timer: Timer = $InputTimer

# Virtual _ready method. Runs when the control menu row finishes entering the
# scene tree. Sets the control menu row's text and state:
func _ready() -> void:
	$Content/Label.text = "CONTROL.ACTION.%s" % _action.to_upper()
	set_awaiting_input(false)
	Global.config.connect_string("controls.%s_mapping" % _action, self, "_on_config_value_changed")


# Virtual _input method. Runs when the control menu row receives an input event.
# Handles changing controls if the control menu row is awaiting an input and a
# key is pressed:
func _input(event: InputEvent) -> void:
	if not _is_awaiting_input or not Global.controls.is_event_mappable(event):
		return
	
	Global.tree.set_input_as_handled() # Don't do anything else with the input.
	Global.controls.map_event(_action, event)
	set_awaiting_input(false)
	Global.audio.play_clip("sfx.menu_ok")


# Virtual _exit_tree method. Runs when the control menu row exits the scene
# tree. Disconnects the connected configuration value from the control's state:
func _exit_tree() -> void:
	Global.config.disconnect_value(
			"controls.%s_mapping" % _action, self, "_on_config_value_changed"
	)


# Virtual _deselect method. Runs when the control menu row is deselected. Stops
# awaiting an input:
func _deselect() -> void:
	_input_timer.stop()
	set_awaiting_input(false)


# Sets whether the control menu row is awaiting an input:
func set_awaiting_input(value: bool) -> void:
	if value:
		for other in Global.tree.get_nodes_in_group("control_menu_rows"):
			if other != self:
				other.set_awaiting_input(false)
		
		_is_awaiting_input = true
		_button.set_pressed_no_signal(true)
		_button.text = "CONTROL.WAIT"
		_input_timer.start()
	else:
		_is_awaiting_input = false
		_input_timer.stop()
		_button.set_pressed_no_signal(false)
		_button.text = Global.controls.get_mapping_name(_action)


# Callback for the connected configuration value. Sets the control menu row's
# state:
func _on_config_value_changed(_value: String) -> void:
	set_awaiting_input(false)


# Signal callback for toggled on the control menu row's button. Sets the control
# menu row's state:
func _on_button_toggled(button_pressed: bool) -> void:
	set_awaiting_input(button_pressed)


# Signal callback for timeout on the input timer. Stops awaiting an input:
func _on_input_timer_timeout() -> void:
	set_awaiting_input(false)
