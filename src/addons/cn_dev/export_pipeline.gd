tool
extends EditorExportPlugin

# Coldest Night Export Pipeline
# The Coldest Night export pipeline is an editor export plugin that excludes,
# transforms, and adds resource files to Coldest Night when exported. It is used
# to exclude unnecessary files and optimize the file size of the exported game.

const GAME_VERSION: String = "0.4.0";
const TOOLKIT_VERSION: String = "0.0";
const USER_DIR: String = "user://";
const TEMP_DIR: String = USER_DIR + "tmp/";
const LOGS_DIR: String = USER_DIR + "logs/";
const OBFUSCATED_CHARS: String = "abcdefghijklmnopqrstuvwxyz";
const LOG_INDENT: String = "    ";

const EXCLUDE_COMMON: PoolStringArray = PoolStringArray([
	"res://addons/cn_dev/"
]);

const EXCLUDE_DEBUG: PoolStringArray = PoolStringArray([
	"res://utils/dialog/release/"
]);

const EXCLUDE_RELEASE: PoolStringArray = PoolStringArray([
	"res://utils/dialog/debug/",
	"res://utils/overworld/debug/",
	"res://utils/radar/debug/"
]);

var _dialog_compiler: Object = preload("res://addons/cn_dev/dialog_compiler.gd").new();
var _level_repacker: Object = preload("res://utils/overworld/debug/level_repacker.gd").new();
var _features: PoolStringArray = PoolStringArray();
var _debug: bool = false;
var _temp_dir: String;
var _logs_dir: String;
var _obfuscation_counter: PoolIntArray = PoolIntArray();
var _error_count: int = 0;
var _log: PoolStringArray = PoolStringArray();
var _log_indent_level: int = 0;

var _rgx_empty: RegEx = RegEx.new();
var _rgx_comment: RegEx = RegEx.new();
var _rgx_directive: RegEx = RegEx.new();
var _rgx_semicolon: RegEx = RegEx.new();
var _rgx_omit: RegEx = RegEx.new();
var _rgx_end_omit: RegEx = RegEx.new();

# Constructor. Compiles regular expressions and initializes the temp directory
# and logs directory:
func _init() -> void:
	var error: int = _rgx_empty.compile("^\\s+$");
	
	if error != OK:
		print("Failed to compile empty RegEx! Error: %d" % error);
	
	error = _rgx_comment.compile("^\\s*#");
	
	if error != OK:
		print("Failed to compile comment RegEx! Error: %d" % error);
	
	error = _rgx_directive.compile("^\\s*#\\s*warning-ignore\\s*:");
	
	if error != OK:
		print("Failed to compile directive RegEx! Error: %d" % error);
	
	error = _rgx_semicolon.compile("[;\\s]+$");
	
	if error != OK:
		print("Failed to compile semicolon RegEx! Error: %d" % error);
	
	error = _rgx_omit.compile("^\\s*#\\s*CNEP\\s*:\\s*DEBUG");
	
	if error != OK:
		print("Failed to compile omit RegEx! Error: %d" % error);
	
	error = _rgx_end_omit.compile("^\\s*#\\s*CNEP\\s*:\\s*END_DEBUG");
	
	if error != OK:
		print("Failed to compile end omit RegEx! Error: %d" % error);
	
	var dir: Directory = Directory.new();
	
	if not dir.dir_exists(USER_DIR):
		error = dir.make_dir_recursive(USER_DIR);
		
		if error != OK:
			print("Failed to make directory %s! Error: %d" % [USER_DIR, error]);
	
	if dir.dir_exists(TEMP_DIR):
		_temp_dir = TEMP_DIR;
	else:
		error = dir.make_dir(TEMP_DIR);
		
		if error == OK:
			_temp_dir = TEMP_DIR;
		else:
			_temp_dir = USER_DIR;
			print("Failed to make directory %s! Error: %d" % [TEMP_DIR, error]);
	
	if dir.dir_exists(LOGS_DIR):
		_logs_dir = LOGS_DIR;
	else:
		error = dir.make_dir(LOGS_DIR);
		
		if error == OK:
			_logs_dir = LOGS_DIR;
		else:
			_logs_dir = USER_DIR;
			print("Failed to make directory %s! Error: %d" % [LOGS_DIR, error]);


# Virtual _export_begin method. Runs when the game begins exporting. Registers
# the export features and whether the game is being exported in debug mode.
# Resets the export log if the export log is enabled:
func _export_begin(features: PoolStringArray, is_debug: bool, path: String, flags: int) -> void:
	_features = features;
	_debug = is_debug;
	
	_error_count = 0;
	
	_obfuscation_counter.resize(1);
	_obfuscation_counter[0] = 0;
	
	if _is_logging():
		_clear_log();
		_log_line("Coldest Night Export Log");
		_log_separator();
		_log_line("Export path: ------- " + path);
		_log_line("Export mode: ------- " + ("Debug" if _debug else "Release"));
		_log_line("Export flags: ------ %d" % flags);
		_log_line("Game version: ------ " + GAME_VERSION);
		_log_line("Toolkit version: --- " + TOOLKIT_VERSION);
		_log_line("Godot version: ----- ");
		
		var godot_version: Dictionary = Engine.get_version_info();
		_log_append("%d.%d.%d" % [godot_version.major, godot_version.minor, godot_version.patch]);
		
		_log_line("Export features:");
		_log_indent();
		
		for feature in _features:
			_log_line(feature);
		
		_log_dedent();
		_log_separator();


# Virtual _export_file method. Runs when the game exports a resource file.
# Excludes, transforms or adds resource files to the exported game. Logs
# information about the exported file if the export log is enabled:
func _export_file(path: String, type: String, _features: PoolStringArray) -> void:
	if _is_logging():
		_log_undent();
		_log_line("Export file: " + path);
		_log_indent();
		_log_line("File type: --- " + ("[Unknown]" if type.empty() else type));
		_log_line("Action: ------ ");
	
	for exclude in EXCLUDE_COMMON:
		if path.begins_with(exclude):
			skip();
			
			if _is_logging():
				_log_append("Exclude (Common)");
				_log_dedent();
			
			return;
	
	if _debug:
		for exclude in EXCLUDE_DEBUG:
			if path.begins_with(exclude):
				skip();
				
				if _is_logging():
					_log_append("Exclude (Debug)");
					_log_dedent();
				
				return;
		
		_debug_pipeline(path);
	else:
		for exclude in EXCLUDE_RELEASE:
			if path.begins_with(exclude):
				skip();
				
				if _is_logging():
					_log_append("Exclude (Release)");
					_log_dedent();
				
				return;
		
		_release_pipeline(path);


# Virtual _export_end method. Runs when the game finishes exporting. Finishes
# and saves the export log if the export log is enabled:
func _export_end() -> void:
	if _is_logging():
		_log_undent();
		_log_separator();
		_log_line("Export finished!");
		_log_line("Errors: %d" % _error_count);
		_save_log();
		_clear_log();


# Destructor. Destructs and frees the dialog compiler and level repacker:
func destruct() -> void:
	_dialog_compiler.destruct();
	_dialog_compiler.free();
	_level_repacker.free();


# Gets the next obfuscated path to use:
func _get_obfuscated_path(extension: String) -> String:
	var path: String = "res://";
	
	for i in range(_obfuscation_counter.size() - 1, -1, -1):
		path += OBFUSCATED_CHARS[_obfuscation_counter[i]];
	
	for i in range(_obfuscation_counter.size()):
		_obfuscation_counter[i] += 1;
		
		if _obfuscation_counter[i] < OBFUSCATED_CHARS.length():
			break;
		else:
			_obfuscation_counter[i] = 0;
			
			if i == _obfuscation_counter.size() - 1:
				_obfuscation_counter.push_back(0);
	
	return path + "." + extension;


# Gets whether the export log is enabled for the current export:
func _is_logging() -> bool:
	return _has_feature("export_log");


# Returns whether the current export has a feature:
func _has_feature(feature: String) -> bool:
	return feature in _features;


# Transforms the file extension of a path:
func _transform_extension(path: String, extension: String) -> String:
	var path_dots: PoolStringArray = path.split(".", true);
	
	if path_dots.size() > 1:
		path_dots.remove(path_dots.size() - 1);
	
	var path_no_extension: String = path_dots.join(".");
	
	if extension.empty():
		return path_no_extension;
	else:
		return path_no_extension + "." + extension;


# Remaps the current resource file to a new path. Bypasses the default remapping
# to remove unnecessary data from the remap file:
func _remap_file(from: String, to: String, data: PoolByteArray) -> void:
	skip();
	
	add_file(to, data, false);
	
	var remap_data: PoolByteArray = ('path="' + to.c_escape() + '"').to_utf8();
	add_file(from + ".remap", remap_data, false);


# Remps a current resource file with a resource type to a binary format. Returns
# whether the resource was remapped successfully:
func _remap_resource(from: String, to: String, resource: Resource, extension: String) -> bool:
	var temp_path: String = _temp_dir + "tmp." + extension;
	var error: int = ResourceSaver.save(
			temp_path, resource, ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES
	);
	
	if error != OK:
		if _is_logging():
			_log_line("Failed to convert resource to %s format! Error: %d" % [extension, error]);
		
		_error_count += 1;
		return false;
	
	var file: File = File.new();
	error = file.open(temp_path, File.READ);
	
	if error != OK:
		if file.is_open():
			file.close();
		
		if _is_logging():
			_log_line("Failed to read converted resource! Error: %d" % error);
		
		_error_count += 1;
		return false;
	
	var data: PoolByteArray = file.get_buffer(file.get_len());
	file.close();
	
	_remap_file(from, to, data);
	return true;


# Converts a GDScript resource to a minified form. Omits debug-only code and
# removes some unnecessary tokens from parsed scripts:
func _minify_script(script: GDScript) -> GDScript:
	if _debug or not script.has_source_code():
		return script;
	
	var omitting: bool = false;
	var lines: PoolStringArray = script.get_source_code().split("\n", false);
	var output: PoolStringArray = PoolStringArray();
	
	for i in range(lines.size()):
		var line: String = lines[i].strip_edges(false, true);
		
		# Remove empty and whitespace-only lines:
		if line.empty() or _rgx_empty.search(line) != null:
			continue;
		
		# Omit and end ommitting debug only code:
		if omitting:
			if _rgx_end_omit.search(line) != null:
				omitting = false;
			
			continue;
		elif _rgx_omit.search(line) != null:
			omitting = true;
			continue;
		
		# Remove non-directive comment-only lines:
		if _rgx_comment.search(line) != null and _rgx_directive.search(line) == null:
			continue;
		
		# Remove trailing semicolons and whitespace:
		line = _rgx_semicolon.sub(line, "");
		
		output.push_back(line);
	
	# Create a new GDScript instance so we don't clobber the source code:
	var minified_script: GDScript = GDScript.new();
	minified_script.set_source_code(output.join("\n"));
	return minified_script;


# Export pipeline for debug mode:
func _debug_pipeline(path: String) -> void:
	if false:
		pass;
	else:
		if _is_logging():
			_log_append("Keep");
			_log_dedent();


# Export pipeline for release mode:
func _release_pipeline(path: String) -> void:
	if path.match("res://assets/data/dialogs/*.txt"):
		_release_compile_dialog(path);
	elif path.match("res://levels/*.tscn"):
		_release_repack_level(path);
	elif path.match("*.gd"):
		_release_parse_script(path);
	elif path.match("*.tres"):
		_release_serialize_resource(path);
	elif path.match("*.tscn"):
		_release_serialize_scene(path);
	else:
		if _is_logging():
			_log_append("Keep");
			_log_dedent();


# Compiles a dialog source file for release mode:
func _release_compile_dialog(path: String) -> void:
	skip();
	
	var compiled_path: String = _transform_extension(path, "dtc");
	var data: PoolByteArray = _dialog_compiler.compile_path(path);
	add_file(compiled_path, data, false);
	
	if _is_logging():
		_log_append("Compile dialog");
		_log_indent();
		_log_line("Compiled path: " + compiled_path);
		_log_dedent();
		_log_dedent();


# Repacks a level's scene for release mode:
func _release_repack_level(path: String) -> void:
	var repacked_path: String = _get_obfuscated_path("scn");
	var repacked_scene: PackedScene = _level_repacker.repack(load(path));
	
	if _is_logging():
		_log_append("Repack level");
		_log_indent();
	
	var remapped: bool = _remap_resource(path, repacked_path, repacked_scene, "scn");
	
	if _is_logging():
		if remapped:
			_log_line("Repacked path: " + repacked_path);
		
		_log_dedent();
		_log_dedent();


# Parses GDScript to minified bytecode for release mode:
func _release_parse_script(path: String) -> void:
	var parsed_path: String = _get_obfuscated_path("gdc");
	var parsed_script: GDScript = _minify_script(load(path));
	
	_remap_file(path, parsed_path, parsed_script.get_as_byte_code());
	
	if _is_logging():
		_log_append("Parse script");
		_log_indent();
		_log_line("Parsed path: " + parsed_path);
		_log_dedent();
		_log_dedent();


# Serializes a resource to a binary format for release mode:
func _release_serialize_resource(path: String) -> void:
	var serialized_path: String = _get_obfuscated_path("res");
	var resource: Resource = load(path);
	
	if _is_logging():
		_log_append("Serialize resource");
		_log_indent();
	
	var remapped: bool = _remap_resource(path, serialized_path, resource, "res");
	
	if _is_logging():
		if remapped:
			_log_line("Serialized path: " + serialized_path)
		
		_log_dedent();
		_log_dedent();


# Serializes a scene to a binary format for release mode:
func _release_serialize_scene(path: String) -> void:
	var serialized_path: String = _get_obfuscated_path("scn");
	var scene: PackedScene = load(path);
	
	if _is_logging():
		_log_append("Serialize scene");
		_log_indent();
	
	var remapped: bool = _remap_resource(path, serialized_path, scene, "scn");
	
	if _is_logging():
		if remapped:
			_log_line("Serialized path: " + serialized_path);
		
		_log_dedent();
		_log_dedent();


# Clears the export log:
func _clear_log() -> void:
	_log.resize(0);
	_log_undent();


# Indents the export log:
func _log_indent() -> void:
	_log_indent_level += 1;


# Dedents the export log:
func _log_dedent() -> void:
	_log_indent_level -= 1;


# Resets the export log's indent level:
func _log_undent() -> void:
	_log_indent_level = 0;


# Logs a line to the export log:
func _log_line(line: String) -> void:
	_log.push_back(LOG_INDENT.repeat(_log_indent_level) + line);


# Logs a line separator to the export log:
func _log_separator() -> void:
	_log.push_back("------------------------");


# Appends text to the current line of the export log:
func _log_append(text: String) -> void:
	if _log.empty():
		_log_line(text);
	else:
		_log[_log.size() - 1] += text;


# Saves the export log to its file:
func _save_log() -> void:
	var file: File = File.new();
	var log_path: String = _logs_dir + "export.log";
	var error: int = file.open(log_path, File.WRITE);
	
	if error == OK:
		for line in _log:
			file.store_line(line);
		
		file.close();
	else:
		if file.is_open():
			file.close();
		
		print("Failed to write to file %s! Error: %d" % [log_path, error]);
