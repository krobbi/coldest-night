extends Node2D

# Level Host
# The level host is a component of the overworld scene that handles loading and
# changing the current level and placing players in levels.

var current_level: Level = null

var _save_data: SaveData = Global.save.get_working_data()
var _player: Player = preload("res://entities/actors/player/player.tscn").instance()

# Run when the level host enters the scene tree. Connect the level host to the
# event bus.
func _ready() -> void:
	Global.events.safe_connect("transition_level_request", self, "transition_level")


# Run when the level host exits the scene tree. Disconnects the level host from
# the event bus.
func _exit_tree() -> void:
	Global.events.safe_disconnect("transition_level_request", self, "transition_level")


# Transition the current level.
func transition_level(
		level_key: String, point: String, relative_point: String,
		is_relative_x: bool, is_relative_y: bool) -> void:
	_player.state_machine.change_state(_player.get_transitioning_state())
	var offset: Vector2 = Vector2.ZERO
	
	if current_level:
		var relative: Vector2 = _player.position - current_level.get_point_pos(relative_point)
		
		if is_relative_x:
			offset.x = relative.x
		
		if is_relative_y:
			offset.y = relative.y
	
	_save_data.level = level_key
	_save_data.angle = _player.smooth_pivot.rotation
	_change_level(level_key, point, offset)


# Initialize the game state from save data.
func load_state() -> void:
	_change_level(_save_data.level, "World", _save_data.position)


# Change the current level from its level key, point and offset.
func _change_level(level_key: String, point: String, offset: Vector2) -> void:
	EventBus.emit_camera_unfollow_anchor_request()
	Global.events.emit_signal("radar_camera_unfollow_anchor_request")
	
	if current_level:
		Global.events.emit_signal("fade_out_request")
		yield(Global.events, "faded_out")
		
		Global.events.emit_signal("radar_clear_request")
		_player.get_parent().remove_child(_player)
		remove_child(current_level)
		current_level.free()
	
	Global.events.emit_signal("nightscript_stop_programs_request")
	
	current_level = load("res://levels/%s.tscn" % level_key).instance()
	add_child(current_level)
	
	yield(Global.tree, "idle_frame")
	yield(Global.tree, "idle_frame")
	
	_save_data.position = current_level.get_world_pos(point, offset)
	_player.position = _save_data.position
	current_level.get_player_parent().add_child(_player)
	_player.smooth_pivot.rotation = _save_data.angle
	
	Global.events.emit_signal("radar_refresh_entities_request")
	Global.events.emit_signal("radar_camera_follow_anchor_request", _player)
	EventBus.emit_camera_follow_anchor_request(_player.camera_anchor)
	
	_player.state_machine.change_state(_player.get_moving_state())
	_player.enable_triggers()
	
	Global.save.save_checkpoint()
	Global.events.emit_signal("fade_in_request")
