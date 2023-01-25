class_name LevelCamera
extends Camera2D

# Level Camera
# The level camera is a component of the overworld camera that can have its
# limits set to boundary positions, follow remote anchor nodes, and focus on
# fixed world positions.

var _anchor: Node2D = null
var _anchor_stack: Array = []

# Run when the level camera enters the scene tree. Disable the level camera's
# process, connect the Global display manager's screen stretch changed signal to
# snapping the camera, and subscribe the level camera to the event bus.
func _ready() -> void:
	set_process(false)
	var error: int = Global.display.connect("screen_stretch_changed", self, "snap")
	
	if error and Global.display.is_connected("screen_stretch_changed", self, "snap"):
		Global.display.disconnect("screen_stretch_changed", self, "snap")
	
	EventBus.subscribe_node("camera_set_limits_request", self, "set_limits")
	EventBus.subscribe_node("camera_follow_anchor_request", self, "follow_anchor")
	EventBus.subscribe_node("camera_unfollow_anchor_request", self, "unfollow_anchor")


# Run on every frame while the level camera's process is enabled. Follow the
# anchor node.
func _process(_delta: float) -> void:
	position = _anchor.global_position


# Run when the level camera exits the scene tree. Disconnect the Global display
# manager's screen stretch changed signal from snapping the camera.
func _exit_tree() -> void:
	if Global.display.is_connected("screen_stretch_changed", self, "snap"):
		Global.display.disconnect("screen_stretch_changed", self, "snap")


# Set the level camera's limits to boundary positions.
func set_limits(top_left: Vector2, bottom_right: Vector2) -> void:
	limit_left = int(top_left.x)
	limit_top = int(top_left.y)
	limit_right = int(bottom_right.x)
	limit_bottom = int(bottom_right.y)
	snap()


# Follow a new anchor.
func follow_anchor(anchor_ref: Node2D) -> void:
	_anchor = anchor_ref
	
	if _anchor_stack.empty():
		position = _anchor.global_position
		snap()
		set_process(true)
	
	_anchor_stack.push_back(_anchor)


# Unfollow the current anchor.
func unfollow_anchor() -> void:
	if _anchor_stack.empty():
		return
	elif _anchor_stack.size() == 1:
		set_process(false)
		position = _anchor.global_position
		_anchor = null
		_anchor_stack.remove(0)
		return
	
	_anchor_stack.remove(_anchor_stack.size() - 1)
	_anchor = _anchor_stack[-1]


# Snap the level camera to its target position.
func snap() -> void:
	force_update_scroll()
	reset_smoothing()
