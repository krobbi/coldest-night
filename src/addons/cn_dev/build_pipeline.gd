extends EditorExportPlugin

# Coldest Night Development Toolkit Build Pipeline
# The Coldest Night Development Toolkit build pipeline is an editor export
# plugin that excludes, transforms, and adds resource files to Coldest Night
# when exported in release mode. It is used to optimize the file size and
# performance of the game in release builds.

const EXCLUDE_RELEASE: PoolStringArray = PoolStringArray([
	"res://addons/cn_dev/",
	"res://utils/nightscript/debug/",
])

var _nightscript_compiler: Reference = preload("res://utils/nightscript/debug/ns_compiler.gd").new()
var _is_debug: bool = false

# Virtual _export_begin method. Runs when the game begins exporting. Sets
# whether the game is being exported in debug mode:
func _export_begin(_features: PoolStringArray, is_debug: bool, _path: String, _flags: int) -> void:
	_is_debug = is_debug


# Virtual _export_file method. Runs when the game exports a resource file.
# Excludes, transforms, or adds resource files to the exported game in release
# mode:
func _export_file(path: String, _type: String, _features: PoolStringArray) -> void:
	if _is_debug:
		return
	
	for exclude in EXCLUDE_RELEASE:
		if path.begins_with(exclude):
			skip()
			return
	
	if path.match("res://assets/data/credits/credits_*.txt"):
		_pipe_move_credits(path)
	elif path.match("res://assets/data/nightscript/*.ns"):
		_pipe_compile_nightscript(path)


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
	
	var moved_path: String = "res://c/%s" % path.replace("res://assets/data/credits/credits_", "")
	add_file(moved_path, file_data, false)


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
	
	var compiled_path: String = "res://n/%s/%sc" % [locale, path_parts.join(".")]
	add_file(compiled_path, _nightscript_compiler.compile_path(path), false)
