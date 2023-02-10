tool
extends EditorPlugin

# NightScript Precompiler
# The NightScript precompiler is an editor plugin that precompiles NightScript
# source files to NightScript bytecode files when the game is exported. This
# greatly improves performance when loading levels, reduces file size, and
# allows the NightScript compiler to be excluded from exports. This also means
# that developers never have to manually compile NightScript, or work with
# NightScript bytecode files.

var _export_plugin: EditorExportPlugin = preload("export_plugin.gd").new()

# Run when the NightScript precompiler enters the scene tree. Register the
# NightScript precompiler's export plugin.
func _enter_tree() -> void:
	add_export_plugin(_export_plugin)


# Run when the NightScript precompiler exits the scene tree. Remove the
# NightScript precompiler's export plugin.
func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
