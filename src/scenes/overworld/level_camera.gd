class_name LevelCamera
extends Camera2D

# Level Camera
# The level camera is a component of the overworld camera that can have its
# limits set to boundary positions, follow remote anchor nodes, and focus on
# fixed world positions.

var _is_focusing: bool = false
var _anchor: Node2D = null
var _anchor_stack: Array = []

# Virtual _ready method. Runs when the level camera enters the scene tree.
# Disables the level camera's process, connects the Global display manager's
# screen stretch changed signal to snapping the camera, and connects the level
# camera to the event bus:
func _ready() -> void:
	set_process(false)
	var error: int = Global.display.connect("screen_stretch_changed", self, "snap")
	
	if error and Global.display.is_connected("screen_stretch_changed", self, "snap"):
		Global.display.disconnect("screen_stretch_changed", self, "snap")
	
	Global.events.safe_connect("camera_unfocus_request", self, "unfocus")


# Virtual _process method. Runs on every frame while the level camera's process
# is enabled. Follows the anchor node:
func _process(_delta: float) -> void:
	position = _anchor.global_position


# Virtual _exit_tree method. Runs when the level camera exits the scene tree.
# Disconnects the Global display manager's screen stretch changed signal from
# snapping the camera and disconnects the level camera from the event bus:
func _exit_tree() -> void:
	if Global.display.is_connected("screen_stretch_changed", self, "snap"):
		Global.display.disconnect("screen_stretch_changed", self, "snap")
	
	Global.events.safe_disconnect("camera_unfocus_request", self, "unfocus")


# Sets the level camera's limits to boundary positions:
func set_limits(top_left: Vector2, bottom_right: Vector2) -> void:
	limit_left = int(top_left.x)
	limit_top = int(top_left.y)
	limit_right = int(bottom_right.x)
	limit_bottom = int(bottom_right.y)
	snap()


# Snaps the level camera to its target position:
func snap() -> void:
	force_update_scroll()
	reset_smoothing()


# Focuses the level camera on a fixed world position:
func focus(world_pos: Vector2) -> void:
	_is_focusing = true
	set_process(false)
	position = world_pos


# Stops focusing the level camera:
func unfocus() -> void:
	_is_focusing = false
	
	if _anchor:
		position = _anchor.global_position
		set_process(true)


# Starts following an anchor node:
func follow_anchor(anchor_ref: Node2D) -> void:
	if _anchor == anchor_ref:
		return
	elif not anchor_ref:
		unfollow_anchor()
		return
	
	_anchor = anchor_ref
	
	if not _is_focusing:
		position = _anchor.global_position
		set_process(true)


# Stops following the current anchor node:
func unfollow_anchor() -> void:
	if not _anchor:
		return
	
	set_process(false)
	
	if not _is_focusing:
		position = _anchor.global_position
	
	_anchor = null


# Pushes an anchor node to follow:
func push_follow(anchor_ref: Node2D) -> void:
	_anchor_stack.push_back(_anchor)
	follow_anchor(anchor_ref)


# Pops the followed anchor node:
func pop_follow() -> void:
	follow_anchor(_anchor_stack.pop_back())
