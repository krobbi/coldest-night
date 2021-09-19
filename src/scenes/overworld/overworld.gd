class_name Overworld
extends Node

# Overworld Scene
# The overworld scene is the primary scene of the game. It handles composing,
# applying, and initializing the game state from save data, loading and changing
# levels, configuring the player and overworld camera between levels, and
# controlling the HUD.

signal _player_emplaced;
signal _level_changed;

var save_data: SaveData = Global.save.get_working_data();
var level_cache: LevelCache = LevelCache.new(2);
var level: Level = null;
var player: Player = preload("res://entities/actors/player/player.tscn").instance();

var _changing_level: bool = false;

onready var camera: OverworldCamera = $OverworldCamera;
onready var radar: Radar = $HUD/Radar;
onready var transition: FadeTransition = $HUD/FadeTransition;
onready var floating_text: FloatingTextSpawner = $HUD/FloatingText;
onready var radio: RadioDialog = $HUD/RadioDialog;

# Virtual _ready method. Runs when the overworld scene is entered. Registers the
# overworld scene to the global provider manager and initializes the game state
# from save data:
func _ready() -> void:
	Global.provider.set_overworld(self);
	_apply_save_data();


# Virtual _exit_tree method. Runs when the overworld scene is exited.
# Unregisters the overworld scene from the global provider manager, frees the
# level cache, and frees the player if it is not in the scene tree:
func _exit_tree() -> void:
	Global.provider.set_overworld(null);
	
	level_cache.free();
	
	if not player.is_inside_tree():
		player.free();


# Displays a new floating text instance sourced at a world position:
func display_floating_text(text: String, world_pos: Vector2) -> void:
	floating_text.display(text, camera.get_screen_pos(world_pos));


# Saves the game state to the active save slot's file:
func save_game() -> void:
	if _changing_level:
		print("Failed to save the game as the level is changing!");
		return;
	
	_compose_save_data();
	Global.save.save_file();
	display_floating_text("Saved game", player.get_position());


# Changes the current level and positions the player at a point and offset
# position:
func change_level(key: String, point: String, offset: Vector2) -> void:
	if _changing_level:
		print("Failed to change to level %s as the level is already changing!" % key);
		return;
	
	_changing_level = true;
	
	if level != null:
		yield(get_tree(), "idle_frame");
		_change_level_pre();
		
		transition.fade_out();
		yield(transition, "faded_out");
		
		_remove_player();
		_remove_level();
	
	_add_level(key);
	_add_player(point, offset);
	
	save_data.pos_level = key;
	save_data.pos_point = point;
	save_data.pos_offset = offset;
	
	transition.fade_in();
	
	_changing_level = false;
	emit_signal("_level_changed");
	_change_level_post();


# Initializes the state for changing the current level:
func _change_level_pre() -> void:
	player.disable_triggers();
	player.set_state(player.State.TRANSITIONING);


# Removes the player from the current level:
func _remove_player() -> void:
	level.y_sort.remove_child(player);


# Removes the current level from the overworld scene:
func _remove_level() -> void:
	remove_child(level);
	level.free();


# Adds a new level to the overworld scene from its key:
func _add_level(key: String) -> void:
	level = level_cache.get_level(key);
	add_child(level);


# Adds the player to the current level positioned at a point and offset
# position:
func _add_player(point: String, offset: Vector2) -> void:
	player.set_position(level.get_point_pos(point) + offset);
	level.y_sort.add_child(player);
	Global.provider.set_player(player);
	
	emit_signal("_player_emplaced");
	
	radar.set_player_pos(player.get_position());
	
	camera.set_limit(MARGIN_LEFT, int(level.top_left.x));
	camera.set_limit(MARGIN_TOP, int(level.top_left.y));
	camera.set_limit(MARGIN_RIGHT, int(level.bottom_right.x));
	camera.set_limit(MARGIN_BOTTOM, int(level.bottom_right.y));
	camera.follow_anchor(player.camera_anchor);
	camera.force_update_scroll();
	camera.reset_smoothing();


# Finalizes the state after the current level has finished changing:
func _change_level_post() -> void:
	player.set_state(player.State.MOVING);
	player.enable_triggers();


# Composes the current working save data from the game state:
func _compose_save_data() -> void:
	var world_pos: Vector2 = player.get_position();
	save_data.pos_point = level.get_nearest_point(world_pos);
	save_data.pos_offset = world_pos - level.get_point_pos(save_data.pos_point);
	save_data.pos_angle = wrapf(player.smooth_pivot.get_rotation(), -PI, PI);


# Applies the current working save data to the game state:
func _apply_save_data() -> void:
	change_level(save_data.pos_level, save_data.pos_point, save_data.pos_offset);
	player.smooth_pivot.set_rotation(wrapf(save_data.pos_angle, -PI, PI));
	
	if _changing_level:
		yield(self, "_player_emplaced");
		player.clear_velocity();
