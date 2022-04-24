extends Control

# Results Scene
# The results scene is a scene that saves and displays the results of a
# completed save file.

var _is_continuing: bool = false
var _save_data: SaveData = Global.save.get_working_data()

# Virtual _ready method. Runs when the results scene is entered. Plays background music and Displays the
# results:
func _ready() -> void:
	Global.audio.play_music("menu")
	$CenterContainer/VBoxContainer/GridContainer/TimeValue.text = "%02d:%02d:%02d" % [
			_save_data.stats.time_hours, _save_data.stats.time_minutes,
			_save_data.stats.time_seconds
	]
	$CenterContainer/VBoxContainer/GridContainer/AlertCountValue.text = String(
			_save_data.stats.alert_count
	)


# Signal callback for pressed on the continue button. Runs when the continue
# button is pressed. Saves the results and continues to the credits scene:
func _on_continue_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	
	if _save_data.state == SaveData.State.COMPLETED:
		Global.change_scene("title")
	else:
		_save_data.state = SaveData.State.COMPLETED
		Global.save.save_file()
		Global.change_scene("credits")
