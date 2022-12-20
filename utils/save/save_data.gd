class_name SaveData
extends Object

# Save Data
# Save data are structures that represent the data that is stored in a save
# file.

enum State {NEW_GAME, NORMAL, COMPLETED}

var state: int = State.NEW_GAME
var stats: StatsSaveData = StatsSaveData.new()
var level: String
var flags: Dictionary = {}
var point: String = "World"
var offset: Vector2 = Vector2.ZERO
var angle: float = 0.0

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
	flags.clear()
	point = "World"
	offset = Vector2.ZERO
	angle = 0.0


# Clears the save data to preset values for a new game:
func preset_new_game() -> void:
	clear()
	level = "test.area_bx.north"
	point = "Start"
	angle = 0.0


# Serialize the save data to a JSON object.
func serialize() -> Dictionary:
	return {
		"state": serialize_state(),
		"level": level,
		"point": point,
		"offsetX": offset.x,
		"offsetY": offset.y,
		"angle": angle,
		"stats": stats.serialize(),
		"flags": flags.duplicate(true),
	}


# Serialize the save data's state to a string.
func serialize_state() -> String:
	match state:
		State.NEW_GAME:
			return "NEW_GAME"
		State.COMPLETED:
			return "COMPLETED"
		State.NORMAL, _:
			return "NORMAL"


# Deserialize the save data from a JSON object.
func deserialize(data: Dictionary) -> void:
	deserialize_state(String(data.get("state", "NORMAL")))
	level = String(data.get("level", "test.area_bx.hub"))
	point = String(data.get("point", "Terminal"))
	offset = Vector2(float(data.get("offsetX", 0.0)), float(data.get("offsetY", 0.0)))
	angle = float(data.get("angle", PI * 0.5))
	stats.deserialize(data.stats)
	flags = data.get("flags", {}).duplicate(true)


# Deserialize the save data's state from a string.
func deserialize_state(data: String) -> void:
	match data:
		"NEW_GAME":
			state = State.NEW_GAME
		"COMPLETED":
			state = State.COMPLETED
		"NORMAL", _:
			state = State.NORMAL


# Destructor. Frees the save data's statisics save data:
func destruct() -> void:
	stats.free()
