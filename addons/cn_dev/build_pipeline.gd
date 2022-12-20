extends EditorExportPlugin

# Coldest Night Development Toolkit Build Pipeline
# The Coldest Night Development Toolkit build pipeline is an editor export
# plugin that excludes, transforms, and adds resource files to Coldest Night
# when it is exported.

const EXCLUDE_COMMON: PoolStringArray = PoolStringArray([
	"res://.git/",
	"res://.idea/",
	"res://.vscode/",
	"res://builds/",
	"res://coldnight_font/",
	"res://docs/",
	"res://ignore/",
	"res://license.txt",
	"res://logo.png",
])

const EXCLUDE_RELEASE: PoolStringArray = PoolStringArray([
	"res://addons/cn_dev/",
	"res://utils/nightscript/compiler/",
	"res://utils/nightscript/debug/",
])

var _is_debug: bool = false

# Run when the game begins exporting. Set whether the game is being exported in
# debug mode.
func _export_begin(_features: PoolStringArray, is_debug: bool, _path: String, _flags: int) -> void:
	_is_debug = is_debug


# Run when the game exports a resource file. Exclude, transform, or add resource
# files where applicable.
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
	
	if path.match("res://resources/data/nightscript/*.ns"):
		_pipe_compile_nightscript(path)


# Compile a NightScript source file for release mode.
func _pipe_compile_nightscript(path: String) -> void:
	skip()
	
	var compiler: Reference = load("res://utils/nightscript/compiler/ns_compiler.gd").new()
	
	if path.count(".") == 2:
		var locale: String = path.split(".")[1]
		add_file(path, compiler.compile_path(locale, path, true), false)
		return
	
	for locale in TranslationServer.get_loaded_locales():
		var new_path: String = path.replace(".ns", ".%s.ns" % locale)
		add_file(new_path, compiler.compile_path(locale, path, true), false)
