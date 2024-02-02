## Manages input mapping.
extends Node

## Emitted when input mappings are applied.
signal mappings_applied

## The map of action [String]s to their default mapping code [String]s.
const _DEFAULT_MAPPINGS: Dictionary = {
	"move_up": "key/%d" % KEY_UP,
	"move_down": "key/%d" % KEY_DOWN,
	"move_left": "key/%d" % KEY_LEFT,
	"move_right": "key/%d" % KEY_RIGHT,
	"interact": "key/%d" % KEY_Z,
	"pause": "key/%d" % KEY_ESCAPE,
	"toggle_fullscreen": "key/%d" % KEY_F11,
}

## The map of links from game action [String]s to built-in action [String]s.
const _ACTION_LINKS: Dictionary = {
	"move_up": "ui_up",
	"move_down": "ui_down",
	"move_left": "ui_left",
	"move_right": "ui_right",
	"interact": "ui_accept",
	"pause": "ui_cancel",
}

## The map of action [String]s to their current mapping code [String]s.
var _mappings: Dictionary = _DEFAULT_MAPPINGS.duplicate()

## The map of built-in action [String]s to their mapped [InputEvent]s.
var _linked_events: Dictionary = {}

## Run when the input manager is ready. Clear the linked [InputEvent]s and apply
## input mappings from config values.
func _ready() -> void:
	for action in _ACTION_LINKS.values():
		_linked_events[action] = null
	
	for action in _mappings:
		_map_action_code(action, ConfigBus.get_string("controls.%s_mapping" % action))
	
	_apply_mappings()


## Get an action [String]'s mapped input as a human-readable [String].
func get_mapping_name(action: String) -> String:
	if not action in _mappings:
		return tr("INPUT.NO_ACTION")
	
	var code_parts: PackedStringArray = _mappings[action].split("/")
	
	if code_parts[0] == "key" and code_parts.size() == 2:
		return OS.get_keycode_string(int(code_parts[1]))
	elif code_parts[0] == "mouse_button" and code_parts.size() == 2:
		var mouse_button: MouseButton = int(code_parts[1]) as MouseButton
		
		match mouse_button:
			MOUSE_BUTTON_LEFT:
				return tr("INPUT.MOUSE_BUTTON.LEFT")
			MOUSE_BUTTON_RIGHT:
				return tr("INPUT.MOUSE_BUTTON.RIGHT")
			MOUSE_BUTTON_MIDDLE:
				return tr("INPUT.MOUSE_BUTTON.MIDDLE")
			MOUSE_BUTTON_WHEEL_UP:
				return tr("INPUT.MOUSE_BUTTON.WHEEL_UP")
			MOUSE_BUTTON_WHEEL_DOWN:
				return tr("INPUT.MOUSE_BUTTON.WHEEL_DOWN")
			MOUSE_BUTTON_WHEEL_LEFT:
				return tr("INPUT.MOUSE_BUTTON.WHEEL_LEFT")
			MOUSE_BUTTON_WHEEL_RIGHT:
				return tr("INPUT.MOUSE_BUTTON.WHEEL_RIGHT")
			MOUSE_BUTTON_XBUTTON1:
				return tr("INPUT.MOUSE_BUTTON.XBUTTON1")
			MOUSE_BUTTON_XBUTTON2:
				return tr("INPUT.MOUSE_BUTTON.XBUTTON2")
			_:
				return tr("INPUT.MOUSE_BUTTON.UNKNOWN").format({"index": mouse_button})
	elif code_parts[0] == "joypad_button" and code_parts.size() == 2:
		var joy_button: JoyButton = int(code_parts[1]) as JoyButton
		
		match joy_button:
			JOY_BUTTON_A:
				return tr("INPUT.JOYPAD_BUTTON.A")
			JOY_BUTTON_B:
				return tr("INPUT.JOYPAD_BUTTON.B")
			JOY_BUTTON_X:
				return tr("INPUT.JOYPAD_BUTTON.X")
			JOY_BUTTON_Y:
				return tr("INPUT.JOYPAD_BUTTON.Y")
			JOY_BUTTON_BACK:
				return tr("INPUT.JOYPAD_BUTTON.BACK")
			JOY_BUTTON_GUIDE:
				return tr("INPUT.JOYPAD_BUTTON.GUIDE")
			JOY_BUTTON_START:
				return tr("INPUT.JOYPAD_BUTTON.START")
			JOY_BUTTON_LEFT_STICK:
				return tr("INPUT.JOYPAD_BUTTON.LEFT_STICK")
			JOY_BUTTON_RIGHT_STICK:
				return tr("INPUT.JOYPAD_BUTTON.RIGHT_STICK")
			JOY_BUTTON_LEFT_SHOULDER:
				return tr("INPUT.JOYPAD_BUTTON.LEFT_SHOULDER")
			JOY_BUTTON_RIGHT_SHOULDER:
				return tr("INPUT.JOYPAD_BUTTON.RIGHT_SHOULDER")
			JOY_BUTTON_DPAD_UP:
				return tr("INPUT.JOYPAD_BUTTON.DPAD_UP")
			JOY_BUTTON_DPAD_DOWN:
				return tr("INPUT.JOYPAD_BUTTON.DPAD_DOWN")
			JOY_BUTTON_DPAD_LEFT:
				return tr("INPUT.JOYPAD_BUTTON.DPAD_LEFT")
			JOY_BUTTON_DPAD_RIGHT:
				return tr("INPUT.JOYPAD_BUTTON.DPAD_RIGHT")
			JOY_BUTTON_MISC1:
				return tr("INPUT.JOYPAD_BUTTON.MISC1")
			JOY_BUTTON_PADDLE1:
				return tr("INPUT.JOYPAD_BUTTON.PADDLE1")
			JOY_BUTTON_PADDLE2:
				return tr("INPUT.JOYPAD_BUTTON.PADDLE2")
			JOY_BUTTON_PADDLE3:
				return tr("INPUT.JOYPAD_BUTTON.PADDLE3")
			JOY_BUTTON_PADDLE4:
				return tr("INPUT.JOYPAD_BUTTON.PADDLE4")
			JOY_BUTTON_TOUCHPAD:
				return tr("INPUT.JOYPAD_BUTTON.TOUCHPAD")
			_:
				return tr("INPUT.JOYPAD_BUTTON.UNKNOWN").format({"index": joy_button})
	elif code_parts[0] == "joypad_motion" and code_parts.size() == 3:
		var joy_axis: JoyAxis = int(code_parts[1]) as JoyAxis
		var direction: String = code_parts[2]
		
		if direction != "positive" and direction != "negative":
			return tr("INPUT.UNKNOWN")
		
		direction = direction.to_upper()
		
		match joy_axis:
			JOY_AXIS_LEFT_X:
				return tr("INPUT.JOYPAD_MOTION.LEFT_X.%s" % direction)
			JOY_AXIS_LEFT_Y:
				return tr("INPUT.JOYPAD_MOTION.LEFT_Y.%s" % direction)
			JOY_AXIS_RIGHT_X:
				return tr("INPUT.JOYPAD_MOTION.RIGHT_X.%s" % direction)
			JOY_AXIS_RIGHT_Y:
				return tr("INPUT.JOYPAD_MOTION.RIGHT_Y.%s" % direction)
			JOY_AXIS_TRIGGER_LEFT:
				return tr("INPUT.JOYPAD_MOTION.TRIGGER_LEFT.%s" % direction)
			JOY_AXIS_TRIGGER_RIGHT:
				return tr("INPUT.JOYPAD_MOTION.TRIGGER_RIGHT.%s" % direction)
			_:
				return tr("INPUT.JOYPAD_MOTION.UNKNOWN.%s" % direction).format({"index": joy_axis})
	
	return tr("INPUT.UNKNOWN")


## Reset all input mappings to their defaults.
func reset_mappings() -> void:
	_mappings = _DEFAULT_MAPPINGS.duplicate()
	_apply_mappings()


## Attempt to map an action [String] to an [InputEvent] and return whether it
## was successful.
func map_action_event(action: String, event: InputEvent) -> bool:
	if action in _mappings and _is_event_mappable(event):
		_map_action_code(action, _get_event_code(event))
		_apply_mappings()
		return true
	else:
		return false


## Get a mapping code [String]'s [InputEvent]. Return [code]null[/code] if
## [param code] is not a valid mapping code.
func _get_code_event(code: String) -> InputEvent:
	var code_parts: PackedStringArray = code.split("/")
	
	if code_parts[0] == "key" and code_parts.size() == 2:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = int(code_parts[1]) as Key
		return event
	elif code_parts[0] == "mouse_button" and code_parts.size() == 2:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = int(code_parts[1]) as MouseButton
		return event
	elif code_parts[0] == "joypad_button" and code_parts.size() == 2:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = int(code_parts[1]) as JoyButton
		return event
	elif code_parts[0] == "joypad_motion" and code_parts.size() == 3:
		var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
		event.axis = int(code_parts[1]) as JoyAxis
		
		if code_parts[2] == "positive":
			event.axis_value = 1.0
		elif code_parts[2] == "negative":
			event.axis_value = -1.0
		else:
			return null
		
		return event
	
	return null


## Get an [InputEvent]'s mapping code [String]. Return an empty [String] if
## [param event] is not mappable.
func _get_event_code(event: InputEvent) -> String:
	if event is InputEventKey:
		return "key/%d" % event.physical_keycode
	elif event is InputEventMouseButton:
		return "mouse_button/%d" % event.button_index
	elif event is InputEventJoypadButton:
		return "joypad_button/%d" % event.button_index
	elif event is InputEventJoypadMotion:
		if event.axis_value >= 0.5:
			return "joypad_motion/%d/positive" % event.axis
		elif event.axis_value <= -0.5:
			return "joypad_motion/%d/negative" % event.axis
	
	return ""


## Return whether an [InputEvent] can be used for input mapping.
func _is_event_mappable(event: InputEvent) -> bool:
	return not _get_event_code(event).is_empty()


## Normalize an input mapping code [String]. Return [param action]'s default
## mapping code if [param code] is not a valid mapping code.
func _normalize_code(action: String, code: String) -> String:
	var event: InputEvent = _get_code_event(code)
	
	if not event:
		event = _get_code_event(_DEFAULT_MAPPINGS.get(action, _DEFAULT_MAPPINGS.interact))
	
	return _get_event_code(event)


## Map an action [String] to a mapping code [String].
func _map_action_code(action: String, code: String) -> void:
	code = _normalize_code(action, code)
	
	for other_action in _mappings:
		if other_action != action and _mappings[other_action] == code:
			_mappings[other_action] = _mappings[action]
			break
	
	_mappings[action] = code


## Apply the current input mappings. Emit [signal mappings_applied].
func _apply_mappings() -> void:
	for action in _mappings:
		var code: String = _mappings[action]
		var event: InputEvent = _get_code_event(code)
		
		if not event:
			continue
		
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		
		if action in _ACTION_LINKS:
			var linked_action: String = _ACTION_LINKS[action]
			
			if _linked_events[linked_action]:
				InputMap.action_erase_event(linked_action, _linked_events[linked_action])
				_linked_events[linked_action] = null
			
			if not InputMap.action_has_event(linked_action, event):
				InputMap.action_add_event(linked_action, event)
				_linked_events[linked_action] = event
		
		ConfigBus.set_string("controls.%s_mapping" % action, code)
	
	mappings_applied.emit()
