extends EditorExportPlugin

# NightScript Precompiler Export Plugin
# The NightScript precompiler export plugin is an editor export plugin
# registered to the NightScript precompiler that detects file paths belonging to
# NightScript source files when they are exported and replaces them with
# compiled NightScript bytecode files.

# Run when a file is about to be exported. Export the file as a compiled
# NightScript bytecode file if it is a NightScript source file.
func _export_file(path: String, _type: String, _features: PoolStringArray) -> void:
	if path.begins_with("res://nightscript/scripts/") and path.ends_with(".ns"):
		skip() # Don't export NightScript source files.
		
		# NightScript source files with global locales don't have a dot
		# delimited locale in their file name.
		var has_global_locale: bool = path.count(".") == 1
		
		# NightScript source files with global locales must be exported for each
		# locale in case they have dependencies with non-global locales.
		if has_global_locale:
			for locale in TranslationServer.get_loaded_locales():
				var target_path: String = path.replace(".ns", ".%s.ns" % locale)
				_compile_nightscript(path, target_path, locale)
		else:
			# NightScript source files with non-global locales are exported once
			# with the locale from their file name.
			var locale: String = path.split(".")[1]
			
			_compile_nightscript(path, path, locale)


# Export a NightScript source file at a source path as a compiled NightScript
# bytecode file at a target path with a locale.
func _compile_nightscript(source_path: String, target_path: String, locale: String) -> void:
	var compiler: Reference = load("res://nightscript/compiler/ns_compiler.gd").new()
	add_file(target_path, compiler.compile_path(locale, source_path, true), false)
