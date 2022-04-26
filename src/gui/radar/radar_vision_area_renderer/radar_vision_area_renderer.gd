class_name RadarVisionAreaRenderer
extends Polygon2D

# Radar Vision Area Renderer
# A radar vision area renderer is a component of the radar display that renders
# the size, position, and rotation of a vision area.

const _COLOR_NORMAL: Color = Color("#45c5d9")
const _COLOR_CAUTION: Color = Color("#fff959")
const _COLOR_ALERT: Color = Color("#ad1818")

var vision_area: VisionArea = null setget set_vision_area

# Virtual _ready method. Runs when the radar vision area renderer enters the
# scene tree. Disables the radar vision area renderer's physics process:
func _ready() -> void:
	set_physics_process(false)


# Virtual _physics_process method. Runs on every physics frame while the radar
# vision area renderer's physics process is enabled. Updates the radar vision
# area's position and rotation:
func _physics_process(_delta: float) -> void:
	position = vision_area.global_position
	rotation = vision_area.global_rotation


# Sets the radar vision area renderer's vision area:
func set_vision_area(value: VisionArea) -> void:
	if not value:
		hide()
		set_physics_process(false)
		
		if vision_area and vision_area.is_connected("radar_display_changed", self, "set_display"):
			vision_area.disconnect("radar_display_changed", self, "set_display")
		
		vision_area = null
		return
	
	vision_area = value
	var near_edge_pos: Vector2 = vision_area.get_near_edge_pos()
	var far_edge_pos: Vector2 = vision_area.get_far_edge_pos()
	var curve_pos: Vector2 = vision_area.get_curve_pos()
	var front_pos: Vector2 = vision_area.get_front_pos()
	polygon[0] = far_edge_pos * Vector2(1.0, -1.0)
	polygon[1] = curve_pos * Vector2(1.0, -1.0)
	polygon[2] = front_pos
	polygon[3] = curve_pos
	polygon[4] = far_edge_pos
	polygon[5] = near_edge_pos
	polygon[6] = near_edge_pos * Vector2(1.0, -1.0)
	set_display(vision_area.radar_display)
	
	var error: int = vision_area.connect("radar_display_changed", self, "set_display")
	
	if error and vision_area.is_connected("radar_display_changed", self, "set_display"):
		vision_area.disconnect("radar_display_changed", self, "set_display")
	
	position = vision_area.global_position
	rotation = vision_area.global_rotation
	show()
	set_physics_process(true)


# Gets whether the radar vision area renderer is available in the radar vision
# area renderer pool:
func is_available() -> bool:
	return not vision_area


# Sets the radar vision area renderer's display:
func set_display(display: int) -> void:
	var target_color: Color = _COLOR_NORMAL
	
	match display:
		VisionArea.RadarDisplay.NONE:
			target_color = Color.transparent
		VisionArea.RadarDisplay.CAUTION:
			target_color = _COLOR_CAUTION
		VisionArea.RadarDisplay.ALERT:
			target_color = _COLOR_ALERT
	
	# warning-ignore: RETURN_VALUE_DISCARDED
	create_tween().tween_property(self, "modulate", target_color, 0.08).set_trans(Tween.TRANS_SINE)


# Clears the radar vision area renderer's vision area:
func clear_vision_area() -> void:
	set_vision_area(null)
