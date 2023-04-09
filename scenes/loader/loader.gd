extends Control

# Loader Scene
# The loader scene is a scene that loads the game from the current working save
# data.

@export var _normal_scene_path: String # (String, FILE, "*.tscn")
@export var _completed_scene_path: String # (String, FILE, "*.tscn")

@onready var _new_game_cutscene: Cutscene = $NewGameCutscene

# Run when the loader scene is entered. Run the new game cutscene on a new game
# and change to the appropriate scene.
func _ready() -> void:
	match SaveManager.get_working_data().state:
		SaveData.State.NEW_GAME:
			_new_game_cutscene.run()
		SaveData.State.NORMAL:
			SceneManager.change_scene_to_file(_normal_scene_path, true, false)
		SaveData.State.COMPLETED:
			SceneManager.change_scene_to_file(_completed_scene_path)


# Run when the new game cutscene finishes. Save the current working save data in
# its normal state and change to the overworld scene.
func _on_new_game_cutscene_finished() -> void:
	SaveManager.get_working_data().state = SaveData.State.NORMAL
	SaveManager.push_to_slot()
	SaveManager.save_file()
	SceneManager.change_scene_to_file(_normal_scene_path, true, false)
