extends Trigger

# Change Scene Trigger
# A change scene trigger is a trigger that changes the current scene when
# entered.

export(String) var _scene_key: String

# Run when a the change scene trigger is entered. Change the current scene.
func _enter() -> void:
	EventBus.emit_player_transition_request()
	Global.change_scene(_scene_key)
