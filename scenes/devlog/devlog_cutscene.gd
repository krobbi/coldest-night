extends Cutscene

# Devlog Cutscene
# The devlog cutscene is the cutscene that runs the devlog.

export(String, FILE, "*.tscn") var _end_scene_path: String

# Run when the devlog cutscene ends. Exit the devlog scene.
func end() -> void:
	SceneManager.change_scene(_end_scene_path)
