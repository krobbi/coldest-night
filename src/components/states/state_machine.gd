class_name StateMachine
extends Node

# State Machine
# A state machine is a component of an entity that handles processing a set of
# finite states.

signal state_changed(state_key)

export(String) var _initial_state: String

var _current_key: String = ""
var _next_key: String = ""
var _current_state: State = null

# Virtual _ready method. Runs when the state machine enters the scene tree.
# Changes to the initial state:
func _ready() -> void:
	change_state(_initial_state)


# Gets the state machine's current state key:
func get_key() -> String:
	return _current_key


# Changes the state machine's current state:
func change_state(state_key: String) -> void:
	if has_node(state_key) and get_node(state_key) is State:
		_next_key = state_key


# Processes the state machine's current state:
func process_state(delta: float) -> void:
	if _current_key != _next_key:
		if _current_state:
			_current_state.exit_state()
		
		_current_key = _next_key
		_current_state = get_node(_current_key)
		_current_state.enter_state()
		emit_signal("state_changed", _current_key)
	
	if _current_state:
		_current_state.process_state(delta)
