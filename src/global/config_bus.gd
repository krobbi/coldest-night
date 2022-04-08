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
		args.insert(0, _cast_value(value))
		target.callv(method, args)
	
	
	# Casts a value to the configuration signal's cast type:
	func _cast_value(value):
		match cast_type:
			TYPE_BOOL:
				return true if value else false
			TYPE_INT:
				match typeof(value):
					TYPE_BOOL, TYPE_REAL, TYPE_STRING:
						return int(value)
					TYPE_INT:
						return value
					_:
						return 0
			TYPE_REAL:
				match typeof(value):
					TYPE_BOOL, TYPE_INT, TYPE_STRING:
						return float(value)
					TYPE_REAL:
						return value
					_:
						return 0.0
			TYPE_STRING:
				match typeof(value):
					TYPE_BOOL, TYPE_INT, TYPE_REAL:
						return String(value)
					TYPE_STRING:
						return value
					_:
						return ""
			_:
				return value


const FILE_PATH: String = "user://settings.cfg"

var _logger: Logger
var _should_save: bool = false
var _config_signals: Array = []
var _data: Dictionary = {
	"controls.move_up_mapping": "key.%d" % KEY_UP,
	"controls.move_down_mapping": "key.%d" % KEY_DOWN,
	"controls.move_left_mapping": "key.%d" % KEY_LEFT,
	"controls.move_right_mapping": "key.%d" % KEY_RIGHT,
	"controls.interact_mapping": "key.%d" % KEY_Z,
	"controls.change_player_mapping": "key.%d" % KEY_TAB,
	"controls.pause_mapping": "key.%d" % KEY_ESCAPE,
	"controls.toggle_fullscreen_mapping": "key.%d" % KEY_F11,
	"accessibility.legible_font": false,
	"accessibility.never_game_over": false,
	"accessibility.radar_scale": 1.0,
	"accessibility.radar_opacity": 50.0,
	"audio.master_volume": 100.0,
	"audio.music_volume": 100.0,
	"audio.sfx_volume": 100.0,
	"display.fullscreen": false,
	"display.vsync": true,
	"display.pixel_snap": false,
	"display.scale_mode": "aspect",
	"display.window_scale": 0,
	"language.locale": "auto",
	"advanced.show_advanced": false,
	"advanced.compress_saves": true,
}

# Constructor. Passes the logger to the configuration bus:
func _init(logger_ref: Logger) -> void:
	_logger = logger_ref


# Sets a configuration value from its configuration key if it exists. Marks the
# configuration values to be saved if the configuration value was changed:
func set_value(config_key: String, value) -> void:
	if _data.has(config_key) and not _strict_equals(_data[config_key], value):
		_data[config_key] = value
		_should_save = true
		
		for config_signal in _config_signals:
			if config_signal.config_key == config_key:
				config_signal.emit(value)


# Gets a configuration value from its configuration key. Returns a default value
# if the configuration key does not exist:
func get_value(config_key: String, default = null):
	return _data.get(config_key, default)


# Gets a configuration value from its configuration key cast to a bool. Returns
# a default value if the configuration key does not exist:
func get_bool(config_key: String, default: bool = false) -> bool:
	return true if _data.get(config_key, default) else false


# Gets a configuraiton value from its configuration key cast to a float. Returns
# a default value if the configuration key does not exist or if the
# configuration value cannot be cast to a float:
func get_float(config_key: String, default: float = 0.0) -> float:
	var value = _data.get(config_key, default)
	
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return float(value)
		TYPE_REAL:
			return value
		_:
			return default


# Connects a configuration value to a receiver method:
func connect_value(
		config_key: String, target: Object, method: String, cast_type: int = 0, binds: Array = []
) -> void:
	if not _data.has(config_key) or not is_instance_valid(target) or not target.has_method(method):
		return
	
	for config_signal in _config_signals:
		if config_signal.has_signature(config_key, target, method):
			return
	
	_config_signals.push_back(ConfigSignal.new(config_key, target, method, cast_type, binds))


# Disconnects a configuration value from a receiver method:
func disconnect_value(config_key: String, target: Object, method: String) -> void:
	for i in range(_config_signals.size() - 1, -1, -1):
		var config_signal: ConfigSignal = _config_signals[i]
		
		if config_signal.has_signature(config_key, target, method):
			config_signal.free()
			_config_signals.remove(i)


# Emits all configuration signals:
func broadcast_values() -> void:
	for config_key in _data:
		for config_signal in _config_signals:
			if config_signal.config_key == config_key:
				config_signal.emit(_data[config_key])


# Loads the configuration values from their file if it exists:
func load_file() -> void:
	var dir: Directory = Directory.new()
	
	if not dir.file_exists(FILE_PATH):
		return
	
	var file: ConfigFile = ConfigFile.new()
	var error: int = file.load(FILE_PATH)
	
	if error:
		_logger.err_config_load(FILE_PATH, error)
		return
	
	_should_save = false
	
	for config_key in _data:
		var config_key_parts: PoolStringArray = config_key.split(".", false, 1)
		
		if config_key_parts.size() != 2:
			continue
		
		var section: String = config_key_parts[0]
		var key: String = config_key_parts[1]
		
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
		file.set_value(section, key, _data[config_key])
	
	var error: int = file.save(FILE_PATH)
	
	if error:
		_logger.err_config_save(FILE_PATH, error)
	else:
		_should_save = false


# Destructor. Frees the configuration bus' configuration signals:
func destruct() -> void:
	for config_signal in _config_signals:
		config_signal.free()
	
	_config_signals.clear()


# Returns whether two variable-type values have the same type and value:
func _strict_equals(a, b) -> bool:
	return typeof(a) == typeof(b) and a == b
