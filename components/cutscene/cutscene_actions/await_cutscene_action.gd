class_name AwaitCutsceneAction
extends CutsceneAction

# Await Cutscene Action
# An await cutscene action is a cutscene action that finishes when a signal is
# received.

var _awaited_signal: Signal
var _is_finished: bool = false

# Initialize the await cutscene action's awaited signal.
func _init(awaited_signal_ref: Signal) -> void:
	_awaited_signal = awaited_signal_ref


# Run when the await cutscene action begins. Connect the awaited signal to the
# await cutscene action.
func begin() -> void:
	if _awaited_signal.is_null():
		_is_finished = true
		return
	
	if _awaited_signal.connect(_on_signal_received, CONNECT_ONE_SHOT) != OK:
		if _awaited_signal.is_connected(_on_signal_received):
			_awaited_signal.disconnect(_on_signal_received)
		
		_is_finished = true


# Tick the await cutscene action and return whether it has finished.
func tick(_delta: float) -> bool:
	return _is_finished


# Run when the awaited signal is received. Mark the await cutscene action as
# finished.
func _on_signal_received() -> void:
	_is_finished = true
