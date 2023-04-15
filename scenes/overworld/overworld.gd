extends Node2D

# Overworld Scene
# The overworld scene is the primary scene of the game. It contains the level,
# camera, and HUD and manages changing level.

var _save_data: SaveData = SaveManager.get_working_data()
var _player: Player = preload("res://entities/actors/player/player.tscn").instantiate()
var _level: Level = null

# Run when the overworld scene is entered. Subscribe the overworld scene to the
# event bus and change the level from save data.
func _ready() -> void:
	EventBus.subscribe_node(EventBus.transition_level_request, _transition_level)
	_change_level(_save_data.level, "", _save_data.position)


# Change the current level from its level path, point and offset.
func _change_level(level_path: String, point: String, offset: Vector2) -> void:
	EventBus.camera_unfollow_anchor_request.emit()
	EventBus.radar_camera_unfollow_anchor_request.emit()
	
	if _level:
		SceneManager.fade_out()
		await SceneManager.faded_out
		
		_level.save_state()
		
		_player.get_parent().remove_child(_player)
		remove_child(_level)
		_level.free()
	
	_level = load(level_path).instantiate()
	add_child(_level)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	_save_data.position = _level.get_point_pos(point) + offset
	_player.position = _save_data.position
	_level.get_player_parent().add_child(_player)
	_player.smooth_pivot.rotation_degrees = _save_data.angle
	
	EventBus.radar_camera_follow_anchor_request.emit(_player)
	EventBus.camera_follow_anchor_request.emit(_player.get_camera_anchor())
	
	_player.pop_state()
	
	SaveManager.push_to_checkpoint()
	SceneManager.fade_in()


# Transition the current level.
func _transition_level(
		level_path: String, point: String, relative_point: String,
		is_relative_x: bool, is_relative_y: bool) -> void:
	_player.push_transition_state()
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
