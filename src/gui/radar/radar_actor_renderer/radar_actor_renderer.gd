class_name RadarActorRenderer
extends Polygon2D

# Radar Actor Renderer
# A radar actor renderer is a component of the radar display that renders the
# position and type of an actor.

const COLOR_NONE: Color = Color.transparent
const COLOR_PLAYER: Color = Color("#f1f2f1")
const COLOR_IDLE: Color = Color("#80f1f2f1")
const COLOR_GUARD: Color = Color("#ad1818")

var actor: Actor = null setget set_actor

onready var _color_polygon: Polygon2D = $ColorPolygon

# Virtual _ready method. Runs when the radar actor renderer finishes entering
# the scene tree. Disables the radar actor renderer's physics process:
func _ready() -> void:
	set_physics_process(false)


# Virtual _physics_process method. Runs on every physics frame while the radar
# actor renderer has its physics process enabled. Updates the radar actor
# renderer's position:
func _physics_process(_delta: float) -> void:
	position = actor.position


# Sets the radar actor renderer's actor:
func set_actor(value: Actor) -> void:
	if not value:
		hide()
		set_physics_process(false)
		
		if actor and actor.is_connected("radar_display_changed", self, "set_display"):
			actor.disconnect("radar_display_changed", self, "set_display")
		
		actor = null
		return
	
	actor = value
	set_display(actor.radar_display)
	
	var error: int = actor.connect("radar_display_changed", self, "set_display")
	
	if error and actor.is_connected("radar_display_changed", self, "set_display"):
		actor.disconnect("radar_display_changed", self, "set_display")
	
	position = actor.position
	set_physics_process(true)
	show()


# Gets whether the radar actor renderer is available in the radar actor renderer
# pool:
func is_available() -> bool:
	return not actor


# Sets the radar actor renderer's display:
func set_display(display: int) -> void:
	match display:
		Actor.RadarDisplay.NONE:
			_color_polygon.color = COLOR_NONE
		Actor.RadarDisplay.PLAYER:
			_color_polygon.color = COLOR_PLAYER
		Actor.RadarDisplay.IDLE:
			_color_polygon.color = COLOR_IDLE
		Actor.RadarDisplay.GUARD:
			_color_polygon.color = COLOR_GUARD


# Clears the radar actor renderer's actor:
func clear_actor() -> void:
	set_actor(null)
