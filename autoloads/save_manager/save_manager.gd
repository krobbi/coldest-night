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
	EventBus.save_state_request.emit()
	push_to_slot()
	save_file()


# Save the slot save data to its file.
func save_file() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	
	if not dir.dir_exists(SAVES_DIR):
		if dir.make_dir(SAVES_DIR) != OK:
			return
	
	var file: FileAccess = FileAccess.open(FILE_PATH, FileAccess.WRITE)
	
	if not file:
		return
	
	var data_string: String
	
	if ConfigBus.get_bool("advanced.readable_saves"):
		data_string = "%s\n" % JSON.stringify(_slot_data.serialize(), "\t", false)
	else:
		data_string = JSON.stringify(_slot_data.serialize())
	
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
	validator.check_string_value("format_name", FORMAT_NAME)
	validator.check_int_value("format_version", FORMAT_VERSION)
	validator.check_string_enum("state", ["NEW_GAME", "NORMAL", "COMPLETED"])
	validator.check_string("level")
	validator.check_vector2("position")
	validator.check_float("angle")
	
	validator.enter_dictionary("stats")
	_validate_stats_save_data(validator)
	validator.exit()
	
	validator.enter_dictionary("flags")
	
	for flag in validator.get_keys():
		validator.check_int(flag)
	
	validator.exit()
	
	validator.enter_dictionary("levels")
	
	for level_path in validator.get_keys():
		validator.enter_dictionary(level_path)
		_validate_level_save_data(validator)
		validator.exit()
	
	validator.exit()


# Validate stats save data from a JSON validator.
func _validate_stats_save_data(validator: JSONValidator) -> void:
	validator.check_int("time_hours")
	validator.check_int("time_minutes")
	validator.check_int("time_seconds")
	validator.check_float("time_fraction")
	validator.check_int("alert_count")


# Validate level save data from a JSON validator.
func _validate_level_save_data(validator: JSONValidator) -> void:
	validator.enter_array("entities")
	
	for index in validator.get_keys():
		validator.enter_dictionary(index)
		_validate_entity_save_data(validator)
		validator.exit()
	
	validator.exit()


# Validate entity save data from a JSON validator.
func _validate_entity_save_data(validator: JSONValidator) -> void:
	validator.check_string("scene")
	validator.check_string("parent")
	
	if validator.has_property("position"):
		validator.check_vector2("position")
	
	if validator.has_property("data"):
		validator.check_dictionary("data")
