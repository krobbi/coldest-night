extends Control

# Loader Scene
# The loader scene is a scene that loads the game from the current working save
# data.

var _save_data: SaveData = Global.save.get_working_data()

onready var _nightscript: NSInterpreter = $NightScriptInterpreter

# Virtual _ready method. Runs when the loader scene is entered. Ensures the game
# is not paused, starts the new game dialog on a new game, and changes to the
# overworld scene:
func _ready() -> void:
	Global.tree.paused = false
	
	match _save_data.state:
		SaveData.State.NEW_GAME:
			Global.audio.play_music("briefing")
			_nightscript.run_program("dialog.test.new_game")
		SaveData.State.COMPLETED:
			Global.change_scene("results")
		SaveData.State.NORMAL, _:
			_save_data.state = SaveData.State.NORMAL
			Global.change_scene("overworld", true, false)


# Signal callback for program_finished on NightScript. Runs when the load dialog
# finishes. Changes to the overworld scene:
func _on_nightscript_program_finished() -> void:
	_save_data.state = SaveData.State.NORMAL
	Global.change_scene("overworld", true, false)
