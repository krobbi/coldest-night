class_name SleepCutsceneAction
extends CutsceneAction

# Sleep Cutscene Action
# A sleep cutscene action is a cutscene action that pauses a cutscene for a
# duration in seconds.

var _duration: float

# Initialize the sleep cutscene action's duration.
func _init(duration_val: float) -> void:
	_duration = duration_val


# Tick the sleep cutscene action and return whether is has finished.
func tick(delta: float) -> bool:
	_duration -= delta
	return _duration <= 0.0
