class_name State
extends Node

# State
# A state is a component of a state machine that can be ticked and return a
# state to transition to.

# Run when the state is entered.
func enter() -> void:
	pass


# Tick the state and return the state to transition to. Return self if the state
# should not change.
func tick(_delta: float) -> State:
	return self


# Run when the state is exited.
func exit() -> void:
	pass
