class_name ResultsMenuCard
extends MenuCard

# Results Menu Card
# The results menu card is a fixed menu card that is the root menu card of the
# results scene.

var _save_data: SaveData = Global.save.get_working_data()
var _stats: StatsSaveData = _save_data.stats
var _is_continuing: bool = false

onready var _time_label: Label = $CenterContainer/VBoxContainer/GridContainer/TimeValue
onready var _alert_count_label: Label = $CenterContainer/VBoxContainer/GridContainer/AlertCountValue

# Virtual _ready method. Runs when the results menu card finishes entering the
# scene tree. Displays the results of the save file:
func _ready() -> void:
	_time_label.text = "%02d:%02d:%02d" % [
		_stats.time_hours, _stats.time_minutes, _stats.time_seconds
	]
	_alert_count_label.text = String(_stats.alert_count)


# Signal callback for pressed on the continue button. Runs when the continue
# button is pressed. Completes the save file, saves the results, and changes to
# the credits scene if the save file was just completed. Changes to the menu
# scene if the save file is already completed:
func _on_continue_button_pressed() -> void:
	if _is_continuing:
		return
	
	_is_continuing = true
	
	if _save_data.state == SaveData.State.COMPLETED:
		Global.change_scene("menu")
	else:
		_save_data.state = SaveData.State.COMPLETED
		Global.save.save_file()
		Global.change_scene("credits")
