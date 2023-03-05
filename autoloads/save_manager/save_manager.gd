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
	var validator: JSONValidator = JSONValidator.new()
	validator.from_path(FILE_PATH)
	_validate_save_data(validator)
	
	if validator.is_valid():
		_slot_data.deserialize(validator.get_root_data())


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


# Validate save data from a JSON validator.
func _validate_save_data(validator: JSONValidator) -> void:
	validator.check_enum("format_name", [FORMAT_NAME])
	validator.check_enum("format_version", [FORMAT_VERSION])
	validator.check_enum("state", ["NEW_GAME", "NORMAL", "COMPLETED"])
	validator.check_string("level")
	validator.check_float("position_x")
	validator.check_float("position_y")
	validator.check_float("angle")
	
	validator.enter_dictionary("stats") # Begin stats.
	validator.check_int("time_hours")
	validator.check_int("time_minutes")
	validator.check_int("time_seconds")
	validator.check_float("time_fraction")
	validator.check_int("alert_count")
	validator.exit() # End stats.
	
	validator.enter_dictionary("flags") # Begin flags.
	
	for key in validator.get_keys():
		validator.check_int(key)
	
	validator.exit() # End flags.
	
	validator.enter_dictionary("scenes") # Begin scene object array dictionary.
	
	for key in validator.get_keys():
		validator.enter_array(key) # Begin scene object array.
		
		for index in validator.get_keys():
			validator.enter_dictionary(index) # Begin scene object.
			validator.check_string("filename")
			validator.check_string("parent")
			
			if validator.has_property("position_x") or validator.has_property("position_y"):
				validator.check_float("position_x")
				validator.check_float("position_y")
			
			if validator.has_property("data"):
				validator.check_dictionary("data")
			
			validator.exit() # End scene object.
		
		validator.exit() # End scene object array.
	
	validator.exit() # End scene object array dictionary.
