class_name FocusCameraTrigger
extends Trigger

# Focus Camera Trigger
# A focus camera trigger is a trigger that focuses the overworld camera on one
# of the current level's points while the player is inside it.

export(String) var point: String;

# Virtual _player_enter method. Runs when the player enters the focus camera
# trigger. Starts focusing the overworld camera on the current level's point
# defined in exported variables:
func _player_enter() -> void:
	var camera: OverworldCamera = Global.provider.get_camera();
	var level: Level = Global.provider.get_level();
	
	if level == null or camera == null:
		print("Camera focus trigger failed as objects could not be provided!");
		return;
	
	camera.focus(level.get_point_pos(point));


# Virtual _player_exit method. Runs when the player exits the focus camera
# trigger. Stops focusing the overworld camera:
func _player_exit() -> void:
	var camera: OverworldCamera = Global.provider.get_camera();
	
	if camera == null:
		print("Camera unfocus trigger failed as the overworld camera could not be provided!");
		return;
	
	camera.unfocus();
