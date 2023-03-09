class_name RadarVisionAreaRenderer
extends Polygon2D

# Radar Vision Area Renderer
# A radar vision area renderer is a component of the radar display that renders
# the size, position, and rotation of a vision area.

var _vision_area: VisionArea = null
var _display_style: int = VisionArea.DisplayStyle.NONE
var _colors: Dictionary = {}

# Run when the radar vision area renderer enters the scene tree. Disable the
# radar vision area renderer's physics process and subscribe the radar vision
# area renderer to the configuration bus.
func _ready() -> void:
	set_physics_process(false)
	_add_style("radar.normal_cone_color", VisionArea.DisplayStyle.NORMAL)
	_add_style("radar.caution_cone_color", VisionArea.DisplayStyle.CAUTION)
	_add_style("radar.alert_cone_color", VisionArea.DisplayStyle.ALERT)


# Run on every physics frame while the radar vision area renderer's has a vision
# area. Update radar vision area's transform.
func _physics_process(_delta: float) -> void:
	transform = _vision_area.global_transform


# Set the radar vision area renderer's display style.
func set_display_style(value: int) -> void:
	_display_style = value
	modulate = _colors.get(_display_style, Color.transparent)
	visible = value != VisionArea.DisplayStyle.NONE


# Set the radar vision area renderer's vision area.
func set_vision_area(value: VisionArea) -> void:
	if _vision_area:
		if _vision_area.is_connected("tree_exiting", self, "queue_free"):
			_vision_area.disconnect("tree_exiting", self, "queue_free")
		
		if _vision_area.is_connected("display_style_changed", self, "set_display_style"):
			_vision_area.disconnect("display_style_changed", self, "set_display_style")
	
	if not value:
		set_physics_process(false)
		_vision_area = null
		return
	
	if value.connect("tree_exiting", self, "queue_free", [], CONNECT_ONESHOT) != OK:
		if value.is_connected("tree_exiting", self, "queue_free"):
			value.disconnect("tree_exiting", self, "queue_free")
		
		return
	
	if value.connect("display_style_changed", self, "set_display_style") != OK:
		if value.is_connected("display_style_changed", self, "set_display_style"):
			value.disconnect("display_style_changed", self, "set_display_style")
	
	_vision_area = value
	var near_edge_pos: Vector2 = _vision_area.get_near_edge_pos()
	var far_edge_pos: Vector2 = _vision_area.get_far_edge_pos()
	var curve_pos: Vector2 = _vision_area.get_curve_pos()
	var front_pos: Vector2 = _vision_area.get_front_pos()
	polygon[0] = far_edge_pos * Vector2(1.0, -1.0)
	polygon[1] = curve_pos * Vector2(1.0, -1.0)
	polygon[2] = front_pos
	polygon[3] = curve_pos
	polygon[4] = far_edge_pos
	polygon[5] = near_edge_pos
	polygon[6] = near_edge_pos * Vector2(1.0, -1.0)
	transform = _vision_area.global_transform
	set_display_style(_vision_area.get_display_style())
	set_physics_process(true)


# Add a display style to the radar vision area renderer.
func _add_style(config_key: String, config_style: int) -> void:
	ConfigBus.subscribe_node_string(config_key, self, "_on_config_changed", [config_style])


# Run when the radar vision area renderer's configuration changes. Update the
# display style colors.
func _on_config_changed(value: String, config_style: int) -> void:
	_colors[config_style] = DisplayManager.get_palette_color(value)
	set_display_style(_display_style)
