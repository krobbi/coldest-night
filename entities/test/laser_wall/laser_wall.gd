class_name LaserWall
extends StaticBody2D

# Laser Wall
# A laser wall is an entity that forms an obstruction until a flag condition is
# met.

signal wall_visibility_changed(wall_visible)

enum AppearanceCondition {ALWAYS, NEVER, RELEASE, DEBUG, EQ, NE, GT, GE, LT, LE}

export(AppearanceCondition) var appearance_condition: int = AppearanceCondition.ALWAYS
export(Vector2) var extents: Vector2 = Vector2(64.0, 0.0)
export(String) var flag_namespace: String = ""
export(String) var flag_key: String
export(int) var compare_value: int

var _save_data: SaveData = SaveManager.get_working_data()

onready var _obstructive_shape: CollisionShape2D = $ObstructiveShape

# Run when the laser wall finishes entering the scene tree. Set the laser wall's
# extents and connect the laser wall to the current working save data.
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
	
	if _eval_appearance_condition(_save_data.get_flag(flag_namespace, flag_key)):
		show_wall()
	else:
		hide_wall()
	
	if _save_data.connect("flag_changed", self, "_on_flag_changed") != OK:
		if _save_data.is_connected("flag_changed", self, "_on_flag_changed"):
			_save_data.disconnect("flag_changed", self, "_on_flag_changed")


# Run when the laser wall exits the scene tree. Disconnect the laser wall from
# the current working save data.
func _exit_tree() -> void:
	if _save_data.is_connected("flag_changed", self, "_on_flag_changed"):
		_save_data.disconnect("flag_changed", self, "_on_flag_changed")


# Show the laser wall.
func show_wall() -> void:
	_obstructive_shape.set_deferred("disabled", false)
	show()
	emit_signal("wall_visibility_changed", true)


# Hide the laser wall.
func hide_wall() -> void:
	hide()
	_obstructive_shape.set_deferred("disabled", true)
	emit_signal("wall_visibility_changed", false)


# Evaluate whether the laser wall should be shown based on a value.
func _eval_appearance_condition(value: int) -> bool:
	match appearance_condition:
		AppearanceCondition.NEVER:
			return false
		AppearanceCondition.RELEASE:
			return not OS.is_debug_build()
		AppearanceCondition.DEBUG:
			return OS.is_debug_build()
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


# Run when a flag is changed. Update whether the laser wall is shown.
func _on_flag_changed(namespace: String, key: String, value: int) -> void:
	if namespace != flag_namespace or key != flag_key:
		return
	
	if _eval_appearance_condition(value):
		show_wall()
	else:
		hide_wall()
