class_name Radar
extends Control

# Radar Display
# The radar display is a GUI element in the overworld that shows a zoomed-out
# map of the level as a series of line segments.

const PLAYER_OFFSET: Vector2 = Vector2(0.0, 1.0);

onready var walls: RadarWallRenderer = $ViewportContainer/Viewport/Foreground/Walls;
onready var player: Polygon2D = $ViewportContainer/Viewport/Foreground/Player;


# Gets the position of a world coordinate scaled to be rendered on the radar
# display:
func get_radar_pos(world_pos: Vector2) -> Vector2:
	return (world_pos / 8.0).floor();


# Renders a level to the radar display:
func render_level(level: Level) -> void:
	var shape_segmenter: ShapeSegmenter = ShapeSegmenter.new();
	var segments: PoolVector2Array = shape_segmenter.segment_node(level.radar_shapes);
	shape_segmenter.free();
	level.radar_shapes.queue_free();
	
	for i in range(segments.size()):
		segments[i] = get_radar_pos(segments[i]);
	
	walls.render(segments);


# Moves the player display on the radar display according to the player's world
# position:
func move_player(player_pos: Vector2) -> void:
	player.position = get_radar_pos(player_pos) + PLAYER_OFFSET;
