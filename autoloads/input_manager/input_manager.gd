extends Node

# Input Manager
# The input manager is an autoload scene that manages input mapping. The input
# manager can be accessed from any script by using `InputManager`.

const DEFAULT_MAPPINGS: Dictionary = {
	"move_up": "key.%d" % KEY_UP,
	"move_down": "key.%d" % KEY_DOWN,
	"move_left": "key.%d" % KEY_LEFT,
	"move_right": "key.%d" % KEY_RIGHT,
	"interact": "key.%d" % KEY_Z,
	"pause": "key.%d" % KEY_ESCAPE,
	"toggle_fullscreen": "key.%d" % KEY_F11,
}

const LINKED_ACTIONS: Dictionary = {
	"move_up": "ui_up",
	"move_down": "ui_down",
	"move_left": "ui_left",
	"move_right": "ui_right",
	"interact": "ui_accept",
	"pause": "ui_cancel",
}

var _mappings: Dictionary = DEFAULT_MAPPINGS.duplicate()
var _linked_action_events: Dictionary = {}

# Run when the input manager enters the scene tree. Populate the linked input
# action events, initialize the default input action mappings, and connect the
# input manager to the configuration bus.
func _ready() -> void:
	for linked_action in LINKED_ACTIONS.values():
		_linked_action_events[linked_action] = null
	
	reset_mappings()
	
	for action in DEFAULT_MAPPINGS:
		Global.config.connect_string(
				"controls.%s_mapping" % action, self, "_on_config_changed", [action])


# Run when the input manager exits the scene tree. Disconnect the input manager
# from the configuration bus.
func _exit_tree() -> void:
	for action in DEFAULT_MAPPINGS:
		Global.config.disconnect_value("controls.%s_mapping" % action, self, "_on_config_changed")


# Get an input mapping code's human-readable name.
func get_code_name(code: String) -> String:
	var code_parts: PoolStringArray = code.split(".")
	
	if code_parts[0] == "key" and code_parts.size() == 2:
		return OS.get_scancode_string(int(code_parts[1]))
	elif code_parts[0] == "mouse_button" and code_parts.size() == 2:
		var button_index: int = int(code_parts[1])
		
		if button_index == BUTTON_LEFT:
			return "INPUT.MOUSE_BUTTON.LEFT"
		elif button_index == BUTTON_RIGHT:
			return "INPUT.MOUSE_BUTTON.RIGHT"
		elif button_index == BUTTON_MIDDLE:
			return "INPUT.MOUSE_BUTTON.MIDDLE"
		elif button_index == BUTTON_XBUTTON1:
			return "INPUT.MOUSE_BUTTON.XBUTTON1"
		elif button_index == BUTTON_XBUTTON2:
			return "INPUT.MOUSE_BUTTON.XBUTTON2"
		
		return tr("INPUT.MOUSE_BUTTON.UNKNOWN").format({"button_index": code_parts[1]})
	elif code_parts[0] == "joypad_button" and code_parts.size() == 2:
		return Input.get_joy_button_string(int(code_parts[1]))
	elif code_parts[0] == "joypad_motion" and code_parts.size() == 3:
		var axis: String = Input.get_joy_axis_string(int(code_parts[1]))
		
		if code_parts[2] == "positive":
			return tr("INPUT.JOYPAD_MOTION.POSITIVE").format({"axis": axis})
		elif code_parts[2] == "negative":
			return tr("INPUT.JOYPAD_MOTION.NEGATIVE").format({"axis": axis})
		
		return axis
	
	return "INPUT.UNKNOWN"


# Get an input action's mapping's human-readable name.
func get_mapping_name(action: String) -> String:
	return get_code_name(_mappings.get(action, ""))


# Get an input mapping code from an input event. Return `"auto"` if the input
# event cannot be used for input mapping.
func get_event_code(event: InputEvent) -> String:
	if event is InputEventKey:
		return "key.%d" % event.scancode
	elif event is InputEventMouseButton:
		return "mouse_button.%d" % event.button_index
	elif event is InputEventJoypadButton:
		return "joypad_button.%d" % event.button_index
	elif event is InputEventJoypadMotion:
		return "joypad_motion.%d.%s" % [
				event.axis, "positive" if event.axis_value >= 0.0 else "negative"]
	
	return "auto"


# Get whether an input event may be used to trigger an input mapping.
func is_event_mappable(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventJoypadButton:
		return true
	elif event is InputEventMouseButton:
		return not event.button_index in [
				BUTTON_WHEEL_UP, BUTTON_WHEEL_DOWN, BUTTON_WHEEL_LEFT, BUTTON_WHEEL_RIGHT]
	elif event is InputEventJoypadMotion:
		return abs(event.axis_value) >= 0.5
	
	return false


# Create an input event for input mapping from an input mapping code. Return
# `null` if the input mapping code is invalid.
func create_code_event(code: String) -> InputEvent:
	var code_parts: PoolStringArray = code.split(".")
	
	if code_parts[0] == "key" and code_parts.size() == 2:
		var event: InputEventKey = InputEventKey.new()
		event.scancode = int(code_parts[1])
		return event
	elif code_parts[0] == "mouse_button" and code_parts.size() == 2:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = int(code_parts[1])
		return event
	elif code_parts[0] == "joypad_button" and code_parts.size() == 2:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = int(code_parts[1])
		return event
	elif code_parts[0] == "joypad_motion" and code_parts.size() == 3:
		var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
		event.axis = int(code_parts[1])
		
		if code_parts[2] == "positive":
			event.axis_value = 1.0
		elif code_parts[2] == "negative":
			event.axis_value = -1.0
		else:
			return null
		
		return event
	
	return null


# Map an input action to an input mapping code.
func map_action_code(action: String, code: String, swap: bool = true) -> void:
	if code == "auto":
		code = DEFAULT_MAPPINGS[action]
	
	map_action_event(action, create_code_event(code), swap)


# Map an input action to an input event.
func map_action_event(action: String, event: InputEvent, swap: bool = true) -> void:
	if not DEFAULT_MAPPINGS.has(action) or not is_event_mappable(event):
		return
	
	var code: String = get_event_code(event)
	event = create_code_event(code) # Normalize event for input mapping.
	
	if not event:
		return
	
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	
	if LINKED_ACTIONS.has(action):
		var linked_action: String = LINKED_ACTIONS[action]
		
		if _linked_action_events[linked_action]:
			InputMap.action_erase_event(linked_action, _linked_action_events[linked_action])
			_linked_action_events[linked_action] = null
		
		if not InputMap.action_has_event(linked_action, event):
			InputMap.action_add_event(linked_action, event)
			_linked_action_events[linked_action] = event
	
	if swap:
		var previous_code: String = _mappings[action]
		
		for other_action in DEFAULT_MAPPINGS:
			if action == other_action or _mappings[other_action] != code:
				continue
			
			map_action_code(other_action, previous_code, false)
	
	_mappings[action] = code
	Global.config.set_string("controls.%s_mapping" % action, code)


# Reset all input action mappings to their defaults.
func reset_mappings() -> void:
	for action in DEFAULT_MAPPINGS:
		map_action_code(action, DEFAULT_MAPPINGS[action])


# Run when an input action's input mapping code changes in the configuration
# bus. Map the input action to the input mapping code.
func _on_config_changed(code: String, action: String) -> void:
	map_action_code(action, code)
