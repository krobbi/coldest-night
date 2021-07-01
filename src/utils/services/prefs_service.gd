class_name PrefsService
extends Object

# Preferences Service
# The preferences service is a service object that manages loading, storing and
# saving the user's settings. It behaves only as a data store and does not apply
# the preferences to the game. Ideally, the preferences service should be
# accessed by proxy through other functions to ensure that the stored
# preferences accurately reflect the user's settings. A global instance of the
# preferences service can be accessed from any script by using the identifier
# 'Global.prefs'.

signal pref_changed(section, key, value);

const FILE_PATH: String = "user://settings.cfg";
const DEFAULT_PREFS: Dictionary = {
	"display": {
		"window_mode": "windowed",
		"scale_mode": "aspect",
		"window_scale": 0
	}
};

var _data: Dictionary = DEFAULT_PREFS;
var _should_save_data: bool = false;


# Sets a preference from its section and key if it exists. Marks the preferences
# to be saved and emits a signal if the preference was changed:
func set_pref(section: String, key: String, value) -> void:
	if has_pref(section, key) and _data[section][key] != value:
		_data[section][key] = value;
		_should_save_data = true;
		emit_signal("pref_changed", section, key, value);


# Gets a preference from its section and key. Returns a default value if the
# preference does not exist:
func get_pref(section: String, key: String, default = null):
	return _data[section][key] if has_pref(section, key) else default;


# Gets whether a preference exists from its section and key:
func has_pref(section: String, key: String) -> bool:
	return DEFAULT_PREFS.has(section) and DEFAULT_PREFS[section].has(key);


# Saves the preferences to their file if they are marked to be saved:
func save_file() -> void:
	if not _should_save_data:
		return;
	
	var file: ConfigFile = ConfigFile.new();
	
	for section in DEFAULT_PREFS.keys():
		for key in DEFAULT_PREFS[section].keys():
			file.set_value(section, key, _data[section][key]);
	
	var error: int = file.save(FILE_PATH);
	
	if error == OK:
		_should_save_data = false;
	else:
		print("Failed to save settings to %s! Error: %d" % [FILE_PATH, error]);


# Loads the preferences from their file:
func load_file() -> void:
	var dir: Directory = Directory.new();
	
	if not dir.file_exists(FILE_PATH):
		_should_save_data = true; # Provide user with a preferences file.
		return;
	
	var file: ConfigFile = ConfigFile.new();
	var error: int = file.load(FILE_PATH);
	
	if error == OK:
		_should_save_data = false; # Successfully loaded a valid file.
		
		for section in DEFAULT_PREFS.keys():
			for key in DEFAULT_PREFS[section].keys():
				if file.has_section_key(section, key):
					_data[section][key] = file.get_value(section, key, DEFAULT_PREFS[section][key]);
				else:
					_should_save_data = true; # File has missing preferences.
	else:
		_should_save_data = false; # Avoid overwriting the preferences file.
