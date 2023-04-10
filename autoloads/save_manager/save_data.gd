class_name SaveData
extends RefCounted

# Save Data
# Save data are structures that represent the data that is stored in a save
# file.

signal flag_changed(flag: String, value: int)

enum State {NEW_GAME, NORMAL, COMPLETED}

var state: int
var level: String
var position: Vector2
var angle: float
var stats: StatsSaveData = StatsSaveData.new()
var flags: Dictionary = {}
var scenes: Dictionary = {}

# Clear the save data.
func _init() -> void:
	clear()


# Set a flag from its flag.
func set_flag(flag: String, value: int) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


# Get a flag from its flag.
func get_flag(flag: String) -> int:
	return flags.get(flag, 0)


# Clear the save data to a new game.
func clear() -> void:
	state = State.NEW_GAME
	level = "res://levels/test/area_bx/north.tscn"
	position = Vector2(-368.0, -496.0)
	angle = 0.0
	stats.clear()
	flags.clear()
	scenes.clear()


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
		"position": {"x": position.x, "y": position.y},
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
	position = Vector2(float(data.position.x), float(data.position.y))
	angle = float(data.angle)
	stats.deserialize(data.stats.duplicate(true))
	flags = data.flags.duplicate(true)
	scenes = data.scenes.duplicate(true)
