class_name LevelHost
extends Node2D

# Level Host
# The level host is a component of the overworld scene that handles loading and
# changing the current level and placing players in levels.

var save_data: SaveData = Global.save.get_working_data()
var current_level: Level = null

var _player: Player = preload("res://entities/actors/player/player.tscn").instance()

# Run when the level host enters the scene tree. Connect the level host to the
# event bus.
func _ready() -> void:
	Global.events.safe_connect("save_state_request", self, "save_state")
	Global.events.safe_connect(
			"accumulate_alert_count_request", save_data.stats, "accumulate_alert_count"
	)


# Run when the level host exits the scene tree. Disconnects the level host from
# the event bus.
func _exit_tree() -> void:
	Global.events.safe_disconnect(
			"accumulate_alert_count_request", save_data.stats, "accumulate_alert_count"
	)
	Global.events.safe_disconnect("save_state_request", self, "save_state")


# Change the current level from its level key.
func change_level(level_key: String) -> void:
	Global.events.emit_signal("camera_unfollow_anchor_request")
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
	
	_player.position = current_level.get_world_pos(save_data.point, save_data.offset)
	current_level.get_player_parent().add_child(_player)
	_player.smooth_pivot.rotation = save_data.angle
	
	Global.events.emit_signal("radar_refresh_entities_request")
	Global.events.emit_signal("radar_camera_follow_anchor_request", _player)
	Global.events.emit_signal("camera_follow_anchor_request", _player.camera_anchor)
	
	_player.state_machine.change_state(_player.get_moving_state())
	_player.enable_triggers()
	
	save_data.level = level_key
	Global.save.save_checkpoint()
	
	Global.events.emit_signal("fade_in_request")


# Move the player's saved position.
func move_player(point: String, offset: Vector2) -> void:
	save_data.point = point
	save_data.offset = offset


# Initialize the game state from save data.
func load_state() -> void:
	change_level(save_data.level)


# Store the game state to save data.
func save_state() -> void:
	if not current_level:
		return
	
	var relative_position: Array = current_level.get_relative_pos(_player.position)
	save_data.point = relative_position[0]
	save_data.offset = relative_position[1]
	save_data.angle = _player.smooth_pivot.rotation
