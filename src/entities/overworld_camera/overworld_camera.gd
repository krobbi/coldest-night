class_name OverworldCamera
extends Camera2D

const CENTER_OFFSET: Vector2 = Vector2(320.0, 180.0);

# Overworld Camera
# The overworld camera is an extension of a 2D camera that is capable of
# following the position of a remote anchor node:

var anchor: Node2D = null;

var _focusing: bool = false;

# Virtual _ready method. Runs when the overworld camera enters the scene tree.
# Disables the overworld camera's physics process as it is not following an
# anchor:
func _ready() -> void:
	set_physics_process(false);


# Virtual _physics_process method. Runs on every physics frame while the
# overworld camera is in the scene tree and has its physics process enabled.
# Sets the camera's position to the anchor's position:
func _physics_process(_delta: float) -> void:
	set_position(anchor.get_position());


# Gets a world position as its screen position when displayed on the overworld
# camera:
func get_screen_pos(world_pos: Vector2) -> Vector2:
	return world_pos + CENTER_OFFSET - get_camera_screen_center();


# Ignores the current anchor and focuses the camera on a fixed world position:
func focus(world_pos: Vector2) -> void:
	_focusing = true;
	set_physics_process(false);
	set_position(world_pos);


# Stops focusing the camera:
func unfocus() -> void:
	_focusing = false;
	
	if anchor:
		set_position(anchor.get_position());
		set_physics_process(true);


# Starts following an anchor:
func follow_anchor(anchor_ref: Node2D) -> void:
	anchor = anchor_ref;
	
	if not _focusing:
		set_position(anchor.get_position());
		set_physics_process(true);


# Stops following the current anchor:
func unfollow_anchor() -> void:
	set_physics_process(false);
	anchor = null;
