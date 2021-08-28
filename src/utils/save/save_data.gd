class_name SaveData
extends Object

# Save Data
# Save data are objects representing the data stored in a save file.

var pos_level: String;
var pos_point: String;
var pos_offset: Vector2;
var dialog_flags: Dictionary;

# Clears the save data to the values for a new game:
func clear() -> void:
	pos_level = "test/blockout/north";
	pos_point = "Start";
	pos_offset = Vector2.ZERO;
	dialog_flags = {};
