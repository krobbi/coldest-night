class_name SaveData
extends Object

# Save Data
# Save data are structures that represent the data that is stored in a save
# file.

enum State {
	NEW_GAME = 0x00,
	NORMAL = 0x01,
	COMPLETED = 0x02,
}

var state: int = State.NEW_GAME
var stats: StatsSaveData = StatsSaveData.new()
var level: String
var player: String
var team: Array = []
var players: Dictionary = {}
var flags: Dictionary = {}

# Sets a flag from its namespace and key:
func set_flag(namespace: String, key: String, value: int) -> void:
	if not flags.has(namespace):
		flags[namespace] = {}
	
	flags[namespace][key] = value
	Global.events.emit_signal("flag_changed", namespace, key, value)


# Gets a flag from its namespace and key:
func get_flag(namespace: String, key: String) -> int:
	if not flags.has(namespace):
		return 0
	
	return flags[namespace].get(key, 0)


# Clears the save data to empty values:
func clear() -> void:
	state = State.NEW_GAME
	stats.clear()
	level = ""
	clear_players()
	flags.clear()


# Clears the save data's player save data:
func clear_players() -> void:
	player = ""
	team.clear()
	
	for player_data in players.values():
		player_data.free()
	
	players.clear()


# Clears the save data to preset values for a new game:
func preset_new_game() -> void:
	clear()
	level = "test.area_bx.north"
	add_player(true, "player", "test.orange", "test.area_bx.north", "Start", 0.0)


# Adds player save data to the save data. If the player is the first player in
# the team then it is made the current player:
func add_player(
		in_team: bool, actor_key: String, player_key: String,
		pos_level: String, pos_point: String, pos_angle: float
) -> void:
	var player_data: PlayerSaveData = PlayerSaveData.new(actor_key, player_key)
	
	if players.has(actor_key):
		player_data.free()
		player_data = players[actor_key]
	else:
		players[actor_key] = player_data
	
	player_data.player_key = player_key
	player_data.level = pos_level
	player_data.point = pos_point
	player_data.offset = Vector2.ZERO
	player_data.angle = pos_angle
	
	if in_team:
		if team.empty():
			player = actor_key
		
		if not team.has(actor_key):
			team.push_back(actor_key)
	else:
		team.erase(actor_key)
		
		if player == actor_key:
			player = "" if team.empty() else team[0]


# Destructor. Frees the save data's player save data and statistics save data:
func destruct() -> void:
	clear_players()
	stats.free()
