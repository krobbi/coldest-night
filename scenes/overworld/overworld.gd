extends Node2D

# Overworld Scene
# The overworld scene is the primary scene of the game. It contains the level,
# camera, and HUD and manages changing level.

var _save_data: SaveData = SaveManager.get_working_data()
var _player: Player = preload("res://entities/actors/player/player.tscn").instance()
var _level: Level = null

# Run when the overworld scene is entered. Subscribe the overworld scene to the
# event bus and change the level from save data.
func _ready() -> void:
	EventBus.subscribe_node("transition_level_request", self, "_transition_level")
	_change_level(_save_data.level, "", _save_data.position)


# Change the current level from its level path, point and offset.
func _change_level(level_path: String, point: String, offset: Vector2) -> void:
	EventBus.emit_camera_unfollow_anchor_request()
	EventBus.emit_radar_camera_unfollow_anchor_request()
	
	if _level:
		SceneManager.fade_out()
		yield(SceneManager, "faded_out")
		
		_level.save_state()
		
		_player.get_parent().remove_child(_player)
		remove_child(_level)
		_level.free()
	
	_level = load(level_path).instance()
	add_child(_level)
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	_save_data.position = _level.get_point_pos(point) + offset
	_player.position = _save_data.position
	_level.get_player_parent().add_child(_player)
	_player.smooth_pivot.rotation_degrees = _save_data.angle
	
	EventBus.emit_radar_camera_follow_anchor_request(_player)
	EventBus.emit_camera_follow_anchor_request(_player.get_camera_anchor())
	
	_player.state_machine.change_state(_player.get_moving_state())
	_player.enable_triggers()
	
	SaveManager.push_to_checkpoint()
	SceneManager.fade_in()


# Transition the current level.
func _transition_level(
		level_path: String, point: String, relative_point: String,
		is_relative_x: bool, is_relative_y: bool) -> void:
	EventBus.emit_player_transition_request()
	var offset: Vector2 = Vector2.ZERO
	
	if _level:
		var relative: Vector2 = _player.position - _level.get_point_pos(relative_point)
		
		if is_relative_x:
			offset.x = relative.x
		
		if is_relative_y:
			offset.y = relative.y
	
	_save_data.level = level_path
	_save_data.angle = _player.smooth_pivot.rotation_degrees
	_change_level(level_path, point, offset)
