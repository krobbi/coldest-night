class_name Overworld
extends Node

# Overworld Scene
# The overworld scene is the primary scene of the game, and is where most of the
# game takes place. It handles storing and initializing the game state to and
# from save data, loading and changing levels, configuring the player and camera
# between levels, and controlling the HUD.

signal _level_changed;

var save_slot: SaveSlot = Global.save.get_active_slot();
var save_data: SaveData = save_slot.clone_data();
var level_cache: LevelCache = LevelCache.new();
var level: Level = null;
var player: Player = load("res://entities/actors/player/player.tscn").instance();

var _changing_level: bool = false;

onready var camera: OverworldCamera = $OverworldCamera;
onready var radar: Radar = $HUD/Radar;
onready var floating_text_spawner: FloatingTextSpawner = $HUD/FloatingTextSpawner;
onready var transition: FadeTransition = $HUD/FadeTransition;

# Virtual _ready method. Initializes the game state from save data and registers
# the overworld scene to the global provider manager:
func _ready() -> void:
	Global.provider.set_radar(radar);
	
	_apply_save_data();
	
	Global.provider.set_player(player);
	Global.provider.set_camera(camera);
	Global.provider.set_overworld(self);


# Virtual _input method. Runs when the overworld scene receives an input event.
# Handles debug controls for quick saving and quick loading:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_quicksave"):
		quick_save_game();
	elif event.is_action_pressed("debug_quickload"):
		quick_load_game();


# Virtual exit_tree method. Unregisters the overworld scene from the global
# provider manager and frees the level cache and player:
func _exit_tree() -> void:
	Global.provider.set_level(null);
	Global.provider.set_player(null);
	Global.provider.set_radar(null);
	Global.provider.set_camera(null);
	Global.provider.set_overworld(null);
	
	camera.unfollow_anchor();
	level_cache.free();
	
	if not level:
		player.free();


# Displays floating text at a world position source:
func display_floating_text(message: String, world_pos: Vector2) -> void:
	floating_text_spawner.display(message, camera.get_screen_pos(world_pos));


# Saves the game to its save slot without saving to its file:
func quick_save_game() -> void:
	if _changing_level:
		print("Failed to quick save the game as the level is changing!");
		return;
	
	_compose_save_data();
	save_slot.put_data(save_data);
	
	display_floating_text("Saved Game", player.get_position());


# Loads the game from its save slot without reading from its file:
func quick_load_game() -> void:
	if _changing_level:
		print("Failed to quick load the game as the level is changing!");
		return;
	
	save_data = save_slot.clone_data();
	_apply_save_data();
	
	if _changing_level:
		yield(self, "_level_changed");
	
	display_floating_text("Loaded Game", player.get_position());


# Changes the current level in the overworld scene:
func change_level(key: String, point: String, offset: Vector2 = Vector2.ZERO) -> void:
	if _changing_level:
		print("Failed to change the level as the level is already changing!");
		return;
	
	_changing_level = true;
	
	yield(get_tree(), "idle_frame");
	player.disable_triggers();
	
	# Fade out:
	transition.fade_out();
	yield(transition, "faded_out");
	
	if level:
		Global.provider.set_level(null);
	
		# Remove player:
		camera.unfollow_anchor();
		camera.unfocus();
		level.y_sort.remove_child(player);
	
		# Remove level:
		remove_child(level);
		level.free();
	
	# Add level:
	level = level_cache.get_level(key);
	
	transition.show_message("%s\n>> %s" % [level.area_name, level.level_name]);
	yield(transition, "message_shown");
	
	add_child(level);
	Global.provider.set_level(level);
	
	# Add player:
	player.set_position(level.get_point_pos(point) + offset);
	level.y_sort.add_child(player);
	
	# Configure radar:
	radar.set_player_pos(player.get_position());
	
	# Configure camera:
	camera.set_limit(MARGIN_LEFT, int(level.top_left.x));
	camera.set_limit(MARGIN_TOP, int(level.top_left.y));
	camera.set_limit(MARGIN_RIGHT, int(level.bottom_right.x));
	camera.set_limit(MARGIN_BOTTOM, int(level.bottom_right.y));
	camera.follow_anchor(player);
	camera.force_update_scroll();
	camera.reset_smoothing();
	
	# Update save data:
	save_data.pos_level = key;
	save_data.pos_point = point;
	save_data.pos_offset = offset;
	
	transition.fade_in();
	yield(transition, "faded_in");
	
	_changing_level = false;
	emit_signal("_level_changed");
	
	player.enable_triggers();


# Composes the game state to the current save data:
func _compose_save_data() -> void:
	var world_pos: Vector2 = player.get_position();
	save_data.pos_point = level.get_nearest_point(world_pos);
	save_data.pos_offset = world_pos - level.get_point_pos(save_data.pos_point);


# Applies the current save data to the game state:
func _apply_save_data() -> void:
	change_level(save_data.pos_level, save_data.pos_point, save_data.pos_offset);
