class_name ControlsManager
extends Object

# Controls Manager
# The controls manager is a global utility that handles control mapping. It can
# be accessed from any script by using 'Global.controls'.

const DEFAULT_MAPPINGS: Dictionary = {
	"move_up": "key.%d" % KEY_UP,
	"move_down": "key.%d" % KEY_DOWN,
	"move_left": "key.%d" % KEY_LEFT,
	"move_right": "key.%d" % KEY_RIGHT,
	"interact": "key.%d" % KEY_Z,
	"pause": "key.%d" % KEY_ESCAPE,
	"toggle_fullscreen": "key.%d" % KEY_F11,
}

const ACTION_LINKS: Dictionary = {
	"move_up": "ui_up",
	"move_down": "ui_down",
	"move_left": "ui_left",
	"move_right": "ui_right",
	"interact": "ui_accept",
	"pause": "ui_cancel",
}

var _config: ConfigBus
var _mappings: Dictionary = DEFAULT_MAPPINGS.duplicate()
var _linked_actions: Dictionary = {
	"ui_up": null,
	"ui_down": null,
	"ui_left": null,
	"ui_right": null,
	"ui_accept": null,
	"ui_cancel": null,
}

# Constructor. Connects the controls manager's configuration values:
func _init(config_ref: ConfigBus) -> void:
	_config = config_ref
	reset_mappings()
	
	for action in DEFAULT_MAPPINGS:
		_config.connect_string(
				"controls.%s_mapping" % action, self, "_on_config_value_changed", [action]
		)


# Gets a human-readable name from a control mapping code:
func get_code_name(code: String) -> String:
	if code.begins_with("key."):
		return OS.get_scancode_string(int(code.substr(4)))
	elif code.begins_with("mouse_button."):
		match int(code.substr(13)):
			BUTTON_LEFT:
				return "INPUT.MOUSE_BUTTON.LEFT"
			BUTTON_RIGHT:
				return "INPUT.MOUSE_BUTTON.RIGHT"
			BUTTON_MIDDLE:
				return "INPUT.MOUSE_BUTTON.MIDDLE"
			BUTTON_XBUTTON1:
				return "INPUT.MOUSE_BUTTON.XBUTTON1"
			BUTTON_XBUTTON2:
				return "INPUT.MOUSE_BUTTON.XBUTTON2"
			BUTTON_WHEEL_UP:
				return "INPUT.MOUSE_BUTTON.WHEEL_UP"
			BUTTON_WHEEL_DOWN:
				return "INPUT.MOUSE_BUTTON.WHEEL_DOWN"
			BUTTON_WHEEL_LEFT:
				return "INPUT.MOUSE_BUTTON.WHEEL_LEFT"
			BUTTON_WHEEL_RIGHT:
				return "INPUT.MOUSE_BUTTON.WHEEL_RIGHT"
			_:
				return tr("INPUT.MOUSE_BUTTON.UNKNOWN").format({"button_index": code.substr(13)})
	elif code.begins_with("joypad_button."):
		return Input.get_joy_button_string(int(code.substr(14)))
	elif code.begins_with("joypad_motion."):
		var code_parts: PoolStringArray = code.substr(14).split(".", true, 1)
		
		if code_parts.size() != 2:
			return "INPUT.UNKNOWN"
		
		var string: String = Input.get_joy_axis_string(int(code_parts[0]))
		
		if code_parts[1] == "-":
			return tr("INPUT.JOYPAD_MOTION.NEGATIVE").format({"string": string})
		else:
			return tr("INPUT.JOYPAD_MOTION.POSITIVE").format({"string": string})
	else:
		return "INPUT.UNKNOWN"


# Gets a control mapping code from an input event:
func get_event_code(event: InputEvent) -> String:
	if event is InputEventKey:
		return "key.%d" % event.scancode
	elif event is InputEventMouseButton:
		return "mouse_button.%d" % event.button_index
	elif event is InputEventJoypadButton:
		return "joypad_button.%d" % event.button_index
	elif event is InputEventJoypadMotion:
		return "joypad_motion.%d.%s" % [event.axis, "+" if event.axis_value >= 0.0 else "-"]
	else:
		return ""


# Gets a human-readable name from a control mapping's action:
func get_mapping_name(action: String) -> String:
	return get_code_name(_mappings.get(action, ""))


# Gets whether an input event may be used as a control mapping:
func is_event_mappable(event: InputEvent) -> bool:
	if event is InputEventKey:
		return true
	elif event is InputEventMouseButton:
		match event.button_index:
			BUTTON_WHEEL_UP, BUTTON_WHEEL_DOWN, BUTTON_WHEEL_LEFT, BUTTON_WHEEL_RIGHT:
				return false
			_:
				return true
	elif event is InputEventJoypadButton:
		return event.pressure >= 0.5
	elif event is InputEventJoypadMotion:
		return abs(event.axis_value) >= 0.5
	else:
		return false


# Creates an input event from a control mapping code:
func create_event(code: String) -> InputEvent:
	if code.begins_with("key."):
		var event: InputEventKey = InputEventKey.new()
		event.scancode = int(code.substr(4))
		return event
	elif code.begins_with("mouse_button."):
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = int(code.substr(13))
		return event
	elif code.begins_with("joypad_button."):
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = int(code.substr(14))
		return event
	elif code.begins_with("joypad_motion."):
		var code_parts: PoolStringArray = code.substr(14).split(".", true, 1)
		
		if code_parts.size() != 2:
			return null
		
		var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
		event.axis = int(code_parts[0])
		event.axis_value = -1.0 if code_parts[1] == "-" else 1.0
		return event
	else:
		return null


# Changes a control mapping from its action and control mapping code:
func map_code(action: String, code: String, swap: bool = true) -> void:
	map_event(action, create_event(code), swap)


# Changes a control mapping from its action and input event:-
func map_event(action: String, event: InputEvent, swap: bool = true) -> void:
	if not DEFAULT_MAPPINGS.has(action) or not is_event_mappable(event):
		return
	
	var code: String = get_event_code(event)
	event = create_event(code)
	
	if not event:
		return
	
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	
	if ACTION_LINKS.has(action):
		_link_action(ACTION_LINKS[action], event)
	
	if swap:
		var old_code: String = _mappings[action]
		
		for other_action in DEFAULT_MAPPINGS:
			if other_action != action and _mappings[other_action] == code:
				map_code(other_action, old_code, false)
	
	_mappings[action] = code
	_config.set_string("controls.%s_mapping" % action, code)


# Resets all control mappings to their defaults:
func reset_mappings() -> void:
	for action in DEFAULT_MAPPINGS:
		map_code(action, DEFAULT_MAPPINGS[action])


# Destructor. Disconnects the controls manager's configuration values:
func destruct() -> void:
	for action in DEFAULT_MAPPINGS:
		_config.disconnect_value("controls.%s_mapping" % action, self, "_on_config_value_changed")
	
	_config.disconnect_value("controls.mouse_look", self, "set_mouse_look")


# Links an input event to a built-in action:
func _link_action(action: String, event: InputEvent) -> void:
	if not event or _linked_actions[action] == event:
		return
	
	if _linked_actions[action]:
		InputMap.action_erase_event(action, _linked_actions[action])
		_linked_actions[action] = null
	
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
		_linked_actions[action] = event


# Callback for the control manager's configuration values. Changes control
# mappings from their control mapping codes and actions:
func _on_config_value_changed(value: String, action: String) -> void:
	map_code(action, value)
