class_name LevelCache
extends Object

# Level Cache
# The level cache is a utility for the overworld scene that loads level scenes
# and creates new instances of levels from their keys.

const DEFAULT_PATH: String = "res://levels/special/blank_level.tscn";

# Gets a new instance of a level from its key:
func get_level(key: String) -> Level:
	return load_scene(key).instance() as Level;


# Loads and returns a level's scene from its key. Returns a default level scene
# if the level does not exist:
func load_scene(key: String) -> PackedScene:
	var path: String = "res://levels/%s_level.tscn" % key;
	var dir: Directory = Directory.new();
	
	if dir.file_exists(path):
		return load(path) as PackedScene;
	else:
		print("Failed to load non-existent level %s!" % key);
		return load(DEFAULT_PATH) as PackedScene;
