class_name LevelCache
extends Object

# Level Cache
# The level cache is a utility that handles loading level's scenes, and creating
# new instances of levels from their keys.

# Gets a new instance of a level from its key. Returns a default level if the
# level does not exist:
func get_level(key: String) -> Level:
	return load_scene(key).instance() as Level;


# Loads a level's scene from its key. Returns a default level's scene if the
# level does not exist:
func load_scene(key: String) -> PackedScene:
	var path: String = "res://levels/%s_level.tscn" % key;
	var dir: Directory = Directory.new();
	
	if dir.file_exists(path):
		return load(path) as PackedScene;
	else:
		print("Failed to load non-existent level %s!" % key);
		return load("res://levels/level.tscn") as PackedScene;
