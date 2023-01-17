class_name LevelHost
extends Node2D

# Level Host
# The level host is a component of the overworld scene that handles loading and
# changing the current level and placing players in levels.

var save_data: SaveData = Global.save.get_working_data()
var current_level: Level = null

var _player: Player = preload("res://entities/actors/player/player.tscn").instance()

# Virtual _ready method. Runs when the level host enters the scene tree.
# Connects the level host to the event bus:
func _ready() -> void:
	Global.events.safe_connect("save_state_request", self, "save_state")
	Global.events.safe_connect(
			"accumulate_alert_count_request", save_data.stats, "accumulate_alert_count"
	)
	Global.events.safe_connect("accumulate_time_request", save_data.stats, "accumulate_time")


# Virtual _exit_tree method. Runs when the level host exits the scene tree.
# Frees cached player instances that are not inside the scene tree and
# disconnects the level host from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("accumulate_time_request", save_data.stats, "accumulate_time")
	Global.events.safe_disconnect(
			"accumulate_alert_count_request", save_data.stats, "accumulate_alert_count"
	)
	Global.events.safe_disconnect("save_state_request", self, "save_state")


# Changes the current level from its level key:
func change_level(level_key: String) -> void:
	Global.events.emit_signal("camera_unfollow_anchor_request")
	Global.events.emit_signal("radar_camera_unfollow_anchor_request")
	
	if current_level:
		Global.events.emit_signal("fade_out_request")
		yield(Global.events, "faded_out")
		
		Global.events.emit_signal("radar_clear_request")
		current_level.midground.remove_child(_player)
		remove_child(current_level)
		current_level.free()
	
	Global.events.emit_signal("nightscript_stop_programs_request")
	current_level = _create_level(level_key)
	
	for program_key in current_level.cached_ns_programs:
		Global.events.emit_signal("nightscript_cache_program_request", program_key)
	
	add_child(current_level)
	save_data.level = level_key
	Global.save.save_checkpoint()
	
	Global.events.emit_signal("radar_render_node_request", current_level.radar)
	yield(Global.tree.create_timer(0.1), "timeout")
	
	_player.position = current_level.get_world_pos(save_data.point, save_data.offset)
	current_level.midground.add_child(_player)
	_player.smooth_pivot.rotation = save_data.angle
	_player.state_machine.change_state(_player.get_moving_state())
	_player.enable_triggers()
	Global.events.emit_signal("camera_follow_anchor_request", _player.camera_anchor)
	Global.events.emit_signal("radar_camera_follow_anchor_request", _player)
	
	Global.events.emit_signal(
			"camera_set_limits_request", current_level.top_left, current_level.bottom_right
	)
	Global.events.emit_signal("radar_refresh_entities_request")
	
	for program_key in current_level.autorun_ns_programs:
		Global.events.emit_signal("nightscript_run_program_request", program_key)
	
	Global.events.emit_signal("fade_in_request")


# Moves a player's saved position to a new level:
func move_player(point: String, offset: Vector2) -> void:
	save_data.point = point
	save_data.offset = offset


# Initializes the game state from save data:
func load_state() -> void:
	change_level(save_data.level)


# Stores the game state to save data:
func save_state() -> void:
	if not current_level:
		return
	
	var relative_position: Array = current_level.get_relative_pos(_player.position)
	save_data.point = relative_position[0]
	save_data.offset = relative_position[1]
	save_data.angle = _player.smooth_pivot.rotation


# Creates a new level instance from its level key:
func _create_level(level_key: String) -> Level:
	return _load_level_scene(level_key).instance() as Level


# Loads a level's scene from its level key:
func _load_level_scene(level_key: String) -> PackedScene:
	return load("res://levels/%s.tscn" % level_key.replace(".", "/")) as PackedScene
