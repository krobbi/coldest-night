extends Control

# Loader Scene
# The loader scene is a scene that loads the game from the current working save
# data.

var _save_data: SaveData = SaveManager.get_working_data()

# Run when the loader scene is entered. Ensure the game is not paused, start the
# new game dialog on a new game, and change to the overworld scene.
func _ready() -> void:
	Global.tree.paused = false
	
	match _save_data.state:
		SaveData.State.NEW_GAME:
			AudioManager.play_music("briefing")
			EventBus.emit_nightscript_run_program_request("dialog/test/new_game")
		SaveData.State.COMPLETED:
			Global.change_scene("results")
		SaveData.State.NORMAL, _:
			_load_normal()


# Set the current working save data's state to normal and change to the
# overworld scene.
func _load_normal() -> void:
	_save_data.state = SaveData.State.NORMAL
	Global.change_scene("overworld", true, false)
