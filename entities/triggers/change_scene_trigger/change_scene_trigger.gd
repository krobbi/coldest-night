extends Trigger

# Change Scene Trigger
# A change scene trigger is a trigger that changes the current scene when
# entered.

export(String, FILE, "*.tscn") var _scene_path: String

# Run when a the change scene trigger is entered. Change the current scene.
func _enter() -> void:
	EventBus.emit_player_transition_request()
	SceneManager.change_scene(_scene_path)
