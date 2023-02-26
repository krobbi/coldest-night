extends Control

# Loader Scene
# The loader scene is a scene that loads the game from the current working save
# data.

export(String, FILE, "*.tscn") var _normal_scene_path: String
export(String, FILE, "*.tscn") var _completed_scene_path: String

var _save_data: SaveData = SaveManager.get_working_data()

# Run when the loader scene is entered. Start the new game dialog on a new game
# and change to the appropriate scene.
func _ready() -> void:
	match _save_data.state:
		SaveData.State.NEW_GAME:
			AudioManager.play_music("briefing")
			EventBus.emit_nightscript_run_program_request("new_game")
		SaveData.State.COMPLETED:
			SceneManager.change_scene(_completed_scene_path)
		SaveData.State.NORMAL, _:
			_load_normal()


# Set the current working save data's state to normal and change to the normal
# scene.
func _load_normal() -> void:
	var is_new_game: bool = _save_data.state == SaveData.State.NEW_GAME
	_save_data.state = SaveData.State.NORMAL
	
	if is_new_game:
		SaveManager.push_to_slot()
		SaveManager.save_file()
	
	SceneManager.change_scene(_normal_scene_path, true, false)
