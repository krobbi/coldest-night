class_name CutsceneAction
extends RefCounted

# Cutscene Action
# A cutscene action is a component of a cutscene that runs an asynchronous
# action.

# Run when the cutscene action begins.
func begin() -> void:
	pass


# Tick the cutscene action and return whether it has finished.
func tick(_delta: float) -> bool:
	return true


# Run when the cutscene action ends.
func end() -> void:
	pass
