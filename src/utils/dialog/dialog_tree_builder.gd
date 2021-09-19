class_name DialogTreeBuilder
extends Object

# Dialog Tree Builder Base
# A dialog tree builder is a dialog utility that builds a dialog tree from a
# dialog file's key. This abstract class is used for polymorphism between dialog
# source files in debug builds and compiled dialog tree files in release builds.

var _tree: DialogTree;

# Constructor. Passes the dialog tree to the dialog tree builder and resets the
# dialog tree builder's state:
func _init(tree_ref: DialogTree) -> void:
	_tree = tree_ref;
	reset();


# Gets the path of a dialog file from its key and the current locale without a
# file extension:
func get_dialog_path(key: String) -> String:
	return "res://assets/data/dialogs/en/" + key;


# Resets the dialog tree builder's state:
func reset() -> void:
	_tree.reset();


# Builds the dialog tree from a dialog file's key:
func build(_key: String) -> void:
	pass;
