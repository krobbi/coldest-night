extends MenuRow

# Control Menu Row
# A control menu row is a menu row that contains a button for changing an input
# mapping.

export(String) var _action: String

var _is_awaiting_input: bool = false

onready var _button: Button = $Content/Button
onready var _input_timer: Timer = $InputTimer

# Run when the control menu row finishes entering the scene tree. Subscribe the
# control menu row to the configuration bus and set its tooltip and text.
func _ready() -> void:
	ConfigBus.subscribe_node_string(
			"controls.%s_mapping" % _action, self, "_on_config_value_changed")
	tooltip = "TOOLTIP.CONTROL.%s" % _action.to_upper()
	$Content/Label.text = "CONTROL.ACTION.%s" % _action.to_upper()


# Run when the control menu row receives an input event. Change the control menu
# row's action input mapping if the control button is awaiting an input and a
# mappable input event is received.
func _input(event: InputEvent) -> void:
	if not _is_awaiting_input or not InputManager.is_event_mappable(event):
		return
	
	get_tree().set_input_as_handled() # Don't do anything else with the input.
	InputManager.map_action_event(_action, event)
	set_awaiting_input(false)
	AudioManager.play_clip("sfx.menu_ok")


# Run when the control menu row is deselected. Stop awaiting an input.
func _deselect() -> void:
	set_awaiting_input(false)


# Set whether the control button is awaiting an input.
func set_awaiting_input(value: bool) -> void:
	if value:
		for other in get_tree().get_nodes_in_group("control_menu_rows"):
			if self != other:
				other.set_awaiting_input(false)
		
		_is_awaiting_input = true
		_button.set_pressed_no_signal(true)
		_button.text = "CONTROL.WAIT"
		_input_timer.start()
	else:
		_is_awaiting_input = false
		_input_timer.stop()
		_button.set_pressed_no_signal(false)
		_button.text = InputManager.get_mapping_name(_action)


# Runs when the control menu row's input action input mapping is changed. Stop
# awaiting an input.
func _on_config_value_changed(_value: String) -> void:
	set_awaiting_input(false)


# Run when the input timer times out. Stop awaiting an input.
func _on_input_timer_timeout() -> void:
	set_awaiting_input(false)
