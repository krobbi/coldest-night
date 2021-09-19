class_name LevelCache
extends Object

# Level Cache
# A level cache is an overworld utility that handles loading, initializing, and
# storing level's scenes and creating new instances of levels from their keys.
# The level's scenes are stored in an LRU cache. If the cache is full when a new
# level is requested, the least recently used level's scene is overwritten.

const DEFAULT_PATH: String = "res://levels/level.tscn";

var size: int;
var lru_page: int = 0;
var keys: PoolStringArray = PoolStringArray();
var scenes: Array = [];
var ages: PoolIntArray = PoolIntArray();

# Constructor. Sets the size of the level cache and clears the level cache:
func _init(size_val: int) -> void:
	size = int(max(1.0, float(size_val)));
	
	keys.resize(size);
	scenes.resize(size);
	ages.resize(size);
	
	for i in range(size):
		keys[i] = "";
		scenes[i] = null;
		ages[i] = size - i - 1; # Populate level cache from front page index.


# Gets a new instance of a level from its key:
func get_level(key: String) -> Level:
	# Empty keys are reserved for unpopulated cache pages:
	if key.empty():
		return init_scene(load(DEFAULT_PATH)).instance() as Level;
	
	var page: int = -1;
	
	# Look for cache hit:
	for i in range(size):
		if keys[i] == key:
			page = i;
			break;
	
	# Replace LRU page on cache miss:
	if page == -1:
		page = lru_page;
		keys[page] = key;
		scenes[page] = load_scene(key);
	
	# Set age of accessed page to 0 and increment age of younger pages:
	var prev_age: int = ages[page];
	ages[page] = 0;
	
	# TODO: There is probably a more efficient way to do this:
	for i in range(size):
		if i == page:
			continue;
		
		if ages[i] < prev_age:
			ages[i] += 1;
			
			if ages[i] == size - 1:
				lru_page = i;
	
	return scenes[page].instance();


# Loads, initializes and returns a level's scene from its path:
func load_scene(key: String) -> PackedScene:
	var path: String = "res://levels/" + key + "_level.tscn";
	var scene: PackedScene;
	
	if ResourceLoader.exists(path, "PackedScene"):
		scene = load(path);
	else:
		scene = load(DEFAULT_PATH);
		print("Failed to load non-existent level %s!" % key);
	
	return init_scene(scene);


# Initializes a level's scene to a runtime-compatible format:
func init_scene(scene: PackedScene) -> PackedScene:
	# CNEP:DEBUG
	if OS.is_debug_build():
		var level_repacker: Object = load("res://utils/overworld/debug/level_repacker.gd").new();
		scene = level_repacker.repack(scene);
		level_repacker.free();
	# CNEP:END_DEBUG
	
	return scene;
