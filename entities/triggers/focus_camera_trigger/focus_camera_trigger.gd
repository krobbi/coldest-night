class_name FocusCameraTrigger
extends Trigger

# Focus Camera Trigger
# A focus camera trigger is a trigger that focuses the level camera on one of
# the current level's points when entered by a player.

export(String) var point: String

# Virtual _player_enter method. Runs when a player enters the focus camera
# trigger. Focuses the level camera on one of the current level's points:
func _player_enter(_player: Player) -> void:
	if Global.tree.current_scene.name != "Overworld":
		return
	
	var current_level: Level = Global.tree.current_scene.level_host.current_level
	
	if current_level:
		Global.events.emit_signal("camera_focus_request", current_level.get_point_pos(point))


# Virtual _player_exit method. Runs when a player exits the focus camera
# trigger. Unfocuses the level camera:
func _player_exit(_player: Player) -> void:
	Global.events.emit_signal("camera_unfocus_request")
