extends ViewportContainer

# Radar Display
# The radar display is a HUD element of the overworld scene that displays a map
# of the current level.

const VisionAreaRenderer: PackedScene = preload(
		"res://gui/radar/radar_vision_area_renderer/radar_vision_area_renderer.tscn")
const ActorRenderer: PackedScene = preload(
		"res://gui/radar/radar_actor_renderer/radar_actor_renderer.tscn")
const LaserWallRenderer: PackedScene = preload(
		"res://gui/radar/radar_laser_wall_renderer/radar_laser_wall_renderer.tscn")

const RESOLUTION: Vector2 = Vector2(128.0, 96.0)

var _vision_area_renderers: Array = []
var _actor_renderers: Array = []
var _laser_wall_renderers: Array = []
var _camera_anchor: Node2D = null

onready var camera: Camera2D = $Viewport/Foreground/Camera

onready var _viewport: Viewport = $Viewport
onready var _background_polygon: Polygon2D = $Viewport/Background/ColorPolygon
onready var _pits_renderer: RadarPolygonRenderer = $Viewport/Foreground/Pits
onready var _floors_renderer: RadarSegmentRenderer = $Viewport/Foreground/Floors
onready var _vision_area_container: Node2D = $Viewport/Foreground/VisionAreas
onready var _actor_container: Node2D = $Viewport/Foreground/Actors
onready var _laser_wall_container: Node2D = $Viewport/Foreground/LaserWalls
onready var _walls_renderer: RadarSegmentRenderer = $Viewport/Foreground/Walls

# Run when the radar display finishes entering the scene tree. Disable the radar
# display's process and subscribe the radar display to the configuration bus and
# event bus.
func _ready() -> void:
	set_process(false)
	ConfigBus.subscribe_node_bool("radar.visible", self, "set_visible")
	ConfigBus.subscribe_node_float("radar.scale", self, "_set_display_scale")
	ConfigBus.subscribe_node_float("radar.background_opacity", self ,"_set_background_opacity")
	EventBus.subscribe_node("radar_clear_request", self, "clear")
	EventBus.subscribe_node("radar_render_level_request", self, "render_level")
	EventBus.subscribe_node("radar_referesh_entities_request", self, "refresh_entities")
	EventBus.subscribe_node("radar_camera_follow_anchor_request", self, "camera_follow_anchor")
	EventBus.subscribe_node("radar_camera_unfollow_anchor_request", self, "camera_unfollow_anchor")


# Run on every frame while the radar display's process is enabled. Follow the
# camera anchor.
func _process(_delta: float) -> void:
	camera.position = _camera_anchor.position


# Refresh all rendered entities on the radar display.
func refresh_entities() -> void:
	clear_laser_walls()
	clear_actors()
	clear_vision_areas()
	
	for vision_area in get_tree().get_nodes_in_group("vision_areas"):
		if vision_area is VisionArea:
			render_vision_area(vision_area)
	
	for actor in get_tree().get_nodes_in_group("actors"):
		if actor is Actor:
			render_actor(actor)
	
	for laser_wall in get_tree().get_nodes_in_group("laser_walls"):
		if laser_wall is LaserWall:
			render_laser_wall(laser_wall)


# Render a vision area to the radar display.
func render_vision_area(vision_area: VisionArea) -> void:
	for vision_area_renderer in _vision_area_renderers:
		if vision_area_renderer.is_available():
			vision_area_renderer.vision_area = vision_area
			return
	
	var vision_area_renderer: RadarVisionAreaRenderer = VisionAreaRenderer.instance()
	vision_area_renderer.name = "VisionArea%d" % (_vision_area_renderers.size() + 1)
	_vision_area_container.add_child(vision_area_renderer)
	vision_area_renderer.vision_area = vision_area
	_vision_area_renderers.push_back(vision_area_renderer)


# Render an actor to the radar display.
func render_actor(actor: Actor) -> void:
	for actor_renderer in _actor_renderers:
		if actor_renderer.is_available():
			actor_renderer.actor = actor
			return
	
	var actor_renderer: RadarActorRenderer = ActorRenderer.instance()
	actor_renderer.name = "Actor%d" % (_actor_renderers.size() + 1)
	_actor_container.add_child(actor_renderer)
	actor_renderer.actor = actor
	_actor_renderers.push_back(actor_renderer)


# Render a laser wall renderer to the radar display.
func render_laser_wall(laser_wall: LaserWall) -> void:
	for laser_wall_renderer in _laser_wall_renderers:
		if laser_wall_renderer.is_available():
			laser_wall_renderer.laser_wall = laser_wall
			return
	
	var laser_wall_renderer: RadarLaserWallRenderer = LaserWallRenderer.instance()
	laser_wall_renderer.name = "LaserWall%d" % (_laser_wall_renderers.size() + 1)
	_laser_wall_container.add_child(laser_wall_renderer)
	laser_wall_renderer.laser_wall = laser_wall
	_laser_wall_renderers.push_back(laser_wall_renderer)


# Render the current level to the radar display.
func render_level() -> void:
	var pit_polygons: Array = []
	
	for pit_node in get_tree().get_nodes_in_group("radar_pits"):
		pit_polygons.append_array(_get_node_polygons(pit_node))
		pit_node.queue_free()
	
	_pits_renderer.render(pit_polygons)
	
	var floor_segments: PoolVector2Array = PoolVector2Array()
	
	for floor_node in get_tree().get_nodes_in_group("radar_floors"):
		floor_segments.append_array(_get_node_segments(floor_node))
		floor_node.queue_free()
	
	_floors_renderer.render(floor_segments)
	
	var wall_segments: PoolVector2Array = PoolVector2Array()
	
	for wall_node in get_tree().get_nodes_in_group("radar_walls"):
		wall_segments.append_array(_get_node_segments(wall_node))
		wall_node.queue_free()
	
	_walls_renderer.render(wall_segments)


# Clear the radar display.
func clear() -> void:
	_walls_renderer.clear()
	clear_laser_walls()
	clear_actors()
	clear_vision_areas()
	_floors_renderer.clear()
	_pits_renderer.clear()


# Clear all laser walls from the radar display.
func clear_laser_walls() -> void:
	for laser_wall_renderer in _laser_wall_renderers:
		laser_wall_renderer.clear_laser_wall()


# Clear all actors from the radar display.
func clear_actors() -> void:
	for actor_renderer in _actor_renderers:
		actor_renderer.clear_actor()


# Clear all vision area renderers from the radar display.
func clear_vision_areas() -> void:
	for vision_area_renderer in _vision_area_renderers:
		vision_area_renderer.clear_vision_area()


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
	if value < 1.0:
		ConfigBus.set_float("radar.scale", 1.0)
		return
	elif value > 3.0:
		ConfigBus.set_float("radar.scale", 3.0)
		return
	
	_viewport.size = RESOLUTION * value
	rect_size = RESOLUTION * value
	rect_position.x = 624.0 - rect_size.x
	camera.zoom = Vector2(8.0, 8.0) / value


# Set the radar display's background opacity.
func _set_background_opacity(value: float) -> void:
	if value < 0.0:
		ConfigBus.set_float("radar.background_opacity", 0.0)
		return
	elif value > 100.0:
		ConfigBus.set_float("radar.background_opacity", 100.0)
		return
	
	_background_polygon.color.a = value * 0.01


# Recursively get a node and its children's polygons.
func _get_node_polygons(node: Node) -> Array:
	var polygons: Array = []
	
	for child in node.get_children():
		polygons.append_array(_get_node_polygons(child))
	
	if node is Polygon2D:
		polygons.push_back(_transform_points(node.polygon, node.global_transform))
	
	return polygons


# Recursively get a node and it's children's line segments.
func _get_node_segments(node: Node) -> PoolVector2Array:
	var segments: PoolVector2Array = PoolVector2Array()
	
	for child in node.get_children():
		segments.append_array(_get_node_segments(child))
	
	if node is Line2D:
		segments.append_array(_segment_line(_transform_points(node.points, node.global_transform)))
	elif node is Polygon2D:
		segments.append_array(
				_segment_polygon(_transform_points(node.polygon, node.global_transform)))
	
	return segments


# Transform an array of points.
func _transform_points(points: PoolVector2Array, transform: Transform2D) -> PoolVector2Array:
	for i in range(points.size()):
		points[i] = transform.translated(points[i]).origin
	
	return points


# Segment a line.
func _segment_line(points: PoolVector2Array) -> PoolVector2Array:
	var segments: PoolVector2Array = PoolVector2Array()
	
	for i in range(points.size() - 1):
		segments.push_back(points[i])
		segments.push_back(points[i + 1])
	
	return segments


# Segment a polygon.
func _segment_polygon(points: PoolVector2Array) -> PoolVector2Array:
	if points.size() >= 3:
		points.push_back(points[0])
	
	return _segment_line(points)
