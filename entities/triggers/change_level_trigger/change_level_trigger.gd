class_name ChangeLevelTrigger
extends Trigger

# Change Level Trigger
# A change level trigger is a trigger that moves a player to a new current level
# when entered by the player.

enum RelativeMode {
	FIXED = 0b00,
	RELATIVE_X = 0b01,
	RELATIVE_Y = 0b10,
	RELATIVE = 0b11,
}

export(String) var level: String
export(String) var point: String
export(RelativeMode) var relative_mode: int = RelativeMode.FIXED
export(String) var relative_point: String

# Virtual _player_pre_enter method. Runs before a player enters the change level
# trigger. Disables the player:
func _player_pre_enter(player: Player) -> void:
	player.state_machine.change_state(player.get_transitioning_state())


# Virtual _player_enter method. Runs when a player enters the change level
# trigger. Moves the player to a new current level:
func _player_enter(player: Player) -> void:
	var level_host: LevelHost = find_parent("LevelHost")
	
	if not level_host is LevelHost:
		return
	
	var offset: Vector2 = Vector2.ZERO
	
	if relative_mode and level_host.current_level:
		var relative: Vector2 = player.position - level_host.current_level.get_point_pos(
				relative_point
		)
		
		if relative_mode & RelativeMode.RELATIVE_X:
			offset.x = relative.x
		
		if relative_mode & RelativeMode.RELATIVE_Y:
			offset.y = relative.y
	
	level_host.save_state()
	level_host.move_player(point, offset)
	level_host.change_level(level)
