class_name Level
extends Node2D

# Level Base
# Levels are sub-scenes of the overworld scene that represent an area in the
# game world. They have an area and level name, background music, boundaries,
# radar display data, a set of fixed point positions, a navigation map storing
# collision information, a node for containing triggers, and a Y sort node for
# containing entities. Each level can be referenced by a string key based on its
# path.

enum RadarSource {
	NONE, # The level has no radar.
	INTERPRET, # The level's radar is rendered just in time from the radar nodes.
};

export(String) var area_name: String = "???";
export(String) var level_name: String = "???";
export(RadarSource) var _radar_source: int = RadarSource.INTERPRET;
export(AudioStream) var _music: AudioStream = null;

var _points: Dictionary = {};

onready var y_sort: YSort = $YSort;
onready var top_left: Vector2 = $TopLeft.get_position();
onready var bottom_right: Vector2 = $BottomRight.get_position();

# Virtual _ready method. Runs when the level is entered. Frees the used boundary
# position nodes, registers the level's points, renders the level's radar,
# unpacks the level's triggers, plays the level's background music, and
# registers the level to the global provider manager:
func _ready() -> void:
	$BottomRight.queue_free();
	$TopLeft.queue_free();
	
	var radar: Radar = Global.provider.get_radar();
	
	if radar == null:
		print("Failed to render the level's radar as the radar display could not be provided!");
	else:
		match RadarSource:
			RadarSource.NONE:
				radar.clear_walls();
				radar.clear_floors();
				radar.clear_pits();
			RadarSource.INTERPRET, _:
				radar.render_pits_node($Radar/Pits);
				radar.render_floors_node($Radar/Floors);
				radar.render_walls_node($Radar/Walls);
	
	$Radar.queue_free();
	
	for point in $Points.get_children():
		if point is Node2D:
			_points[point.get_name()] = point.get_position();
	
	$Points.queue_free();
	
	var trigger_container: Node2D = $Triggers;
	
	for trigger in trigger_container.get_children():
		if trigger is Trigger:
			trigger_container.remove_child(trigger);
			add_child(trigger);
	
	trigger_container.free();
	
	Global.audio.play_music(_music);
	
	Global.provider.set_level(self);


# Virtual _exit_tree method. Runs when the level is exited. Unregisters the
# level from the global provider manager:
func _exit_tree() -> void:
	Global.provider.set_level(null);


# Gets the world position of a point. Returns the origin position of the level
# if the point does not exist:
func get_point_pos(point: String) -> Vector2:
	return _points[point] if _points.has(point) else Vector2.ZERO;


# Gets the nearest point to world_position. Returns a default origin point if
# the level has no points:
func get_nearest_point(world_pos: Vector2) -> String:
	var nearest_point: String = "O";
	var nearest_distance: float = INF;
	
	for point in _points.keys():
		var distance: float = world_pos.distance_squared_to(_points[point]);
		
		if distance < nearest_distance:
			nearest_point = point;
			nearest_distance = distance;
	
	return nearest_point;
