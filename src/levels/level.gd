class_name Level
extends Node2D

# Level Base
# Levels are sub-scenes of the overworld scene that represent an area in the
# game world. They have an area and level name, background music, boundaries,
# radar display data, a set of fixed point positions, a navigation map storing
# collision information, a node for containing triggers, and a Y sort node for
# containing entities. Each level can be referenced by a string key based on its
# path. Exported variables other than area name, level name and music should be

export(String) var area_name: String = "???";
export(String) var level_name: String = "???";
export(AudioStream) var music: AudioStream = null;

# Repacked level data. Use the provided nodes to edit these values. Do not edit
# them in the inspector:
export(Vector2) var top_left: Vector2;
export(Vector2) var bottom_right: Vector2;
export(Dictionary) var points: Dictionary;
export(PoolByteArray) var radar_data: PoolByteArray;

onready var y_sort: YSort = $YSort;

# Virtual _ready method. Runs when the level is entered. Renders the level's
# radar display, plays the level's background music, and registers the level to
# the global provider manager:
func _ready() -> void:
	var radar: Radar = Global.provider.get_radar();
	
	if radar == null:
		print("Failed to render the level's radar as the radar display could not be provided!");
	else:
		radar.render_data(radar_data);
		radar_data.resize(0);
	
	Global.audio.play_music(music);
	Global.provider.set_level(self);


# Virtual _exit_tree method. Runs when the level is exited. Unregisters the
# level from the global provider manager:
func _exit_tree() -> void:
	Global.provider.set_level(null);


# Gets the world position of a point. Returns the origin position of the level
# if the point does not exist:
func get_point_pos(point: String) -> Vector2:
	return points[point] if points.has(point) else Vector2.ZERO;


# Gets the nearest point to world_position. Returns a default origin point if
# the level has no points:
func get_nearest_point(world_pos: Vector2) -> String:
	var nearest_point: String = "O";
	var nearest_distance: float = INF;
	
	for point in points.keys():
		var distance: float = world_pos.distance_squared_to(points[point]);
		
		if distance < nearest_distance:
			nearest_point = point;
			nearest_distance = distance;
	
	return nearest_point;
