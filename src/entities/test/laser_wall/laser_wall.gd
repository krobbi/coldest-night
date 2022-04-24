class_name LaserWall
extends StaticBody2D

# Laser Wall
# A laser wall is a test entity that forms an obstruction until a flag condition
# is met.

signal wall_visibility_changed(wall_visible)

enum AppearanceCondition {ALWAYS, NEVER, EQ, NE, GT, GE, LT, LE}

export(AppearanceCondition) var appearance_condition: int = AppearanceCondition.ALWAYS
export(Vector2) var extents: Vector2 = Vector2(64.0, 0.0)
export(String) var flag_namespace: String = ""
export(String) var flag_key: String
export(int) var compare_value: int

onready var _obstructive_shape: CollisionShape2D = $ObstructiveShape

# Virtual _ready method. Runs when the laser wall finishes entering the scene
# tree. Sets the laser wall's extents and connects the laser wall to the event
# bus:
func _ready() -> void:
	var a: Vector2 = extents * -1.0
	var b: Vector2 = extents
	
	var shape: SegmentShape2D = SegmentShape2D.new()
	shape.a = a
	shape.b = b
	_obstructive_shape.shape = shape
	
	var shadow: Line2D = $Shadow
	shadow.points[0] = a
	shadow.points[1] = b
	
	var line: Line2D = $Line
	line.points[0] = a
	line.points[1] = b
	
	if _eval_appearance_condition():
		show_wall()
	else:
		hide_wall()
	
	Global.events.safe_connect("flag_changed", self, "_on_events_flag_changed")


# Virtual _exit_tree method. Runs when the laser wall exits the scene tree.
# Disconnects the laser wall from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("flag_changed", self, "_on_events_flag_changed")


# Shows the laser wall:
func show_wall() -> void:
	_obstructive_shape.set_deferred("disabled", false)
	show()
	emit_signal("wall_visibility_changed", true)


# Hides the laser wall:
func hide_wall() -> void:
	hide()
	_obstructive_shape.set_deferred("disabled", true)
	emit_signal("wall_visibility_changed", false)


# Evaluates the laser wall's appearance condition:
func _eval_appearance_condition() -> bool:
	var value: int = Global.save.get_working_data().get_flag(flag_namespace, flag_key)
	
	match appearance_condition:
		AppearanceCondition.NEVER:
			return false
		AppearanceCondition.EQ:
			return value == compare_value
		AppearanceCondition.NE:
			return value != compare_value
		AppearanceCondition.GT:
			return value > compare_value
		AppearanceCondition.GE:
			return value >= compare_value
		AppearanceCondition.LT:
			return value < compare_value
		AppearanceCondition.LE:
			return value <= compare_value
		AppearanceCondition.ALWAYS, _:
			return true


# Signal callback for flag_changed on the event bus. Updates whether the laser
# wall is shown:
func _on_events_flag_changed(namespace: String, key: String, _value: int) -> void:
	if namespace != flag_namespace or key != flag_key:
		return
	elif _eval_appearance_condition():
		show_wall()
	else:
		hide_wall()
