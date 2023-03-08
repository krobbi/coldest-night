class_name RadarPointRenderer
extends Polygon2D

# Radar Point Renderer
# A radar point renderer is a component of the radar display that renders a
# radar point.

const PLAYER_COLOR: Color = Color("#f1f2f1")
const GUARD_COLOR: Color = Color("#ad1818")
const COLLECTABLE_COLOR: Color = Color("#ff980e")

var _radar_point: RadarPoint = null

onready var _color_polygon: Polygon2D = $ColorPolygon

# Run when the radar point renderer finished entering the scene tree. Disable
# the radar point renderer's physics process.
func _ready() -> void:
	set_physics_process(false)


# Run on every physics frame while the radar point renderer has a radar point.
# Update the radar point renderer's position.
func _physics_process(_delta: float) -> void:
	position = _radar_point.global_position


# Set the radar point renderer's display style.
func set_display_style(value: int) -> void:
	match value:
		RadarPoint.DisplayStyle.PLAYER:
			_color_polygon.color = PLAYER_COLOR
		RadarPoint.DisplayStyle.GUARD:
			_color_polygon.color = GUARD_COLOR
		RadarPoint.DisplayStyle.COLLECTABLE:
			_color_polygon.color = COLLECTABLE_COLOR
	
	visible = value != RadarPoint.DisplayStyle.NONE


# Set the radar point renderer's radar point.
func set_radar_point(value: RadarPoint) -> void:
	if _radar_point:
		if _radar_point.is_connected("tree_exiting", self, "queue_free"):
			_radar_point.disconnect("tree_exiting", self, "queue_free")
		
		if _radar_point.is_connected("display_style_changed", self, "set_display_style"):
			_radar_point.disconnect("display_style_changed", self, "set_display_style")
	
	if not value:
		set_physics_process(false)
		_radar_point = null
		return
	
	if value.connect("tree_exiting", self, "queue_free", [], CONNECT_ONESHOT) != OK:
		if value.is_connected("tree_exiting", self, "queue_free"):
			value.disconnect("tree_exiting", self, "queue_free")
		
		return
	
	if value.connect("display_style_changed", self, "set_display_style") != OK:
		if value.is_connected("display_style_changed", self, "set_display_style"):
			value.disconnect("display_style_changed", self, "set_display_style")
	
	_radar_point = value
	position = _radar_point.global_position
	set_display_style(_radar_point.get_display_style())
	set_physics_process(true)
