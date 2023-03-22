class_name AwaitCutsceneAction
extends CutsceneAction

# Await Cutscene Action
# An await cutscene action is a cutscene action that finishes when a signal is
# received.

var _object: Object
var _signal_name: String
var _is_finished: bool = false

# Initialize the await cutscene action's object and signal name.
func _init(object_ref: Object, signal_name_val: String) -> void:
	_object = object_ref
	_signal_name = signal_name_val


# Run when the await cutscene action begins. Connect the object to the await
# cutscene action.
func begin() -> void:
	if not is_instance_valid(_object) or not _object.has_signal(_signal_name):
		_is_finished = true
		return
	
	if _object.connect(_signal_name, self, "_on_signal_received", [], CONNECT_ONESHOT) != OK:
		if _object.is_connected(_signal_name, self, "_on_signal_received"):
			_object.disconnect(_signal_name, self, "_on_signal_received")
		
		_is_finished = true


# Tick the await cutscene action and return whether it has finished.
func tick(_delta: float) -> bool:
	return _is_finished


# Run when the awaited signal is received. Mark the await cutscene action as
# finished.
func _on_signal_received() -> void:
	_is_finished = true
