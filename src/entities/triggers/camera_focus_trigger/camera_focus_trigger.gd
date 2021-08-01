class_name CameraFocusTrigger
extends Trigger

# Camera Focus Trigger
# A camera focus trigger is a trigger that focuses the camera on a level point
# when triggered, and unfocuses the camera when untriggered.

export(String) var point: String;

func _trigger() -> void:
	var camera: OverworldCamera = Global.provider.get_camera();
	var level: Level = Global.provider.get_level();
	
	if level and camera:
		camera.focus(level.get_point_pos(point));
	else:
		print("Failed to focus camera as the overworld camera or level could not be provided!");


func _untrigger() -> void:
	var camera: OverworldCamera = Global.provider.get_camera();
	
	if camera:
		camera.unfocus();
	else:
		print("Failed to unfocus camera as the overworld camera could not be provided!");
