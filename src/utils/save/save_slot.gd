class_name SaveSlot
extends Reference

# Save Slot
# A save slot is a representation of a save file loaded by the game.

var index: int;
var data: SaveData = SaveData.new();

# Constructor. Sets the save slot's index and clears its data:
func _init(index_val: int) -> void:
	index = index_val;
	data.clear();


# Puts the contents of a save data object to the save slot's data by value:
func put_data(new_data: SaveData) -> void:
	_copy_data(new_data, data);


# Creates a clone of the save slot's data by value:
func clone_data() -> SaveData:
	var clone: SaveData = SaveData.new();
	_copy_data(data, clone);
	return clone;


# Copies the contents of one save data object to another by value:
func _copy_data(source: SaveData, target: SaveData) -> void:
	target.pos_level = source.pos_level;
	target.pos_point = source.pos_point;
	target.pos_offset = source.pos_offset;
