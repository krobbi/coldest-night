class_name OverworldCamera
extends Camera2D

# Overworld Camera
# The overworld camera is an extension of a 2D camera used in the overworld that
# is capable of following camera anchors and having its limits set according to
# a level.

var anchor: RemoteTransform2D = null;

# Starts following a camera anchor:
func follow_anchor(anchor_ref: RemoteTransform2D) -> void:
	if anchor == anchor_ref:
		return;
	
	unfollow_anchor();
	anchor = anchor_ref;
	anchor.remote_path = get_path();


# Starts following the player's camera anchor:
func follow_player(player: Player) -> void:
	follow_anchor(player.camera_anchor);


# Stops following the current camera anchor:
func unfollow_anchor() -> void:
	if not anchor:
		return;
	
	anchor.remote_path = NodePath();
	anchor = null;


# Applies the limits of a level to the overworld camera's limits:
func apply_level_limits(level: Level) -> void:
	var top_left: Vector2 = level.top_left.position;
	var bottom_right: Vector2 = level.bottom_right.position;
	level.top_left.queue_free();
	level.bottom_right.queue_free();
	limit_left = int(top_left.x);
	limit_top = int(top_left.y);
	limit_right = int(bottom_right.x);
	limit_bottom = int(bottom_right.y);
