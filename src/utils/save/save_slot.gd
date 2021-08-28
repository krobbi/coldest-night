class_name SaveSlot
extends Object

var index: int;
var data: SaveData = SaveData.new();
var should_load: bool = true;

# Constructor. Sets the save slot's index and clears its save data:
func _init(index_val: int) -> void:
	index = index_val;
	data.clear();


# Destructor. Frees the save slot's save data:
func destruct() -> void:
	data.free();
