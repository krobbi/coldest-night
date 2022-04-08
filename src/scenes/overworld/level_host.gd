class_name LevelHost
extends Node2D

# Level Host
# The level host is a component of the overworld scene that handles loading and
# changing the current level and placing players in levels.

signal camera_follow_request(anchor)
signal camera_unfollow_request
signal camera_limit_request(top_left, bottom_right)
signal radar_render_node_request(node)
signal radar_clear_request
signal radar_refresh_actors_request
signal radar_camera_follow_request(anchor)
signal radar_camera_unfollow_request()

var save_data: SaveData = Global.save.get_working_data()
var current_level: Level = null
var current_player: Player = null

var _players: Dictionary = {}

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
	for player in _players.values():
		if player.is_connected("change_player_request", self, "toggle_player"):
			player.disconnect("change_player_request", self, "toggle_player")
		
		if not player.is_inside_tree():
			player.free()
	
	Global.events.safe_disconnect("accumulate_time_request", save_data.stats, "accumulate_time")
	Global.events.safe_disconnect(
			"accumulate_alert_count_request", save_data.stats, "accumulate_alert_count"
	)
	Global.events.safe_disconnect("save_state_request", self, "save_state")


# Changes the current level from its level key:
func change_level(level_key: String) -> void:
	emit_signal("camera_unfollow_request")
	emit_signal("radar_camera_unfollow_request")
	
	if current_level:
		Global.events.emit_signal("fade_out_request")
		yield(Global.events, "faded_out")
		
		emit_signal("radar_clear_request")
		current_player = null
		
		for player in _players.values():
			if player.get_parent() == current_level.midground:
				current_level.midground.remove_child(player)
		
		remove_child(current_level)
		current_level.free()
	
	current_level = _create_level(level_key)
	add_child(current_level)
	save_data.level = level_key
	Global.save.save_checkpoint()
	
	emit_signal("radar_render_node_request", current_level.radar)
	yield(Global.tree.create_timer(0.1), "timeout")
	
	for player_data in save_data.players.values():
		if player_data.level != level_key:
			continue
		
		var player: Player = _create_player(player_data.actor_key, player_data.player_key)
		player.position = current_level.get_world_pos(player_data.point, player_data.offset)
		current_level.midground.add_child(player)
		player.smooth_pivot.rotation = player_data.angle
		
		if save_data.player == player.actor_key:
			_activate_player(player)
	
	emit_signal("camera_limit_request", current_level.top_left, current_level.bottom_right)
	emit_signal("radar_refresh_actors_request")
	Global.events.emit_signal("fade_in_request")


# Changes the current player from its actor key:
func change_player(actor_key: String) -> void:
	var old_player: Player = current_player
	_deactivate_player()
	save_data.player = ""
	
	if not save_data.players.has(actor_key):
		return
	
	var player_data: PlayerSaveData = save_data.players[actor_key]
	var player: Player = _create_player(actor_key, player_data.player_key)
	save_data.player = actor_key
	
	yield(Global.tree, "idle_frame")
	
	if player.is_inside_tree():
		_activate_player(player)
	elif current_level and current_level.is_safe:
		save_state()
		change_level(player_data.level)
	elif old_player:
		_activate_player(old_player)
		save_data.player = old_player.actor_key
		Global.events.emit_signal(
				"floating_text_display_request",
				"FLOATING_TEXT.CHANGE_PLAYER_UNSAFE", old_player.position
		)


# Toggles the current player from the team:
func toggle_player() -> void:
	var team_size: int = save_data.team.size()
	
	if team_size < 2:
		return
	
	for i in range(team_size):
		if save_data.team[i] == save_data.player:
			change_player(save_data.team[(i + 1) % team_size])
			return


# Moves a player's saved position to a new level:
func move_player(actor_key: String, level: String, point: String, offset: Vector2) -> void:
	if not save_data.players.has(actor_key):
		return
	
	var player_data: PlayerSaveData = save_data.players[actor_key]
	player_data.level = level
	player_data.point = point
	player_data.offset = offset


# Initializes the game state from save data:
func load_state() -> void:
	change_level(save_data.level)


# Stores the game state to save data:
func save_state() -> void:
	if not current_level:
		return
	
	for actor_key in save_data.players:
		if not _players.has(actor_key):
			continue
		
		var player: Player = _players[actor_key]
		
		if player.get_parent() != current_level.midground:
			continue
		
		var relative_pos: Array = current_level.get_relative_pos(player.position)
		var player_data: PlayerSaveData = save_data.players[actor_key]
		player_data.point = relative_pos[0]
		player_data.offset = relative_pos[1]
		player_data.angle = player.smooth_pivot.rotation


# Activates a player as the current player:
func _activate_player(player: Player) -> void:
	if not player or current_player == player:
		return
	
	_deactivate_player()
	current_player = player
	current_player.set_radar_display(Actor.RadarDisplay.PLAYER)
	current_player.state_machine.change_state("Moving")
	current_player.enable_triggers()
	emit_signal("camera_follow_request", current_player.camera_anchor)
	emit_signal("radar_camera_follow_request", current_player)


# Deactivates the current player:
func _deactivate_player() -> void:
	if not current_player:
		return
	
	current_player.disable_triggers()
	current_player.state_machine.change_state("Scripted")
	current_player.set_radar_display(Actor.RadarDisplay.IDLE)
	current_player = null


# Creates a new level instance from its level key:
func _create_level(level_key: String) -> Level:
	return _load_level_scene(level_key).instance() as Level


# Creates a new player instance from its actor key and player key. Returns the
# cached player instance with a matching actor key if it exists:
func _create_player(actor_key: String, player_key: String):
	if _players.has(actor_key):
		return _players[actor_key]
	
	var player: Player = _load_player_scene(player_key).instance()
	player.actor_key = actor_key
	
	var error: int = player.connect(
			"change_player_request", self, "toggle_player", [], CONNECT_DEFERRED
	)
	
	if error and player.is_connected("change_player_request", self, "toggle_player"):
		player.disconnect("change_player_request", self, "toggle_player")
	
	_players[actor_key] = player
	return player


# Loads a level's scene from its level key:
func _load_level_scene(level_key: String) -> PackedScene:
	var path: String = "res://levels/%s.tscn" % level_key.replace(".", "/")
	
	if ResourceLoader.exists(path, "PackedScene"):
		return load(path) as PackedScene
	else:
		Global.logger.err_level_not_found(level_key)
		return load("res://levels/level.tscn") as PackedScene


# Loads a player's scene from its player key:
func _load_player_scene(player_key: String) -> PackedScene:
	var path: String = "res://entities/actors/players/%s.tscn" % player_key.replace(".", "/")
	
	if ResourceLoader.exists(path, "PackedScene"):
		return load(path) as PackedScene
	else:
		Global.logger.err_player_not_found(player_key)
		return load("res://entities/actors/players/test/orange.tscn") as PackedScene
