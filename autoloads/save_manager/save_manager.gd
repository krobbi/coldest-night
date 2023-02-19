extends Node

# Save Manager
# The save manager is an autoload scene that handles loading, storing, and
# saving save data. It can be accessed from any script by using `SaveManager`.

const FORMAT_NAME: String = "krobbizoid.coldest-night.save"
const FORMAT_VERSION: int = 1
const SAVES_DIR: String = "user://saves/"
const FILE_PATH: String = "%ssave_1.json" % SAVES_DIR

var _slot_data: SaveData = SaveData.new()
var _checkpoint_data: SaveData = SaveData.new()
var _working_data: SaveData = SaveData.new()

# Run when the save manager enters the scene tree. Load the save data.
func _ready() -> void:
	load_file()
	pull_from_slot()


# Get the current working save data.
func get_working_data() -> SaveData:
	return _working_data


# Save the state of the game and save current working save data to the slot save
# data's file.
func save_game() -> void:
	EventBus.emit_save_state_request()
	push_to_slot()
	save_file()


# Save the slot save data to its file.
func save_file() -> void:
	var dir: Directory = Directory.new()
	
	if not dir.dir_exists(SAVES_DIR) and dir.make_dir(SAVES_DIR) != OK:
		return
	
	var file: File = File.new()
	
	if file.open(FILE_PATH, File.WRITE) != OK:
		if file.is_open():
			file.close()
		
		return
	
	var data_string: String
	
	if ConfigBus.get_bool("advanced.readable_saves"):
		data_string = "%s\n" % JSON.print(_slot_data.serialize(), "\t")
	else:
		data_string = JSON.print(_slot_data.serialize())
	
	file.store_string(data_string)
	file.close()


# Load the slot save data from its file.
func load_file() -> void:
	_slot_data.clear()
	var file: File = File.new()
	
	if not file.file_exists(FILE_PATH):
		return
	
	if file.open(FILE_PATH, File.READ) != OK:
		if file.is_open():
			file.close()
		
		return
	
	var reader: JSONReader = JSONReader.new(file.get_as_text())
	file.close()
	_validate_save_data_json(reader)
	
	if reader.is_valid():
		_slot_data.deserialize(reader.get_data())


# Push the current working save data to the slot save data.
func push_to_slot() -> void:
	var data: Dictionary = _working_data.serialize()
	_checkpoint_data.deserialize(data)
	_slot_data.deserialize(data)


# Pull the current working save data from the slot save data.
func pull_from_slot() -> void:
	var data: Dictionary = _slot_data.serialize()
	_checkpoint_data.deserialize(data)
	_working_data.deserialize(data)


# Push the current working save data to the checkpoint save data.
func push_to_checkpoint() -> void:
	_checkpoint_data.deserialize(_working_data.serialize())


# Pull the current working save data from the checkpoint save data without
# reverting its statistics save data.
func pull_from_checkpoint() -> void:
	var stats_data: Dictionary = _working_data.stats.serialize()
	_working_data.deserialize(_checkpoint_data.serialize())
	_working_data.stats.deserialize(stats_data)


# Validate save data JSON from a JSON reader.
func _validate_save_data_json(reader: JSONReader) -> void:
	reader.check_enum("format_name", [FORMAT_NAME])
	reader.check_enum("format_version", [FORMAT_VERSION])
	reader.check_enum("state", ["NEW_GAME", "NORMAL", "COMPLETED"])
	reader.check_string("level")
	reader.check_float("position_x")
	reader.check_float("position_y")
	reader.check_float("angle")
	reader.check_int("stats.time_hours")
	reader.check_int("stats.time_minutes")
	reader.check_int("stats.time_seconds")
	reader.check_float("stats.time_fraction")
	reader.check_int("stats.alert_count")
	reader.check_dictionary("scenes")
	
	if not reader.has_dictionary("flags"):
		reader.invalidate()
		return
	
	for flag in reader.get_data().flags:
		if flag.empty() or "." in flag or not reader.has_int("flags.%s" % flag):
			reader.invalidate()
			return
