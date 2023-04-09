class_name CallCutsceneAction
extends CutsceneAction

# Call Cutscene Action
# A call cutscene action is a cutscene action that calls a callable.

var _callable: Callable

# Initialize the call cutscene action's callable.
func _init(callable_ref: Callable) -> void:
	_callable = callable_ref


# Run when the call cutscene action begins. Call the callable if it is valid.
func begin() -> void:
	if _callable.is_valid():
		_callable.call()
