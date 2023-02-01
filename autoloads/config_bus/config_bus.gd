extends Node

# Configuration Bus
# The configuration bus is an autoload scene that handles loading, storing, and
# saving configuration values and emitting configuration events. The
# configuration bus can be accessed from any script by using `ConfigBus`.

const FILE_PATH: String = "user://settings.cfg"

var _should_save: bool = false
var _connections: Array = []
var _data: Dictionary = {
	"controls.move_up_mapping": "auto",
	"controls.move_down_mapping": "auto",
	"controls.move_left_mapping": "auto",
	"controls.move_right_mapping": "auto",
	"controls.interact_mapping": "auto",
	"controls.pause_mapping": "auto",
	"controls.toggle_fullscreen_mapping": "auto",
	"accessibility.legible_font": false,
	"accessibility.reduced_motion": false,
	"accessibility.tooltips": true,
	"accessibility.never_game_over": false,
	"accessibility.radar_scale": 1.0,
	"accessibility.radar_opacity": 50.0,
	"accessibility.pause_opacity": 80.0,
	"accessibility.color_grading": "none",
	"audio.mute": false,
	"audio.master_volume": 100.0,
	"audio.music_volume": 100.0,
	"audio.sfx_volume": 100.0,
	"display.fullscreen": false,
	"display.vsync": true,
	"display.pixel_snap": false,
	"display.window_scale": 0,
	"display.scale_mode": "aspect",
	"display.display_barks": true,
	"language.locale": "auto",
	"advanced.show_advanced": false,
	"advanced.readable_saves": false,
	"debug.optimize_nightscript": false,
}

# Set a configuration value from its configuration key.
func set_value(config_key: String, value) -> void:
	if(
			not _data.has(config_key)
			or typeof(_data[config_key]) == typeof(value) and _data[config_key] == value):
		return
	
	_data[config_key] = value
	_should_save = true
	
	for i in range(_connections.size() - 1, -1, -1):
		var connection: ConfigConnection = _connections[i]
		
		if connection.get_config_key() == config_key:
			connection.emit(value)
		
		if connection.is_severed():
			_connections.remove(i)


# Set a bool configuration value from its configuration key.
func set_bool(config_key: String, value: bool) -> void:
	set_value(config_key, value)


# Set an int configuration value from its configuration key.
func set_int(config_key: String, value: int) -> void:
	set_value(config_key, value)


# Set a float configuration value from its configuration key.
func set_float(config_key: String, value: float) -> void:
	set_value(config_key, value)


# Set a string configuraton value from its configuraton key.
func set_string(config_key: String, value: String) -> void:
	set_value(config_key, value)


# Get a configuration value from its configuration key.
func get_value(config_key: String, default = null):
	return _data.get(config_key, default)


# Get a configuration bool from its configuration key.
func get_bool(config_key: String, default: bool = false) -> bool:
	return ConfigConnection.cast_bool(get_value(config_key, default))


# Get a configuration int from its configuration key.
func get_int(config_key: String, default: int = 0) -> int:
	return ConfigConnection.cast_int(get_value(config_key, default))


# Get a configuration float from its configuration key.
func get_float(config_key: String, default: float = 0.0) -> float:
	return ConfigConnection.cast_float(get_value(config_key, default))


# Get a configuration string from its configuration key.
func get_string(config_key: String, default: String = "") -> String:
	return ConfigConnection.cast_string(get_value(config_key, default))


# Subscribe a target to a configuration event.
func subscribe(
		config_key: String, target: Object, method: String,
		cast_type: int = TYPE_NIL, binds: Array = []) -> void:
	if not _data.has(config_key) or not target or not target.has_method(method):
		return
	
	unsubscribe(config_key, target, method)
	_connections.push_back(ConfigConnection.new(config_key, target, method, cast_type, binds))


# Subscribe a target to a bool configuration event.
func subscribe_bool(config_key: String, target: Object, method: String, binds: Array = []) -> void:
	subscribe(config_key, target, method, TYPE_BOOL, binds)


# Subscribe a target to an int configuration event.
func subscribe_int(config_key: String, target: Object, method: String, binds: Array = []) -> void:
	subscribe(config_key, target, method, TYPE_INT, binds)


# Subscribe a target to a float configuration event.
func subscribe_float(config_key: String, target: Object, method: String, binds: Array = []) -> void:
	subscribe(config_key, target, method, TYPE_REAL, binds)


# Subscribe a target to a string configuration event.
func subscribe_string(
		config_key: String, target: Object, method: String, binds: Array = []) -> void:
	subscribe(config_key, target, method, TYPE_STRING, binds)


# Subscribe a target node to a configuration event and automatically unsubscribe
# the target node when it exits the scene tree.
func subscribe_node(
		config_key: String, target: Node, method: String,
		cast_type: int = TYPE_NIL, binds: Array = []) -> void:
	subscribe(config_key, target, method, cast_type, binds)
	
	if not target.is_connected("tree_exiting", self, "_unsubscribe_node"):
		if target.connect(
				"tree_exiting", self, "_unsubscribe_node", [target], CONNECT_ONESHOT) != OK:
			if target.is_connected("tree_exiting", self, "_unsubscribe_node"):
				target.disconnect("tree_exiting", self, "_unsubscribe_node")


# Subscribe a target node to a bool configuration event.
func subscribe_node_bool(
		config_key: String, target: Node, method: String, binds: Array = []) -> void:
	subscribe_node(config_key, target, method, TYPE_BOOL, binds)


# Subscribe a target node to an int configuration event.
func subscribe_node_int(
		config_key: String, target: Node, method: String, binds: Array = []) -> void:
	subscribe_node(config_key, target, method, TYPE_INT, binds)


# Subscribe a target node to a float configuration event.
func subscribe_node_float(
		config_key: String, target: Node, method: String, binds: Array = []) -> void:
	subscribe_node(config_key, target, method, TYPE_REAL, binds)


# Subscribe a target node to a string configuration event.
func subscribe_node_string(
		config_key: String, target: Node, method: String, binds: Array = []) -> void:
	subscribe_node(config_key, target, method, TYPE_STRING, binds)


# Unsubscribe a target from a configuration event.
func unsubscribe(config_key: String, target: Object, method: String) -> void:
	for i in range(_connections.size() - 1, -1, -1):
		var connection: ConfigConnection = _connections[i]
		
		if connection.has_signature(config_key, target, method):
			connection.sever()
		
		if connection.is_severed():
			_connections.remove(i)


# Emit all configuration events.
func broadcast() -> void:
	for i in range(_connections.size() - 1, -1, -1):
		var connection: ConfigConnection = _connections[i]
		connection.emit(_data.get(connection.get_config_key()))
		
		if connection.is_severed():
			_connections.remove(i)


# Save the configuration bus to its file.
func save_file() -> void:
	if not _should_save:
		return
	
	var file: ConfigFile = ConfigFile.new()
	
	for config_key in _data:
		if OS.is_debug_build() and config_key.begins_with("debug."):
			continue
		
		var config_key_parts: PoolStringArray = config_key.split(".", false, 1)
		
		if config_key_parts.size() != 2:
			continue
		
		file.set_value(config_key_parts[0], config_key_parts[1], _data[config_key])
	
	if file.save(FILE_PATH) == OK:
		_should_save = false


# Load the configuration bus from its file.
func load_file() -> void:
	var dir: Directory = Directory.new()
	
	if not dir.file_exists(FILE_PATH):
		return
	
	var file: ConfigFile = ConfigFile.new()
	
	if file.load(FILE_PATH) != OK:
		return
	
	_should_save = false
	
	for config_key in _data:
		if OS.is_debug_build() and config_key.begins_with("debug."):
			continue
		
		var config_key_parts: PoolStringArray = config_key.split(".", false, 1)
		
		if config_key_parts.size() != 2:
			continue
		
		var section: String = config_key_parts[0]
		var key: String = config_key_parts[1]
		
		if file.has_section_key(section, key):
			_data[config_key] = file.get_value(section, key, _data[config_key])
		else:
			_should_save = true


# Unsubscribe a node from all of its subscribed configuration events.
func _unsubscribe_node(target: Node) -> void:
	for i in range(_connections.size() - 1, -1, -1):
		var connection: ConfigConnection = _connections[i]
		
		if connection.get_target() == target:
			connection.sever()
		
		if connection.is_severed():
			_connections.remove(i)
