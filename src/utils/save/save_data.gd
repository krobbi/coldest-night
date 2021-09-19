class_name SaveData
extends Object

# Save Data
# Save data are objects representing the data stored in a save file.

var pos_level: String;
var pos_point: String;
var pos_offset: Vector2;
var pos_angle: float;
var flags: Dictionary;

# Clears the save data to the values for a new game:
func clear() -> void:
	pos_level = "test/blockout/north";
	pos_point = "Start";
	pos_offset = Vector2.ZERO;
	pos_angle = PI * 0.5;
	flags = {};


# Sets a flag from its namespace and key:
func set_flag(namespace: String, key: String, value: int) -> void:
	if not flags.has(namespace):
		flags[namespace] = {};
	
	flags[namespace][key] = value;


# Gets a flag from its namespace and key:
func get_flag(namespace: String, key: String) -> int:
	return flags[namespace][key] if flags.has(namespace) and flags[namespace].has(key) else 0;
