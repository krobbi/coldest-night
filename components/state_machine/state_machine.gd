class_name StateMachine
extends Node

# State Machine
# A state machine is a component of an entity that handles processing a set of
# finite states.

export(NodePath) var _main_state_path: NodePath

var _state: State

# Get the current state.
func get_state() -> State:
	return _state


# Get the current state's node name.
func get_state_name() -> String:
	return _state.name


# Initialize the state machine to its main state.
func init() -> void:
	_state = get_node(_main_state_path)
	_state.enter()


# Tick the state machine.
func tick(delta: float) -> void:
	change_state(_state.tick(delta))


# Forcibly change the current state.
func change_state(next_state: State) -> void:
	if _state == next_state:
		return
	
	_state.exit()
	_state = next_state
	_state.enter()


# Forcibly change the current state from its node name.
func change_state_name(next_state_name: String) -> void:
	if not has_node(next_state_name):
		return
	
	var next_state: Node = get_node(next_state_name)
	
	if next_state is State:
		change_state(next_state)
