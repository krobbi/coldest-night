class_name SaveData
extends Reference

# Save Data
# Save data are structures that represent the data that is stored in a save
# file.

signal flag_changed(namespace, key, value)

enum State {NEW_GAME, NORMAL, COMPLETED}

var state: int = State.NEW_GAME
var level: String
var position: Vector2 = Vector2.ZERO
var angle: float = 0.0
var stats: StatsSaveData = StatsSaveData.new()
var flags: Dictionary = {}
var scenes: Dictionary = {}

# Set a flag from its namespace and key.
func set_flag(namespace: String, key: String, value: int) -> void:
	if not flags.has(namespace):
		flags[namespace] = {}
	
	flags[namespace][key] = value
	emit_signal("flag_changed", namespace, key, value)


# Get a flag from its namespace and key.
func get_flag(namespace: String, key: String) -> int:
	if not flags.has(namespace):
		return 0
	
	return flags[namespace].get(key, 0)


# Clear the save data to empty values.
func clear() -> void:
	state = State.NEW_GAME
	level = ""
	position = Vector2.ZERO
	angle = 0.0
	stats.clear()
	flags.clear()
	scenes.clear()


# Clear the save data to preset values for a new game.
func preset_new_game() -> void:
	clear()
	level = "test/area_bx/north"
	position = Vector2(-368.0, -496.0)


# Serialize the save data's state to a string.
func serialize_state() -> String:
	match state:
		State.NEW_GAME:
			return "NEW_GAME"
		State.COMPLETED:
			return "COMPLETED"
		State.NORMAL, _:
			return "NORMAL"


# Serialize the save data to a JSON object.
func serialize() -> Dictionary:
	return {
		"format_name": SaveManager.FORMAT_NAME,
		"format_version": SaveManager.FORMAT_VERSION,
		"state": serialize_state(),
		"level": level,
		"position_x": position.x,
		"position_y": position.y,
		"angle": angle,
		"stats": stats.serialize(),
		"flags": flags.duplicate(true),
		"scenes": scenes.duplicate(true),
	}


# Deserialize the save data's state from a string.
func deserialize_state(data: String) -> void:
	match data:
		"NEW_GAME":
			state = State.NEW_GAME
		"COMPLETED":
			state = State.COMPLETED
		"NORMAL", _:
			state = State.NORMAL


# Deserialize the save data from a validated JSON object.
func deserialize(data: Dictionary) -> void:
	deserialize_state(data.state)
	level = data.level
	position = Vector2(float(data.position_x), float(data.position_y))
	angle = float(data.angle)
	stats.deserialize(data.stats.duplicate(true))
	flags = data.flags.duplicate(true)
	scenes = data.scenes.duplicate(true)
