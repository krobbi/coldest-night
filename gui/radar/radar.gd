extends SubViewportContainer

# Radar Display
# The radar display is a HUD element of the overworld scene that displays a map
# of the current level.

const VisionAreaRendererScene: PackedScene = preload(
		"radar_vision_area_renderer/radar_vision_area_renderer.tscn")
const LaserWallRendererScene: PackedScene = preload(
		"radar_laser_wall_renderer/radar_laser_wall_renderer.tscn")
const PointRendererScene: PackedScene = preload("radar_point_renderer/radar_point_renderer.tscn")

const RESOLUTION: Vector2 = Vector2(128.0, 96.0)

var _camera_anchor: Node2D = null

@onready var camera: Camera2D = $SubViewport/Foreground/Camera

@onready var _viewport: SubViewport = $SubViewport
@onready var _background_polygon: Polygon2D = $SubViewport/Background/ColorPolygon
@onready var _pits_renderer: RadarPolygonRenderer = $SubViewport/Foreground/Pits
@onready var _floors_renderer: RadarSegmentRenderer = $SubViewport/Foreground/Floors
@onready var _vision_area_container: Node2D = $SubViewport/Foreground/VisionAreas
@onready var _points_container: Node2D = $SubViewport/Foreground/Points
@onready var _laser_wall_container: Node2D = $SubViewport/Foreground/LaserWalls
@onready var _walls_renderer: RadarSegmentRenderer = $SubViewport/Foreground/Walls

# Run when the radar display finishes entering the scene tree. Disable the radar
# display's process and subscribe the radar display to the configuration bus and
# event bus.
func _ready() -> void:
	set_process(false)
	ConfigBus.subscribe_node_bool("radar.visible", set_visible)
	ConfigBus.subscribe_node_float("radar.scale", _set_display_scale)
	ConfigBus.subscribe_node_string("radar.background_color", _set_background_color)
	ConfigBus.subscribe_node_float("radar.background_opacity", _set_background_opacity)
	ConfigBus.subscribe_node_string("radar.wall_color", _set_wall_color)
	ConfigBus.subscribe_node_string("radar.floor_color", _set_floor_color)
	EventBus.subscribe_node(EventBus.radar_render_level_request, render_level)
	EventBus.subscribe_node(EventBus.radar_render_point_request, render_point)
	EventBus.subscribe_node(EventBus.radar_render_vision_area_request, render_vision_area)
	EventBus.subscribe_node(EventBus.radar_render_laser_wall_request, render_laser_wall)
	EventBus.subscribe_node(EventBus.radar_camera_follow_anchor_request, camera_follow_anchor)
	EventBus.subscribe_node(EventBus.radar_camera_unfollow_anchor_request, camera_unfollow_anchor)


# Run on every frame while the radar display's process is enabled. Follow the
# camera anchor.
func _process(_delta: float) -> void:
	camera.position = _camera_anchor.position


# Render the current level to the radar display.
func render_level() -> void:
	var pit_polygons: Array[PackedVector2Array] = []
	
	for pit_node in get_tree().get_nodes_in_group("radar_pits"):
		pit_polygons.append_array(_get_node_polygons(pit_node))
		pit_node.queue_free()
	
	_pits_renderer.render(pit_polygons)
	
	var floor_segments: PackedVector2Array = PackedVector2Array()
	
	for floor_node in get_tree().get_nodes_in_group("radar_floors"):
		floor_segments.append_array(_get_node_segments(floor_node))
		floor_node.queue_free()
	
	_floors_renderer.render(floor_segments)
	
	var wall_segments: PackedVector2Array = PackedVector2Array()
	
	for wall_node in get_tree().get_nodes_in_group("radar_walls"):
		wall_segments.append_array(_get_node_segments(wall_node))
		wall_node.queue_free()
	
	_walls_renderer.render(wall_segments)


# Render a radar point to the radar display.
func render_point(radar_point: RadarPoint) -> void:
	var point_renderer: RadarPointRenderer = PointRendererScene.instantiate()
	_points_container.add_child(point_renderer)
	point_renderer.set_radar_point(radar_point)


# Render a vision area to the radar display.
func render_vision_area(vision_area: VisionArea) -> void:
	var vision_area_renderer: RadarVisionAreaRenderer = VisionAreaRendererScene.instantiate()
	_vision_area_container.add_child(vision_area_renderer)
	vision_area_renderer.set_vision_area(vision_area)


func render_laser_wall(laser_wall: LaserWall) -> void:
	var laser_wall_renderer: RadarLaserWallRenderer = LaserWallRendererScene.instantiate()
	_laser_wall_container.add_child(laser_wall_renderer)
	laser_wall_renderer.set_laser_wall(laser_wall)


# Start following a camera anchor.
func camera_follow_anchor(camera_anchor_ref: Node2D) -> void:
	if _camera_anchor == camera_anchor_ref:
		return
	elif not camera_anchor_ref:
		return
	
	_camera_anchor = camera_anchor_ref
	camera.position = _camera_anchor.position
	set_process(true)


# Stop following the current camera anchor.
func camera_unfollow_anchor() -> void:
	if not _camera_anchor:
		return
	
	set_process(false)
	camera.position = _camera_anchor.position
	_camera_anchor = null


# Set the radar display's scale.
func _set_display_scale(value: float) -> void:
	if value < 100.0:
		ConfigBus.set_float("radar.scale", 100.0)
		return
	elif value > 300.0:
		ConfigBus.set_float("radar.scale", 300.0)
		return
	
	_viewport.size = RESOLUTION * value * 0.01
	size = _viewport.size
	position.x = 624.0 - size.x
	camera.zoom = Vector2(value, value) / 800.0


# Set the radar display's background color.
func _set_background_color(value: String) -> void:
	var color: Color = DisplayManager.get_palette_color(value)
	_background_polygon.color.r = color.r
	_background_polygon.color.g = color.g
	_background_polygon.color.b = color.b


# Set the radar display's background opacity.
func _set_background_opacity(value: float) -> void:
	if value < 0.0:
		ConfigBus.set_float("radar.background_opacity", 0.0)
		return
	elif value > 100.0:
		ConfigBus.set_float("radar.background_opacity", 100.0)
		return
	
	_background_polygon.color.a = value * 0.01


# Set the radar display's wall color.
func _set_wall_color(value: String) -> void:
	_walls_renderer.set_color(DisplayManager.get_palette_color(value))


# Set the radar display's floor color.
func _set_floor_color(value: String) -> void:
	_floors_renderer.set_color(DisplayManager.get_palette_color(value))


# Recursively get a node and its children's polygons.
func _get_node_polygons(node: Node) -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	
	for child in node.get_children():
		polygons.append_array(_get_node_polygons(child))
	
	if node is Polygon2D:
		polygons.push_back(_transform_points(node.polygon, node.global_transform))
	
	return polygons


# Recursively get a node and it's children's line segments.
func _get_node_segments(node: Node) -> PackedVector2Array:
	var segments: PackedVector2Array = PackedVector2Array()
	
	for child in node.get_children():
		segments.append_array(_get_node_segments(child))
	
	if node is Line2D:
		segments.append_array(_segment_line(_transform_points(node.points, node.global_transform)))
	elif node is Polygon2D:
		segments.append_array(
				_segment_polygon(_transform_points(node.polygon, node.global_transform)))
	
	return segments


# Transform an array of points.
func _transform_points(points: PackedVector2Array, transform: Transform2D) -> PackedVector2Array:
	for i in range(points.size()):
		points[i] = transform.translated(points[i]).origin
	
	return points


# Segment a line.
func _segment_line(points: PackedVector2Array) -> PackedVector2Array:
	var segments: PackedVector2Array = PackedVector2Array()
	
	for i in range(points.size() - 1):
		segments.push_back(points[i])
		segments.push_back(points[i + 1])
	
	return segments


# Segment a polygon.
func _segment_polygon(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() >= 3:
		points.push_back(points[0])
	
	return _segment_line(points)
