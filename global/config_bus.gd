class_name ConfigBus
extends Object

# Configuration Bus
# The configuration bus is a global utility that handles loading, storing, and
# saving configuration values and emitting configuration signals. It can be
# accessed from any script by using 'Global.config'.

class ConfigSignal extends Object:
	
	# Configuration Signal
	# A configuration signal is a helper structure used by a configuration bus
	# that represents a connection from a configuration value to a receiver
	# method.
	
	var config_key: String
	var target: Object
	var method: String
	var cast_type: int
	var binds: Array
	
	# Constructor. Sets the configuration signal's configuration key, target,
	# method, cast type, and binds:
	func _init(
			config_key_val: String, target_ref: Object, method_val: String,
			cast_type_val: int, binds_ref: Array
	) -> void:
		config_key = config_key_val
		target = target_ref
		method = method_val
		cast_type = cast_type_val
		binds = binds_ref
	
	
	# Returns whether the configuration signal has a signature configuration
	# key, target, and method:
	func has_signature(config_key_val: String, target_ref: Object, method_val: String) -> bool:
		return config_key == config_key_val and target == target_ref and method == method_val
	
	
	# Emits the configuration signal with a value:
	func emit(value) -> void:
		var args: Array = binds.duplicate()
		args.insert(0, cast(value, cast_type))
		target.callv(method, args)
	
	
	# Casts a variable-type value to a type:
	static func cast(value, type: int):
		match type:
			TYPE_BOOL:
				return cast_bool(value)
			TYPE_INT:
				return cast_int(value)
			TYPE_REAL:
				return cast_float(value)
			TYPE_STRING:
				return cast_string(value)
			_:
				return value
	
	
	# Casts a variable-type value to a bool:
	static func cast_bool(value) -> bool:
		return true if value else false
	
	
	# Casts a variable-type value to an int:
	static func cast_int(value) -> int:
		match typeof(value):
			TYPE_BOOL, TYPE_REAL, TYPE_STRING:
				return int(value)
			TYPE_INT:
				return value
			_:
				return 0
	
	
	# Casts a variable-type value to a float:
	static func cast_float(value) -> float:
		match typeof(value):
			TYPE_BOOL, TYPE_INT, TYPE_STRING:
				return float(value)
			TYPE_REAL:
				return value
			_:
				return 0.0
	
	
	# Casts a variable-type value to a string:
	static func cast_string(value) -> String:
		match typeof(value):
			TYPE_BOOL, TYPE_INT, TYPE_REAL:
				return String(value)
			TYPE_STRING:
				return value
			_:
				return ""


const FILE_PATH: String = "user://settings.cfg"

var _should_save: bool = false
var _config_signals: Array = []
var _data: Dictionary = {
	"controls.move_up_mapping": "key.%d" % KEY_UP,
	"controls.move_down_mapping": "key.%d" % KEY_DOWN,
	"controls.move_left_mapping": "key.%d" % KEY_LEFT,
	"controls.move_right_mapping": "key.%d" % KEY_RIGHT,
	"controls.interact_mapping": "key.%d" % KEY_Z,
	"controls.pause_mapping": "key.%d" % KEY_ESCAPE,
	"controls.toggle_fullscreen_mapping": "key.%d" % KEY_F11,
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
	"debug.optimize_nightscript": false,
}

# Sets a configuration value from its configuration key if it exists. Marks the
# configuration values to be saved if the configuration value was changed:
func set_value(config_key: String, value) -> void:
	if _data.has(config_key) and not _strict_equals(_data[config_key], value):
		_data[config_key] = value
		_should_save = true
		
		for config_signal in _config_signals:
			if config_signal.config_key == config_key:
				config_signal.emit(value)


# Sets a configuration value from its configuration key as a bool. Marks the
# configuration values to be saved if the configuration value was changed:
func set_bool(config_key: String, value: bool) -> void:
	set_value(config_key, value)


# Sets a configuration value from its configuration key as an int. Marks the
# configuration values to be saved if the configuration value was changed:
func set_int(config_key: String, value: int) -> void:
	set_value(config_key, value)


# Sets a configuration value from its configuration key as a float. Marks the
# configuration values to be saved if the configuration value was changed:
func set_float(config_key: String, value: float) -> void:
	set_value(config_key, value)


# Sets a configuration value from its configuration key as a string. Marks the
# configuration values to be saved if the configuration value was changed:
func set_string(config_key: String, value: String) -> void:
	set_value(config_key, value)


# Gets a configuration value from its configuration key. Returns a default value
# if the configuration key does not exist:
func get_value(config_key: String, default = null):
	return _data.get(config_key, default)


# Gets a configuration value from its configuration key cast to a bool. Returns
# a default value if the configuration key does not exist:
func get_bool(config_key: String, default: bool = false) -> bool:
	return ConfigSignal.cast_bool(_data.get(config_key, default))


# Gets a configuration value from its configuration key cast to an int. Returns
# a default value if the configuration key does not exist:
func get_int(config_key: String, default: int = 0) -> int:
	return ConfigSignal.cast_int(_data.get(config_key, default))


# Gets a configuraiton value from its configuration key cast to a float. Returns
# a default value if the configuration key does not exist or if the
# configuration value cannot be cast to a float:
func get_float(config_key: String, default: float = 0.0) -> float:
	return ConfigSignal.cast_float(_data.get(config_key, default))


# Gets a configuration value from its configuration key cast to a string.
# Returns a default value if the configuration key does not exist:
func get_string(config_key: String, default: String = "") -> String:
	return ConfigSignal.cast_string(_data.get(config_key, default))


# Connects a configuration value to a receiver method:
func connect_value(
		config_key: String, target: Object, method: String,
		cast_type: int = TYPE_NIL, binds: Array = []
) -> void:
	if not _data.has(config_key) or not is_instance_valid(target) or not target.has_method(method):
		return
	
	for config_signal in _config_signals:
		if config_signal.has_signature(config_key, target, method):
			return
	
	_config_signals.push_back(ConfigSignal.new(config_key, target, method, cast_type, binds))


# Connects a configuration value to a receiver method cast to a bool:
func connect_bool(config_key: String, target: Object, method: String, binds: Array = []) -> void:
	connect_value(config_key, target, method, TYPE_BOOL, binds)


# Connects a configuration value to a receiver method cast to an int:
func connect_int(config_key: String, target: Object, method: String, binds: Array = []) -> void:
	connect_value(config_key, target, method, TYPE_INT, binds)


# Connects a configuration value to a receiver method cast to a float:
func connect_float(config_key: String, target: Object, method: String, binds: Array = []) -> void:
	connect_value(config_key, target, method, TYPE_REAL, binds)


# Connects a configuration value to a receiver method cast to a string:
func connect_string(config_key: String, target: Object, method: String, binds: Array = []) -> void:
	connect_value(config_key, target, method, TYPE_STRING, binds)


# Disconnects a configuration value from a receiver method:
func disconnect_value(config_key: String, target: Object, method: String) -> void:
	for i in range(_config_signals.size() - 1, -1, -1):
		var config_signal: ConfigSignal = _config_signals[i]
		
		if config_signal.has_signature(config_key, target, method):
			config_signal.free()
			_config_signals.remove(i)


# Emits all configuration signals:
func broadcast_values() -> void:
	for config_signal in _config_signals:
		config_signal.emit(_data.get(config_signal.config_key, null))


# Loads the configuration values from their file if it exists:
func load_file() -> void:
	var dir: Directory = Directory.new()
	
	if not dir.file_exists(FILE_PATH):
		return
	
	var file: ConfigFile = ConfigFile.new()
	
	if file.load(FILE_PATH) != OK:
		return
	
	_should_save = false
	
	for config_key in _data:
		var config_key_parts: PoolStringArray = config_key.split(".", false, 1)
		
		if config_key_parts.size() != 2:
			continue
		
		var section: String = config_key_parts[0]
		var key: String = config_key_parts[1]
		
		if section == "debug" and not OS.is_debug_build():
			continue
		
		if file.has_section_key(section, key):
			_data[config_key] = file.get_value(section, key, _data[config_key])
		else:
			_should_save = true


# Saves the configuration values to their file if they are marked to be saved:
func save_file() -> void:
	if not _should_save:
		return
	
	var file: ConfigFile = ConfigFile.new()
	
	for config_key in _data:
		var config_key_parts: PoolStringArray = config_key.split(".", false, 1)
		
		if config_key_parts.size() != 2:
			continue
		
		var section: String = config_key_parts[0]
		var key: String = config_key_parts[1]
		
		if section == "debug" and not OS.is_debug_build():
			continue
		
		file.set_value(section, key, _data[config_key])
	
	if file.save(FILE_PATH) == OK:
		_should_save = false


# Destructor. Frees the configuration bus' configuration signals:
func destruct() -> void:
	for config_signal in _config_signals:
		config_signal.free()
	
	_config_signals.clear()


# Returns whether two variable-type values have the same type and value:
func _strict_equals(a, b) -> bool:
	return typeof(a) == typeof(b) and a == b
