class_name Level
extends Node2D

# Level Base
# Levels are sub-scenes of the overworld scene that represent an area in the
# game world. They have an area name, level name, background music, boundaries,
# fixed points, a navigation map storing collision information, and a Y sort
# node for storing entities. The player and camera do not need to be instanced
# within levels as this is handled by the overworld scene. Each level can be
# referenced by a string key based on its path:

enum RadarSource {
	NONE, # Level has no radar.
	INTERPRET, # Level's radar is created just-in-time.
};

export(String) var area_name: String = "???";
export(String) var level_name: String = "???";
export(AudioStream) var music: AudioStream = null;
export(RadarSource) var radar_source: int = RadarSource.INTERPRET;

var _points: Dictionary = {};

onready var y_sort: YSort = $YSort;
onready var top_left: Vector2 = $TopLeft.get_position();
onready var bottom_right: Vector2 = $BottomRight.get_position();

# Virtual _ready method. Runs when the level finishes entering the scene tree.
# Frees the used boundary position nodes, registers the level's points, renders
# the level's radar, and plays the level's music.
func _ready() -> void:
	$TopLeft.queue_free();
	$BottomRight.queue_free();
	
	for node in $Points.get_children():
		if node is Node2D:
			_points[node.get_name()] = node.get_position();
	
	$Points.queue_free();
	
	var radar: Radar = Global.provider.get_radar();
	
	if radar:
		match radar_source:
			RadarSource.INTERPRET:
				var segmentor: ShapeSegmentor = ShapeSegmentor.new();
				var segments: PoolVector2Array = segmentor.segment_node($RadarShapes);
				segmentor.free();
				radar.render_walls(segments);
			RadarSource.NONE, _:
				radar.render_walls(PoolVector2Array());
	else:
		print("Failed to render radar as the radar display could not be provided!");
	
	$RadarShapes.queue_free();
	
	Global.play_music(music);


# Gets the world position of a point. Returns a zero vector if the point does
# not exist:
func get_point_pos(point: String) -> Vector2:
	return _points[point] if _points.has(point) else Vector2.ZERO;


# Gets the nearest point to a world position. Returns a default point if the
# level has no points:
func get_nearest_point(world_pos: Vector2) -> String:
	var nearest_point: String = "O";
	var nearest_distance: float = INF;
	
	for point in _points.keys():
		var distance: float = world_pos.distance_squared_to(_points[point]);
		
		if distance < nearest_distance:
			nearest_point = point;
			nearest_distance = distance;
	
	return nearest_point;
