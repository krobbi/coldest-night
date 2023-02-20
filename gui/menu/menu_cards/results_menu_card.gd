extends MenuCard

# Results Menu Card
# The results menu card is a fixed menu card that is the root menu card of the
# results scene.

export(String, FILE, "*.tscn") var _just_completed_scene_path: String
export(String, FILE, "*.tscn") var _already_completed_scene_path: String

var _save_data: SaveData = SaveManager.get_working_data()
var _is_continuing: bool = false

# Run when the results menu card finishes entering the scene tree. Display the
# current working save data's stats.
func _ready() -> void:
	$CenterContainer/VBoxContainer/GridContainer/TimeValue.text = "%02d:%02d:%02d" % [
		_save_data.stats.time_hours,
		_save_data.stats.time_minutes,
		_save_data.stats.time_seconds,
	]
	$CenterContainer/VBoxContainer/GridContainer/AlertCountValue.text = String(
			_save_data.stats.alert_count)


# Run when the continue button is pressed. Complete and save the current working
# save data and change to the just completed scene if the current working save
# data was just completed. Otherwise, change to the already completed scene.
func _on_continue_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	
	if _save_data.state == SaveData.State.COMPLETED:
		SceneManager.change_scene(_already_completed_scene_path)
	else:
		_save_data.state = SaveData.State.COMPLETED
		SaveManager.push_to_slot()
		SaveManager.save_file()
		SceneManager.change_scene(_just_completed_scene_path)
