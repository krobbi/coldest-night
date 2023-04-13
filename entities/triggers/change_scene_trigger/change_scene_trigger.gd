extends Trigger

# Change Scene Trigger
# A change scene trigger is a trigger that changes the current scene when
# entered.

@export_file("*.tscn") var _scene_path: String

# Run when a the change scene trigger is entered. Change the current scene.
func _on_entered() -> void:
	EventBus.player_transition_request.emit()
	SceneManager.change_scene_to_file(_scene_path)
