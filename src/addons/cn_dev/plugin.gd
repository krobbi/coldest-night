tool
extends EditorPlugin

# Coldest Night Development Toolkit
# The Coldest Night Development Toolkit is a set of tools and editor plugins for
# developing and exporting Coldest Night.

var export_pipeline: EditorExportPlugin = preload("res://addons/cn_dev/export_pipeline.gd").new();

# Virtual _enter_tree method. Runs when the Coldest Night Development Toolkit
# enters a scene tree. Adds the export pipeline:
func _enter_tree() -> void:
	add_export_plugin(export_pipeline);


# Virtual _exit_tree method. Runs when the Coldest Night Development Toolkit
# exits a scene tree. Removes and destructs the export pipeline:
func _exit_tree() -> void:
	remove_export_plugin(export_pipeline);
	export_pipeline.destruct();
