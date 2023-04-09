class_name LaserWall
extends StaticBody2D

# Laser Wall
# A laser wall is an entity that forms an obstruction until a flag condition is
# met.

signal wall_visibility_changed(is_wall_visible: bool)

enum AppearanceCondition {ALWAYS, NEVER, RELEASE, DEBUG, EQ, NE, GT, GE, LT, LE}

@export var appearance_condition: AppearanceCondition = AppearanceCondition.ALWAYS
@export var size: Vector2 = Vector2(64.0, 0.0)
@export var flag: String
@export var compare_value: int

var _save_data: SaveData = SaveManager.get_working_data()

@onready var _obstructive_shape: CollisionShape2D = $ObstructiveShape

# Run when the laser wall finishes entering the scene tree. Set the laser wall's
# extents, connect the laser wall to the current working save data, and emit a
# radar render laser wall request.
func _ready() -> void:
	var a: Vector2 = size * -1.0
	var b: Vector2 = size
	
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
	
	if _eval_appearance_condition(_save_data.get_flag(flag)):
		show_wall()
	else:
		hide_wall()
	
	if _save_data.flag_changed.connect(_on_flag_changed) != OK:
		if _save_data.flag_changed.is_connected(_on_flag_changed):
			_save_data.flag_changed.disconnect(_on_flag_changed)
	
	EventBus.radar_render_laser_wall_request.emit(self)


# Run when the laser wall exits the scene tree. Disconnect the laser wall from
# the current working save data.
func _exit_tree() -> void:
	if _save_data.flag_changed.is_connected(_on_flag_changed):
		_save_data.flag_changed.disconnect(_on_flag_changed)


# Show the laser wall.
func show_wall() -> void:
	_obstructive_shape.set_deferred("disabled", false)
	show()
	wall_visibility_changed.emit(true)


# Hide the laser wall.
func hide_wall() -> void:
	hide()
	_obstructive_shape.set_deferred("disabled", true)
	wall_visibility_changed.emit(false)


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
func _on_flag_changed(changed_flag: String, value: int) -> void:
	if changed_flag != flag:
		return
	
	if _eval_appearance_condition(value):
		show_wall()
	else:
		hide_wall()
