class_name SaveData
extends Reference

# Save Data
# Save data objects are lightweight, itemized representations of the data stored
# in a save file:

var pos_level: String;
var pos_point: String;
var pos_offset: Vector2;

# Clears the save data to the values for a new game:
func clear() -> void:
	pos_level = "test/blockout/north";
	pos_point = "Start";
	pos_offset = Vector2.ZERO;
