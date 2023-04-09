extends Node

# Configuration Bus
# The configuration bus is an autoload scene that handles loading, storing, and
# saving configuration values and emitting configuration events. The
# configuration bus can be accessed from any script by using `ConfigBus`.

const FILE_PATH: String = "user://settings.cfg"

var _should_save: bool = false
var _connections: Array[ConfigConnection] = []
var _data: Dictionary = {
	"controls.move_up_mapping": "auto",
	"controls.move_down_mapping": "auto",
	"controls.move_left_mapping": "auto",
	"controls.move_right_mapping": "auto",
	"controls.interact_mapping": "auto",
	"controls.pause_mapping": "auto",
	"controls.toggle_fullscreen_mapping": "auto",
	"accessibility.reduced_motion": false,
	"accessibility.subtitles": true,
	"accessibility.tooltips": true,
	"accessibility.never_game_over": false,
	"accessibility.pause_opacity": 80.0,
	"accessibility.contrast_boost": 0.0,
	"accessibility.color_grading": "none",
	"audio.mute": false,
	"audio.master_volume": 100.0,
	"audio.music_volume": 100.0,
	"audio.sfx_volume": 100.0,
	"display.fullscreen": false,
	"display.vsync": true,
	"display.pixel_snap": false,
	"display.window_scale": 0,
	"font.family": "coldnight",
	"font.size": 20,
	"language.locale": "auto",
	"radar.show_world_cones": false,
	"radar.normal_cone_color": "blue",
	"radar.caution_cone_color": "yellow",
	"radar.alert_cone_color": "red",
	"radar.visible": true,
	"radar.scale": 100.0,
	"radar.background_color": "maroon",
	"radar.background_opacity": 50.0,
	"radar.wall_color": "green",
	"radar.floor_color": "dark_green",
	"radar.barrier_color": "red",
	"radar.player_color": "white",
	"radar.guard_color": "red",
	"radar.collectable_color": "orange",
	"advanced.show_advanced": false,
	"advanced.readable_saves": false,
	"debug.show_state_labels": false,
}

# Run when the configuration bus enters the scene tree. Load the configuration
# bus.
func _ready() -> void:
	load_file()


# Run when the configuration bus exits the scene tree. Save the configuration
# bus.
func _exit_tree() -> void:
	save_file()


# Set a configuration value from its configuration key.
func set_value(config_key: String, value: Variant) -> void:
	if not _data.has(config_key):
		return
	
	if not is_same(_data[config_key], value):
		_data[config_key] = value
		_should_save = true
	else:
		return
	
	for i in range(_connections.size() - 1, -1, -1):
		var connection: ConfigConnection = _connections[i]
		
		if connection.get_config_key() == config_key:
			connection.emit(value)
		
		if connection.is_severed():
			_connections.remove_at(i)


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
func get_value(config_key: String, default: Variant = null) -> Variant:
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


# Subscribe a callable to a configuration event.
func subscribe(config_key: String, callable: Callable, cast_type: int = TYPE_NIL) -> void:
	if not _data.has(config_key):
		return
	
	unsubscribe(config_key, callable)
	var connection: ConfigConnection = ConfigConnection.new(config_key, callable, cast_type)
	_connections.push_back(connection)
	connection.emit(_data.get(config_key))


# Subscribe a callable to a bool configuration event.
func subscribe_bool(config_key: String, callable: Callable) -> void:
	subscribe(config_key, callable, TYPE_BOOL)


# Subscribe a callable to an int configuration event.
func subscribe_int(config_key: String, callable: Callable) -> void:
	subscribe(config_key, callable, TYPE_INT)


# Subscribe a callable to a float configuration event.
func subscribe_float(config_key: String, callable: Callable) -> void:
	subscribe(config_key, callable, TYPE_FLOAT)


# Subscribe a callable to a string configuration event.
func subscribe_string(config_key: String, callable: Callable) -> void:
	subscribe(config_key, callable, TYPE_STRING)


# Subscribe a callable with a node target to a configuration event and
# automatically unsubscribe the target node when it exits the scene tree.
func subscribe_node(config_key: String, callable: Callable, cast_type: int = TYPE_NIL) -> void:
	subscribe(config_key, callable, cast_type)
	
	var node: Node = callable.get_object() as Node
	
	if not is_instance_valid(node):
		return
	
	if not node.tree_exiting.is_connected(_unsubscribe_node):
		if node.tree_exiting.connect(_unsubscribe_node.bind(node), CONNECT_ONE_SHOT) != OK:
			if node.tree_exiting.is_connected(_unsubscribe_node):
				node.tree_exiting.disconnect(_unsubscribe_node)


# Subscribe a callable with a node target to a bool configuration event.
func subscribe_node_bool(config_key: String, callable: Callable) -> void:
	subscribe_node(config_key, callable, TYPE_BOOL)


# Subscribe a callable with a node target to an int configuration event.
func subscribe_node_int(config_key: String, callable: Callable) -> void:
	subscribe_node(config_key, callable, TYPE_INT)


# Subscribe a callable with a node target to a float configuration event.
func subscribe_node_float(config_key: String, callable: Callable) -> void:
	subscribe_node(config_key, callable, TYPE_FLOAT)


# Subscribe a callable with a node target to a string configuration event.
func subscribe_node_string(config_key: String, callable: Callable) -> void:
	subscribe_node(config_key, callable, TYPE_STRING)


# Unsubscribe a callable from a configuration event.
func unsubscribe(config_key: String, callable: Callable) -> void:
	for i in range(_connections.size() - 1, -1, -1):
		var connection: ConfigConnection = _connections[i]
		
		if connection.has_signature(config_key, callable):
			connection.sever()
		
		if connection.is_severed():
			_connections.remove_at(i)


# Save the configuration bus to its file.
func save_file() -> void:
	if not _should_save:
		return
	
	var file: ConfigFile = ConfigFile.new()
	
	for config_key in _data:
		if config_key.begins_with("debug.") and not OS.is_debug_build():
			continue
		
		var config_key_parts: PackedStringArray = config_key.split(".", false, 1)
		
		if config_key_parts.size() != 2:
			continue
		
		file.set_value(config_key_parts[0], config_key_parts[1], _data[config_key])
	
	if file.save(FILE_PATH) == OK:
		_should_save = false


# Load the configuration bus from its file.
func load_file() -> void:
	var file: ConfigFile = ConfigFile.new()
	
	if file.load(FILE_PATH) != OK:
		return
	
	_should_save = false
	
	for config_key in _data:
		if config_key.begins_with("debug.") and not OS.is_debug_build():
			continue
		
		var config_key_parts: PackedStringArray = config_key.split(".", false, 1)
		
		if config_key_parts.size() != 2:
			continue
		
		var section: String = config_key_parts[0]
		var key: String = config_key_parts[1]
		
		if file.has_section_key(section, key):
			_data[config_key] = file.get_value(section, key, _data[config_key])
		else:
			_should_save = true


# Unsubscribe a node from all of its subscribed configuration events.
func _unsubscribe_node(node: Node) -> void:
	for i in range(_connections.size() - 1, -1, -1):
		var connection: ConfigConnection = _connections[i]
		
		if connection.get_target() == node:
			connection.sever()
		
		if connection.is_severed():
			_connections.remove_at(i)
