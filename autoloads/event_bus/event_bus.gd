extends Node

# Event Bus
# The event bus is an autoload scene that loosely couples gameplay systems by
# providing globally accessible signals. The event bus can be accessed from any
# script by using 'EventBus'.

signal camera_set_limits_request(top_left, bottom_right)
signal camera_follow_anchor_request(anchor)
signal camera_unfollow_anchor_request()

# Subscribe a target to an event.
func subscribe(
		event: String, target: Object, method: String, binds: Array = [], flags: int = 0) -> void:
	unsubscribe(event, target, method)
	
	if connect(event, target, method, binds, flags) != OK:
		unsubscribe(event, target, method)


# Subscribe a target node to an event and automatically unsubscribe the target
# node when it exits the scene tree.
func subscribe_node(
		event: String, target: Node, method: String, binds: Array = [], flags: int = 0) -> void:
	subscribe(event, target, method, binds, flags)
	
	if not target.is_connected("tree_exiting", self, "_unsubscribe_node"):
		if target.connect(
				"tree_exiting", self, "_unsubscribe_node", [target], CONNECT_ONESHOT) != OK:
			if target.is_connected("tree_exiting", self, "_unsubscribe_node"):
				target.disconnect("tree_exiting", self, "_unsubscribe_node")


# Unsubscribe a target from an event.
func unsubscribe(event: String, target: Object, method: String) -> void:
	if is_connected(event, target, method):
		disconnect(event, target, method)


# Emit a camera set limits request event.
func emit_camera_set_limits_request(top_left: Vector2, bottom_right: Vector2) -> void:
	emit_signal("camera_set_limits_request", top_left, bottom_right)


# Emit a camera follow anchor request event.
func emit_camera_follow_anchor_request(anchor: Node2D) -> void:
	emit_signal("camera_follow_anchor_request", anchor)


# Emit a camera unfollow anchor request event.
func emit_camera_unfollow_anchor_request() -> void:
	emit_signal("camera_unfollow_anchor_request")


# Unsubscribe a node from all of its subscribed events.
func _unsubscribe_node(target: Node) -> void:
	for connection in target.get_incoming_connections():
		if connection.source != self:
			continue
		
		unsubscribe(connection.signal_name, target, connection.method_name)
