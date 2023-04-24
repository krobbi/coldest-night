class_name Level
extends Node2D

# Level Base
# Levels are sub-scenes of the overworld scene that represent areas in the game
# world.

@export var area_name: String = "AREA.UNKNOWN"
@export var level_name: String = "LEVEL.UNKNOWN"

@export var _music: AudioStream

var _save_data: SaveData = SaveManager.get_working_data()
var _points: Dictionary = {}

# Run when the level enters the scene tree. Free persistent nodes if the level
# has a saved state in the current working save data.
func _enter_tree() -> void:
	if _save_data.has_level_data(scene_file_path):
		_free_persistent(self)


# Run when the level finishes entering the scene tree. Initialize the level.
func _ready() -> void:
	ConfigBus.subscribe_node_bool("debug.show_navigation_map", $NavigationTileMap.set_visible)
	AudioManager.play_music(_music)
	
	var points_node: Node = $Points
	remove_child(points_node)
	
	for point_node in points_node.get_children():
		if point_node is Marker2D:
			_points[point_node.name] = point_node.position
	
	points_node.free()
	
	var top_left_node: Node2D = $TopLeft
	var bottom_right_node: Node2D = $BottomRight
	remove_child(top_left_node)
	remove_child(bottom_right_node)
	EventBus.camera_set_limits_request.emit(top_left_node.position, bottom_right_node.position)
	top_left_node.free()
	bottom_right_node.free()
	
	if _save_data.has_level_data(scene_file_path):
		_save_data.get_level_data(scene_file_path).instantiate_entities(self)
	
	EventBus.radar_render_level_request.emit()
	EventBus.subscribe_node(EventBus.save_state_request, save_state)


# Get the parent node to add the player to.
func get_player_parent() -> Node:
	return $Entities


# Get a point's world position. Return `Vector2.ZERO` if the point is empty or
# does not exist.
func get_point_pos(point: String) -> Vector2:
	if point.is_empty():
		return Vector2.ZERO
	else:
		return _points.get(point, Vector2.ZERO)


# Save the level's state to the current working save data.
func save_state() -> void:
	var level_data: LevelSaveData = _save_data.get_level_data(scene_file_path)
	level_data.clear_entities()
	
	for entity in get_tree().get_nodes_in_group("persistent"):
		level_data.add_entity(entity, self)


# Recursively free persistent nodes.
func _free_persistent(node: Node) -> void:
	if not node.is_in_group("persistent"):
		for child in node.get_children():
			_free_persistent(child)
		
		return
	
	node.get_parent().remove_child(node)
	node.free()
