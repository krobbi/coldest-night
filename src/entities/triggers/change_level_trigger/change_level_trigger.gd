class_name ChangeLevelTrigger
extends Trigger

# Change Level Trigger
# A change level trigger is a trigger that changes the current level when
# triggered.

enum RelativeMode {
	NONE = 0b00,
	RELATIVE_X = 0b01,
	RELATIVE_Y = 0b10,
	RELATIVE_XY = 0b11,
};

export(String) var key: String;
export(String) var point: String;
export(RelativeMode) var relative_mode: int = RelativeMode.NONE;
export(String) var relative_point: String;

# Virtual _trigger method. Runs when the change level trigger is triggered.
# Changes the current level to the level and point defined in exported
# variables:
func _trigger() -> void:
	var overworld: Overworld = Global.provider.get_overworld();
	
	if overworld:
		if relative_mode == RelativeMode.NONE:
			overworld.change_level(key, point);
			return;
		
		var player: Player = Global.provider.get_player();
		var level: Level = Global.provider.get_level();
		var relative_pos: Vector2;
		var offset: Vector2 = Vector2.ZERO;
		
		if level and player:
			relative_pos = player.get_position() - level.get_point_pos(relative_point);
		else:
			print("Relative change level failed as the level or player could not be provided!");
			relative_pos = Vector2.ZERO;
		
		if relative_mode & RelativeMode.RELATIVE_X:
			offset.x = relative_pos.x;
		
		if relative_mode & RelativeMode.RELATIVE_Y:
			offset.y = relative_pos.y;
		
		overworld.change_level(key, point, offset);
	else:
		print("Change level failed as the overworld scene could not be provided!");
