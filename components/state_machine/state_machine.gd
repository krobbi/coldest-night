class_name StateMachine
extends Node

# State Machine
# A state machine is a component of an entity that handles processing a set of
# finite states.

@export var _state: State

# Get the current state.
func get_state() -> State:
	return _state


# Enter the state machine's main state.
func init() -> void:
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
