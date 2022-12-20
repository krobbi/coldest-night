class_name State
extends Node

# State Base
# A state is a state that can be processed by a state machine.

# Abstract _state_enter method. Runs when the state is entered:
func _state_enter() -> void:
	pass


# Abstract _state_process method. Runs when the state is processed:
func _state_process(_delta: float) -> void:
	pass


# Abstract _state_exit method. Runs when the state is exited:
func _state_exit() -> void:
	pass


# Enters the state:
func enter_state() -> void:
	_state_enter()


# Processes the state:
func process_state(delta: float) -> void:
	_state_process(delta)


# Exits the state:
func exit_state() -> void:
	_state_exit()
