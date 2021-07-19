extends Node

# Overworld Scene
# The overworld scene is the primary scene of the game, and is where most of the
# game takes place. The overworld scene manages initializing the game state,
# loading and switching levels, reparenting the player between levels, and
# controlling the GUI.

var player: Player = load("res://entities/actors/player/player.tscn").instance();
var level_cache: LevelCache = LevelCache.new();
var level: Level = null;

onready var camera: OverworldCamera = $OverworldCamera;
onready var radar: Radar = $GUI/Radar;

# Virtual _ready method. Runs when the overworld scene is changed to.
# Initializes the game state:
func _ready() -> void:
	add_level("test/blockout", 1, 5);


# Virtual _physics process method. Runs on every physics frame while the
# overworld scene is loaded. Updates the player's position on the radar display:
func _physics_process(_delta: float) -> void:
	radar.move_player(player.position);


# Virtual _exit_tree method. Runs when the overworld scene is exited. Removes
# the current level if it exists, and frees the player and level cache:
func _exit_tree() -> void:
	remove_level();
	level_cache.free();
	player.free();


# Removes the current level if it exists and adds a new level from its key:
func add_level(key: String, player_x: int, player_y: int) -> void:
	remove_level();
	player.set_tile_pos(player_x, player_y);
	level = level_cache.get_level(key);
	level.register_player(player);
	add_child(level);
	radar.render_level(level);
	camera.apply_level_limits(level);
	camera.follow_player(player);


# Removes the current level if it exists:
func remove_level() -> void:
	if not level:
		return;
	
	camera.unfollow_anchor();
	remove_child(level);
	level.free();
	level = null;
