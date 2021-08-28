class_name ChangeLevelTrigger
extends Trigger

# Change Level Trigger
# A change level trigger is a trigger that changes the current level when
# entered by the player.

enum RelativeMode {
	FIXED = 0b00,
	RELATIVE_X = 0b01,
	RELATIVE_Y = 0b10,
	RELATIVE = 0b11,
};

export(String) var key: String;
export(String) var point: String;
export(RelativeMode) var relative_mode: int = RelativeMode.FIXED;
export(String) var relative_point: String;

# Virtual _player_enter method. Runs when the player enters the change level
# trigger. Changes the current level and positions the player from the
# parameters defined in exported variables:
func _player_enter() -> void:
	var overworld: Overworld = Global.provider.get_overworld();
	
	if overworld == null:
		print("Change level trigger failed as the overworld scene could not be provided!");
		return;
	
	var offset: Vector2 = Vector2.ZERO;
	
	if relative_mode == RelativeMode.FIXED:
		overworld.change_level(key, point, offset);
		return;
	
	var player: Player = Global.provider.get_player();
	var level: Level = Global.provider.get_level();
	
	if level == null or player == null:
		print("Relative change level trigger failed as objects could not be provided!");
		overworld.change_level(key, point, offset);
		return;
	
	var relative: Vector2 = player.get_position() - level.get_point_pos(relative_point);
	
	if relative_mode & RelativeMode.RELATIVE_X != 0:
		offset.x = relative.x;
	
	if relative_mode & RelativeMode.RELATIVE_Y != 0:
		offset.y = relative.y;
	
	overworld.change_level(key, point, offset);
