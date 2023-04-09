class_name RadarPointRenderer
extends Polygon2D

# Radar Point Renderer
# A radar point renderer is a component of the radar display that renders a
# radar point.

const PLAYER_COLOR: Color = Color("#f1f2f1")
const GUARD_COLOR: Color = Color("#ad1818")
const COLLECTABLE_COLOR: Color = Color("#ff980e")

var _radar_point: RadarPoint = null
var _display_style: RadarPoint.DisplayStyle = RadarPoint.DisplayStyle.NONE
var _colors: Dictionary = {}

@onready var _color_polygon: Polygon2D = $ColorPolygon

# Run when the radar point renderer finished entering the scene tree. Disable
# the radar point renderer's physics process and subscribe the radar point
# renderer to the coniguration bus.
func _ready() -> void:
	set_physics_process(false)
	_add_style("radar.player_color", RadarPoint.DisplayStyle.PLAYER)
	_add_style("radar.guard_color", RadarPoint.DisplayStyle.GUARD)
	_add_style("radar.collectable_color", RadarPoint.DisplayStyle.COLLECTABLE)


# Run on every physics frame while the radar point renderer has a radar point.
# Update the radar point renderer's position.
func _physics_process(_delta: float) -> void:
	position = _radar_point.global_position


# Set the radar point renderer's display style.
func set_display_style(value: RadarPoint.DisplayStyle) -> void:
	_display_style = value
	_color_polygon.color = _colors.get(_display_style, Color.TRANSPARENT)
	visible = _display_style != RadarPoint.DisplayStyle.NONE


# Set the radar point renderer's radar point.
func set_radar_point(value: RadarPoint) -> void:
	if _radar_point:
		if _radar_point.tree_exiting.is_connected(queue_free):
			_radar_point.tree_exiting.disconnect(queue_free)
		
		if _radar_point.display_style_changed.is_connected(set_display_style):
			_radar_point.display_style_changed.disconnect(set_display_style)
	
	if not value:
		set_physics_process(false)
		_radar_point = null
		return
	
	if value.tree_exiting.connect(queue_free, CONNECT_ONE_SHOT) != OK:
		if value.tree_exiting.is_connected(queue_free):
			value.tree_exiting.disconnect(queue_free)
		
		return
	
	if value.display_style_changed.connect(set_display_style) != OK:
		if value.display_style_changed.is_connected(set_display_style):
			value.display_style_changed.disconnect(set_display_style)
	
	_radar_point = value
	position = _radar_point.global_position
	set_display_style(_radar_point.get_display_style())
	set_physics_process(true)


# Add a display style to the radar point renderer.
func _add_style(config_key: String, config_style: RadarPoint.DisplayStyle) -> void:
	ConfigBus.subscribe_node_string(config_key, _on_config_changed.bind(config_style))


# Run when the radar point renderer's configuration changes. Update the display
# style colors.
func _on_config_changed(value: String, config_style: RadarPoint.DisplayStyle) -> void:
	_colors[config_style] = DisplayManager.get_palette_color(value)
	set_display_style(_display_style)
