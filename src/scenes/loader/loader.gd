extends Control

# Loader Scene
# The loader scene is a scene that loads the game from the current working save
# data.

var _save_data: SaveData = Global.save.get_working_data()

# Virtual _ready method. Runs when the loader scene is entered. Ensures the game
# is not paused, starts the new game dialog on a new game, and changes to the
# overworld scene:
func _ready() -> void:
	Global.tree.paused = false
	
	match _save_data.state:
		SaveData.State.NEW_GAME:
			Global.audio.play_music("briefing")
			Global.events.safe_connect(
					"nightscript_thread_finished", self,
					"_on_nightscript_thread_finished", [], CONNECT_ONESHOT
			)
			Global.events.emit_signal("nightscript_run_program_request", "dialog.test.new_game")
		SaveData.State.COMPLETED:
			Global.change_scene("results")
		SaveData.State.NORMAL, _:
			_save_data.state = SaveData.State.NORMAL
			Global.change_scene("overworld", true, false)


# Signal callback for a finished NightScript thread. Runs when the load dialog
# finishes. Changes to the overworld scene:
func _on_nightscript_thread_finished() -> void:
	_save_data.state = SaveData.State.NORMAL
	Global.change_scene("overworld", true, false)
