extends EditorExportPlugin

# Coldest Night Development Toolkit Build Pipeline
# The Coldest Night Development Toolkit build pipeline is an editor export
# plugin that excludes, transforms, and adds resource files to Coldest Night
# when exported in release mode. It is used to optimize the file size and
# performance of the game in release builds.

class ObfuscationCounter extends Reference:
	
	# Obfuscation Counter
	# An obfuscation counter is a helper structure used by the Coldest Night
	# Development Toolkit build pipeline that generates unique obfuscated
	# strings.
	
	const OBFUSCATED_CHARS: String = "abcdefghijklmnopqrstuvwxyz_"
	const OBFUSCATED_CHARS_EXT: String = "%s0123456789" % OBFUSCATED_CHARS
	
	var _counter: PoolIntArray = PoolIntArray()

	# Constructor. Resets the obfuscation counter:
	func _init() -> void:
		reset()
	
	
	# Resets the obfuscation counter:
	func reset() -> void:
		_counter.resize(1)
		_counter[0] = 0
	
	
	# Gets the next obfuscated string from the obfuscation counter:
	func next() -> String:
		var output: String = ""
		
		for i in range(_counter.size() - 1, -1, -1):
			output += OBFUSCATED_CHARS_EXT[_counter[i]]
		
		for i in range(_counter.size()):
			_counter[i] += 1
			
			var base: int = OBFUSCATED_CHARS.length()
			
			if i < _counter.size() - 1:
				base = OBFUSCATED_CHARS_EXT.length()
			
			if _counter[i] < base:
				break
			else:
				_counter[i] = 0
				
				if i == _counter.size() - 1:
					_counter.push_back(0)
		
		return output


const TEMP_DIR: String = "user://tmp/"

const EXCLUDE_COMMON: PoolStringArray = PoolStringArray([
	"res://.vscode/",
])

const EXCLUDE_RELEASE: PoolStringArray = PoolStringArray([
	"res://addons/cn_dev/",
	"res://utils/nightscript/compiler/",
	"res://utils/nightscript/debug/",
])

var _nightscript_compiler: Reference = preload(
		"res://utils/nightscript/compiler/ns_compiler.gd"
).new()
var _script_counter: ObfuscationCounter = ObfuscationCounter.new()
var _resource_counter: ObfuscationCounter = ObfuscationCounter.new()
var _scene_counter: ObfuscationCounter = ObfuscationCounter.new()
var _whitespace_regex: RegEx = _create_regex("^\\s+$")
var _debug_begin_regex: RegEx = _create_regex("^\\s*#\\s*DEBUG\\s*:\\s*BEGIN\\s*$")
var _debug_end_regex: RegEx = _create_regex("^\\s*#\\s*DEBUG\\s*:\\s*END\\s*$")
var _is_debug: bool = false

# Virtual _export_begin method. Runs when the game begins exporting. Sets
# whether the game is being exported in debug mode, resets the Coldest Night
# Development Toolkit build pipeline's obfuscation counters and creates the
# temporary directory if the game is being exported in release mode:
func _export_begin(_features: PoolStringArray, is_debug: bool, _path: String, _flags: int) -> void:
	_is_debug = is_debug
	_script_counter.reset()
	_resource_counter.reset()
	_scene_counter.reset()
	
	if not _is_debug:
		var dir: Directory = Directory.new()
		
		if not dir.dir_exists(TEMP_DIR):
			dir.make_dir(TEMP_DIR) # warning-ignore: RETURN_VALUE_DISCARDED


# Virtual _export_file method. Runs when the game exports a resource file.
# Excludes, transforms, or adds resource files to the exported game in release
# mode:
func _export_file(path: String, _type: String, _features: PoolStringArray) -> void:
	for exclude in EXCLUDE_COMMON:
		if path.begins_with(exclude):
			skip()
			return
	
	if _is_debug:
		return
	
	for exclude in EXCLUDE_RELEASE:
		if path.begins_with(exclude):
			skip()
			return
	
	if path.match("res://assets/data/nightscript/*.ns"):
		_pipe_compile_nightscript(path)
	if path.match("res://assets/data/credits/credits_*.txt"):
		_pipe_move_credits(path)
	elif path.match("*.gd"):
		_pipe_parse_script(path)
	elif path.match("*.tres"):
		_pipe_convert_resource(path)
	elif path.match("*.tscn"):
		_pipe_convert_scene(path)


# Creates a new compiled RegEx from a regular expression pattern:
func _create_regex(pattern: String) -> RegEx:
	var regex: RegEx = RegEx.new()
	regex.compile(pattern) # warning-ignore: RETURN_VALUE_DISCARDED
	return regex


# Remaps the current resource file to a new path. Bypasess the default remapping
# to remove unnecessary data from the remap file:
func _remap_file(source_path: String, target_path: String, file_data: PoolByteArray) -> void:
	skip()
	add_file(target_path, file_data, false)
	add_file("%s.remap" % source_path, ('path="%s"' % target_path.c_escape()).to_utf8(), false)


# Remaps the current text resource file to a binary resource file:
func _remap_resource(source_path: String, target_path: String) -> void:
	var target_path_parts: PoolStringArray = target_path.split(".")
	var target_extension: String = target_path_parts[-1] if target_path_parts.size() > 1 else "res"
	var temp_path: String = "%stmp.%s" % [TEMP_DIR, target_extension]
	var resource: Resource = load(source_path)
	var error: int = ResourceSaver.save(
			temp_path, resource, ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES
	)
	
	if error:
		return
	
	var file: File = File.new()
	error = file.open(temp_path, File.READ)
	
	if error:
		if file.is_open():
			file.close()
			
		return
	
	var file_data: PoolByteArray = file.get_buffer(file.get_len())
	file.close()
	_remap_file(source_path, target_path, file_data)


# Converts a GDScript resource to a minified form with debug-only code omitted:
func _minify_script(script: GDScript) -> GDScript:
	if _is_debug or not script.has_source_code():
		return script
	
	var is_debug_code: bool = false
	var output: PoolStringArray = PoolStringArray()
	
	for line in script.get_source_code().split("\n", false):
		line = line.strip_edges(false, true)
		
		if line.empty() or _whitespace_regex.search(line):
			continue
		
		if is_debug_code:
			if _debug_end_regex.search(line):
				is_debug_code = false
			
			continue
		elif _debug_begin_regex.search(line):
			is_debug_code = true
			continue
		
		output.push_back(line)
	
	# Create a new GDScript instance so we don't clobber the source code:
	var minified_script: GDScript = GDScript.new()
	minified_script.set_source_code(output.join("\n"))
	return minified_script


# Compiles a NightScript source file for release mode:
func _pipe_compile_nightscript(path: String) -> void:
	skip()
	var path_parts: PoolStringArray = path.replace("res://assets/data/nightscript/", "").split("/")
	
	if path_parts.size() < 2:
		return
	
	var locale: String = path_parts[0]
	path_parts.remove(0)
	
	if locale == "global":
		locale = "g"
	
	var compiled_path: String = "res://%s.%sc" % [locale, path_parts.join(".")]
	add_file(compiled_path, _nightscript_compiler.compile_path(path, true), false)


# Moves a credits file for release mode:
func _pipe_move_credits(path: String) -> void:
	skip()
	
	var file: File = File.new()
	var error: int = file.open(path, File.READ)
	var file_data: PoolByteArray = PoolByteArray()
	
	if not error:
		file_data = file.get_buffer(file.get_len())
		file.close()
	elif file.is_open():
		file.close()
	
	var moved_path: String = "res://%s" % path.replace("res://assets/data/credits/credits_", "")
	add_file(moved_path, file_data, false)


# Parses a GDScript source file to minified bytecode for release mode:
func _pipe_parse_script(path: String) -> void:
	var parsed_path: String = "res://%s.gdc" % _script_counter.next()
	_remap_file(path, parsed_path, _minify_script(load(path)).get_as_byte_code())


# Converts a text resource file to binary for release mode:
func _pipe_convert_resource(path: String) -> void:
	_remap_resource(path, "res://%s.res" % _resource_counter.next())


# Converts a scene resource file to binary for release mode:
func _pipe_convert_scene(path: String) -> void:
	_remap_resource(path, "res://%s.scn" % _scene_counter.next())
