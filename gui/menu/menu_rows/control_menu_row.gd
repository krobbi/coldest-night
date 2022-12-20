class_name ControlMenuRow
extends MenuRow

# Control Menu Row
# A control menu row is a menu row that contains a button for changing a control
# mapping.

export(String) var action: String setget set_action

var is_awaiting_input: bool = false setget set_awaiting_input

onready var _label: Label = $Content/Label
onready var _button: Button = $Content/Button
onready var _input_timer: Timer = $InputTimer

# Virtual _ready method. Runs when the control menu row finishes entering the
# scene tree. Sets the control button's action:
func _ready() -> void:
	set_action(action)


# Virtual _input method. Runs when the control menu row receives an input event.
# Handles changing the control mapping if the control button is awaiting an
# input and a mappable input event is received:
func _input(event: InputEvent) -> void:
	if not is_awaiting_input or not Global.controls.is_event_mappable(event):
		return
	
	Global.tree.set_input_as_handled() # Don't do anything else with the input.
	Global.controls.map_event(action, event)
	set_awaiting_input(false)
	Global.audio.play_clip("sfx.menu_ok")


# Virtual _exit_tree method. Runs when the control menu row exits the scene
# tree. Disconnects the control menu row from the configuration bus:
func _exit_tree() -> void:
	Global.config.disconnect_value("controls.%s_mapping" % action, self, "_on_config_value_changed")


# Virtual _deselect method. Runs when the control menu row is deselected. Stops
# awaiting an input:
func _deselect() -> void:
	set_awaiting_input(false)


# Sets the control button's action:
func set_action(value: String) -> void:
	Global.config.disconnect_value("controls.%s_mapping" % action, self, "_on_config_value_changed")
	action = value
	Global.config.connect_string("controls.%s_mapping" % action, self, "_on_config_value_changed")
	
	if _label:
		_label.text = "CONTROL.ACTION.%s" % action.to_upper()
		set_awaiting_input(false)
	
	tooltip = "TOOLTIP.CONTROL.%s" % action.to_upper()


# Sets whether the control button is awaiting an input:
func set_awaiting_input(value: bool) -> void:
	if value:
		for other in Global.tree.get_nodes_in_group("control_menu_rows"):
			if self != other:
				other.is_awaiting_input = false
		
		is_awaiting_input = true
		_button.set_pressed_no_signal(true)
		_button.text = "CONTROL.WAIT"
		_input_timer.start()
	else:
		is_awaiting_input = false
		_input_timer.stop()
		_button.set_pressed_no_signal(false)
		_button.text = Global.controls.get_mapping_name(action)


# Callback for the connected configuration value. Runs when the control button's
# control mapping is changed. Stops awaiting an input:
func _on_config_value_changed(_value: String) -> void:
	set_awaiting_input(false)


# Signal callback for timeout on the input timer. Runs when the input timer
# times out. Stops awaiting an input:
func _on_input_timer_timeout() -> void:
	set_awaiting_input(false)
