tool
extends EditorPlugin

# Coldest Night Development Toolkit
# The Coldest Night Development Toolkit is an editor plugin that contains tools
# for developing and exporting Coldest Night. It is never used at run-time in
# release mode and should be excluded from release builds of the game.

var build_pipeline: EditorExportPlugin = preload("res://addons/cn_dev/build_pipeline.gd").new()

# Virtual _enter_tree method. Runs when the Coldest Night Development Toolkit
# enters a scene tree. Adds the build pipeline:
func _enter_tree() -> void:
	add_export_plugin(build_pipeline)


# Virtual _exit_tree method. Runs when the Coldest Night Development Toolkit
# exits a scene tree. Removes the build pipeline:
func _exit_tree() -> void:
	remove_export_plugin(build_pipeline)
