class_name Radar
extends Control

# Radar Display
# The radar display is a HUD element that displays a level's walls and the
# player's position.

const PLAYER_OFFSET: Vector2 = Vector2(0.0, 1.0);

onready var walls: RadarWallRenderer = $ViewportContainer/Viewport/Foreground/RadarWallRenderer;
onready var player: Polygon2D = $ViewportContainer/Viewport/Foreground/Player;

# Gets a world position as a radar position:
func get_radar_pos(world_pos: Vector2) -> Vector2:
	return (world_pos * 0.125).floor();


# Sets the displayed player's position to a world position:
func set_player_pos(world_pos: Vector2) -> void:
	player.set_position(get_radar_pos(world_pos) + PLAYER_OFFSET);


# Renders a set of walls to the radar from an array of line segments:
func render_walls(segments: PoolVector2Array) -> void:
	for i in range(segments.size()):
		segments[i] = get_radar_pos(segments[i]);
	
	walls.render(segments);
