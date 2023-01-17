class_name SaveManager
extends Reference

# Save Manager
# The save manager is a global utility that handles loading, storing,
# manipulating, and saving save data. It can be accessed from any script by
# using 'Global.save'.

const FORMAT_NAME: String = "krobbizoid.coldest-night.save-data"
const FORMAT_VERSION: int = 1
const SLOT_COUNT: int = 1
const SAVES_DIR: String = "user://saves/"

var _events: EventBus
var _working_data: SaveData = SaveData.new()
var _checkpoint_data: SaveData = SaveData.new()
var _slots: Array = []
var _selected_slot: int = 0

# Constructor. Populates the save manager's slots:
func _init(events_ref: EventBus) -> void:
	_events = events_ref
	_slots.resize(SLOT_COUNT)
	
	for i in range(SLOT_COUNT):
		_slots[i] = SaveData.new()


# Gets the current working save data:
func get_working_data() -> SaveData:
	return _working_data


# Selects a slot from its slot index:
func select_slot(slot_index: int) -> void:
	if _selected_slot != slot_index and slot_index >= 0 and slot_index < SLOT_COUNT:
		_selected_slot = slot_index
		_copy_save_data(_slots[_selected_slot], _working_data, true)
		_copy_save_data(_working_data, _checkpoint_data, true)


# Loads the current working save data from the checkpoint:
func load_checkpoint() -> void:
	_copy_save_data(_checkpoint_data, _working_data, false)


# Loads the current working save data from the selected slot's file:
func load_file() -> void:
	_load_file(_slots[_selected_slot], _selected_slot)
	_copy_save_data(_slots[_selected_slot], _working_data, true)
	_copy_save_data(_working_data, _checkpoint_data, true)


# Loads the current working save data from the selected slot:
func load_slot() -> void:
	_copy_save_data(_slots[_selected_slot], _working_data, true)
	_copy_save_data(_working_data, _checkpoint_data, true)


# Loads the current working save data from the selected slot without overwriting
# its statistics save data:
func load_slot_checkpoint() -> void:
	_copy_save_data(_slots[_selected_slot], _working_data, false)
	_copy_save_data(_working_data, _checkpoint_data, true)


# Saves the current working save data to the checkpoint:
func save_checkpoint() -> void:
	_copy_save_data(_working_data, _checkpoint_data, true)


# Saves the current working data to the selected slot's file:
func save_file() -> void:
	_copy_save_data(_working_data, _checkpoint_data, true)
	_copy_save_data(_working_data, _slots[_selected_slot], true)
	_save_file(_slots[_selected_slot], _selected_slot)


# Saves the current game state to the selected slot's file:
func save_game() -> void:
	_events.emit_signal("save_state_request")
	_copy_save_data(_working_data, _checkpoint_data, true)
	_copy_save_data(_working_data, _slots[_selected_slot], true)
	_save_file(_slots[_selected_slot], _selected_slot)


# Saves a new game save file to the selected slot's file:
func save_new_game() -> void:
	_working_data.preset_new_game()
	_copy_save_data(_working_data, _checkpoint_data, true)
	_copy_save_data(_working_data, _slots[_selected_slot], true)
	_save_file(_slots[_selected_slot], _selected_slot)


# Gets a slot's path from its slot index:
func _get_slot_path(slot_index: int) -> String:
	return "%ssave_%d.json" % [SAVES_DIR, slot_index + 1]


# Copies source save data to target save data by value:
func _copy_save_data(source: SaveData, target: SaveData, copy_stats: bool) -> void:
	var original_stats: Dictionary = target.stats.serialize()
	target.deserialize(source.serialize())
	
	if not copy_stats:
		target.stats.deserialize(original_stats)


# Copies source statistics save data to target statistics save data by value:
func _copy_stats_save_data(source: StatsSaveData, target: StatsSaveData) -> void:
	target.deserialize(source.serialize())


# Loads save data from its file from a slot index:
func _load_file(save_data: SaveData, slot_index: int) -> void:
	var file: File = File.new()
	var path: String = _get_slot_path(slot_index)
	save_data.preset_new_game()
	
	if not file.file_exists(path):
		return
	
	if file.open(path, File.READ) != OK:
		if file.is_open():
			file.close()
		
		return
	
	var text: String = file.get_as_text()
	file.close()
	
	if not validate_json(text).empty():
		return
	
	var parse_result: JSONParseResult = JSON.parse(text)
	
	if parse_result.error != OK or not parse_result.result or not parse_result.result is Dictionary:
		return
	
	save_data.deserialize(parse_result.result)


# Saves save data to its file from a payload format and slot index:
func _save_file(save_data: SaveData, slot_index: int) -> void:
	var dir: Directory = Directory.new()
	
	if not dir.dir_exists(SAVES_DIR) and dir.make_dir(SAVES_DIR) != OK:
		return
	
	var file: File = File.new()
	
	if file.open(_get_slot_path(slot_index), File.WRITE) != OK:
		if file.is_open():
			file.close()
		
		return
	
	file.store_string("%s\n" % JSON.print(save_data.serialize(), "\t"))
	file.close()
