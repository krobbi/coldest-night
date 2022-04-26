class_name Radar
extends ViewportContainer

# Radar Display
# The radar display is a HUD element of the overworld scene that displays a map
# of the current level.

const VisionAreaRenderer: PackedScene = preload(
		"res://gui/radar/radar_vision_area_renderer/radar_vision_area_renderer.tscn"
)
const ActorRenderer: PackedScene = preload(
		"res://gui/radar/radar_actor_renderer/radar_actor_renderer.tscn"
)
const LaserWallRenderer: PackedScene = preload(
		"res://gui/radar/radar_laser_wall_renderer/radar_laser_wall_renderer.tscn"
)

const RESOLUTION: Vector2 = Vector2(128.0, 96.0)
const MAX_DISPLAY_SCALE: float = 3.0

var _display_scale: float = 1.0
var _display_opacity: float = 0.5
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

# Virtual _ready method. Runs when the radar display finishes entering the scene
# tree. Disables the radar display's process, sets the radar display's display
# scale, and connects the radar display to the configuration bus and event bus:
func _ready() -> void:
	set_process(false)
	set_display_scale(Global.config.get_float("accessibility.radar_scale"))
	set_display_opacity(Global.config.get_float("accessibility.radar_opacity"))
	Global.config.connect_float("accessibility.radar_scale", self, "set_display_scale")
	Global.config.connect_float("accessibility.radar_opacity", self ,"set_display_opacity")
	Global.events.safe_connect("radar_refresh_entities_request", self, "refresh_entities")
	Global.events.safe_connect("radar_render_node_request", self, "render_node")
	Global.events.safe_connect("radar_clear_request", self, "clear")
	Global.events.safe_connect("radar_camera_follow_anchor_request", self, "camera_follow_anchor")
	Global.events.safe_connect(
			"radar_camera_unfollow_anchor_request", self, "camera_unfollow_anchor"
	)


# Virtual _process method. Runs on every frame while the radar display's process
# is enabled. Follows the camera anchor:
func _process(_delta: float) -> void:
	camera.position = _camera_anchor.position


# Virtual _exit_tree method. Runs when the radar display exits the scene tree.
# Disconnects the radar display from the configuration bus and event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect(
			"radar_camera_unfollow_anchor_request", self, "camera_unfollow_anchor"
	)
	Global.events.safe_disconnect(
			"radar_camera_follow_anchor_request", self, "camera_follow_anchor"
	)
	Global.events.safe_disconnect("radar_clear_request", self, "clear")
	Global.events.safe_disconnect("radar_render_node_request", self, "render_node")
	Global.events.safe_disconnect("radar_refresh_entities_request", self, "refresh_entities")
	Global.config.disconnect_value("accessibility.radar_opacity", self, "set_display_opacity")
	Global.config.disconnect_value("accessibility.radar_scale", self, "set_display_scale")


# Sets the radar display's display scale:
func set_display_scale(value: float) -> void:
	if value < 1.0 or is_nan(value):
		value = 1.0
	elif value > MAX_DISPLAY_SCALE or is_inf(value):
		value = MAX_DISPLAY_SCALE
	
	_display_scale = value
	yield(Global.tree, "idle_frame")
	_viewport.size = RESOLUTION * _display_scale
	rect_size = RESOLUTION * _display_scale
	rect_position.x = 624.0 - rect_size.x
	camera.zoom = Vector2(8.0, 8.0) / _display_scale
	Global.config.set_float("accessibility.radar_scale", _display_scale)


# Sets the radar display's display opacity:
func set_display_opacity(value: float) -> void:
	if value < 0.0:
		value = 0.0
	elif value > 100.0 or is_inf(value) or is_nan(value):
		value = 100.0
	
	_display_opacity = value
	_background_polygon.color.a = _display_opacity * 0.01
	Global.config.set_float("accessibility.radar_opacity", _display_opacity)


# Refreshes all rendered entities on the radar display:
func refresh_entities() -> void:
	clear_laser_walls()
	clear_actors()
	clear_vision_areas()
	
	for vision_area in Global.tree.get_nodes_in_group("vision_areas"):
		if vision_area is VisionArea:
			render_vision_area(vision_area)
	
	for actor in Global.tree.get_nodes_in_group("actors"):
		if actor is Actor:
			render_actor(actor)
	
	for laser_wall in Global.tree.get_nodes_in_group("laser_walls"):
		if laser_wall is LaserWall:
			render_laser_wall(laser_wall)


# Renders a vision area to the radar display:
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


# Renders an actor to the radar display:
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


# Renders a laser wall renderer to the radar display:
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


# Renders a radar data node to the radar display:
func render_node(node: Node) -> void:
	if node.has_node("Pits"):
		_pits_renderer.render(_collect_node_polygons(node.get_node("Pits")))
	else:
		_pits_renderer.clear()
	
	if node.has_node("Floors"):
		_floors_renderer.render(_collect_node_segments(node.get_node("Floors")))
	else:
		_floors_renderer.clear()
	
	if node.has_node("Walls"):
		_walls_renderer.render(_collect_node_segments(node.get_node("Walls")))
	else:
		_walls_renderer.clear()


# Clears the radar display:
func clear() -> void:
	_walls_renderer.clear()
	clear_laser_walls()
	clear_actors()
	clear_vision_areas()
	_floors_renderer.clear()
	_pits_renderer.clear()


# Clears all laser walls from the radar display:
func clear_laser_walls() -> void:
	for laser_wall_renderer in _laser_wall_renderers:
		laser_wall_renderer.clear_laser_wall()


# Clears all actors from the radar display:
func clear_actors() -> void:
	for actor_renderer in _actor_renderers:
		actor_renderer.clear_actor()


# Clears all vision area renderers from the radar display:
func clear_vision_areas() -> void:
	for vision_area_renderer in _vision_area_renderers:
		vision_area_renderer.clear_vision_area()


# Starts following a camera anchor:
func camera_follow_anchor(camera_anchor_ref: Node2D) -> void:
	if _camera_anchor == camera_anchor_ref:
		return
	elif not camera_anchor_ref:
		return
	
	_camera_anchor = camera_anchor_ref
	camera.position = _camera_anchor.position
	set_process(true)


# Stops following the current camera anchor:
func camera_unfollow_anchor() -> void:
	if not _camera_anchor:
		return
	
	set_process(false)
	camera.position = _camera_anchor.position
	_camera_anchor = null


# Recursively collects polygons from a node and its children:
func _collect_node_polygons(node: Node, depth: int = 8) -> Array:
	var polygons: Array = []
	
	if node is Polygon2D:
		polygons.push_back(node.polygon)
	
	if depth:
		depth -= 1
		
		for child in node.get_children():
			polygons.append_array(_collect_node_polygons(child, depth))
	
	return polygons


# Recursively collects line segments from a node and its children:
func _collect_node_segments(node: Node, depth: int = 8) -> PoolVector2Array:
	var segments: PoolVector2Array = PoolVector2Array()
	
	if node is Line2D:
		segments.append_array(_segment_line(node.points))
	elif node is Polygon2D:
		segments.append_array(_segment_polygon(node.polygon))
	
	if depth:
		depth -= 1
		
		for child in node.get_children():
			segments.append_array(_collect_node_segments(child, depth))
	
	return segments


# Segments a multi-segment line:
func _segment_line(points: PoolVector2Array) -> PoolVector2Array:
	var segment_count: int = points.size() - 1
	var segments: PoolVector2Array = PoolVector2Array()
	
	if segment_count < 1:
		return segments
	
	segments.resize(segment_count * 2)
	
	for i in range(segment_count):
		segments[i * 2] = points[i]
		segments[i * 2 + 1] = points[i + 1]
	
	return segments


# Segments a polygon:
func _segment_polygon(points: PoolVector2Array) -> PoolVector2Array:
	if points.size() >= 3:
		points.push_back(points[0])
	
	return _segment_line(points)
