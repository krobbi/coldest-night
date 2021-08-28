class_name OverworldCamera
extends Camera2D

# Overworld Camera
# The overworld camera is a component of the overworld scene that is an
# extension of a 2D camera. It is capable of following the position of remote
# 'anchor' nodes and being focused on fixed positions.

const CENTER_OFFSET: Vector2 = Vector2(320.0, 180.0);

var _focusing: bool = false;
var _anchor: Node2D = null;

# Virtual _ready method. Runs when the overworld camera enters the scene tree.
# Disables the overworld camera's physics process to prevent errors from
# following a null 'anchor' node's position and registers the overworld camera
# to the global provider manager:
func _ready() -> void:
	set_physics_process(false);
	
	Global.provider.set_camera(self);


# Virtual _physics_process method. Runs on every physics frame while the
# overworld camera is in the scene tree and has its physics process enabled:
func _physics_process(_delta: float) -> void:
	set_position(_anchor.get_position());


# Virtual _exit_tree method. Runs when the overworld camera exits the scene
# tree. Unregisters the overworld camera from the global provider manager:
func _exit_tree() -> void:
	Global.provider.set_camera(null);


# Gets a screen position as displayed on the overworld camera from a world
# position:
func get_screen_pos(world_pos: Vector2) -> Vector2:
	return world_pos + CENTER_OFFSET - get_camera_screen_center();


# Focuses the camera on a fixed world position:
func focus(world_pos: Vector2) -> void:
	_focusing = true;
	set_physics_process(false);
	set_position(world_pos);


# Stops focusing the camera if it is focusing:
func unfocus() -> void:
	_focusing = false;
	
	if _anchor != null:
		set_position(_anchor.get_position());
		set_physics_process(true);


# Starts following the position of an 'anchor' node:
func follow_anchor(anchor_ref: Node2D) -> void:
	_anchor = anchor_ref;
	
	if not _focusing:
		set_position(_anchor.get_position());
		set_physics_process(true);


# Stops following the position of any currently followed 'anchor' node:
func unfollow_anchor() -> void:
	set_physics_process(false);
	_anchor = null;
