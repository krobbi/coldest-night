extends EditorExportPlugin

# Coldest Night Development Toolkit Build Pipeline
# The Coldest Night Development Toolkit build pipeline is an editor export
# plugin that transforms resource files when they are exported.

# Run when the game exports a resource file. Transform the resource file if
# applicable.
func _export_file(path: String, _type: String, _features: PoolStringArray) -> void:
	if path.match("res://nightscript/scripts/*.ns"):
		_pipe_compile_nightscript(path)


# Compile a NightScript source file to one or more NightScript bytecode files.
func _pipe_compile_nightscript(path: String) -> void:
	skip()
	
	var compiler: Reference = load("res://nightscript/compiler/ns_compiler.gd").new()
	
	if path.count(".") == 2:
		var locale: String = path.split(".")[1]
		add_file(path, compiler.compile_path(locale, path, true), false)
		return
	
	for locale in TranslationServer.get_loaded_locales():
		var new_path: String = path.replace(".ns", ".%s.ns" % locale)
		add_file(new_path, compiler.compile_path(locale, path, true), false)
