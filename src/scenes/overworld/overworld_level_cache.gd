class_name OverworldLevelCache
extends Object

# Overworld Level Cache
# The overworld level cache is a component of the overworld scene that handles
# loading level's scenes and creating new instances of levels from their keys.

# Gets a new instance of a level from its key:
func get_level(key: String) -> Level:
	return load_scene(key).instance() as Level;


# Loads and returns a level's scene from its key:
func load_scene(key: String) -> PackedScene:
	var path: String = "res://levels/" + key + "_level.tscn";
	
	if ResourceLoader.exists(path, "PackedScene"):
		return load(path) as PackedScene;
	else:
		print("Failed to load non-existent level %s!" % key);
		return load("res://levels/level.tscn") as PackedScene;
