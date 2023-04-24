extends Node

# Event Bus
# The event bus is an autoload scene that loosely couples gameplay systems by
# providing globally accessible signals. The event bus can be accessed from any
# script by using `EventBus`.

signal save_state_request
signal pause_game_request
signal game_over_request
signal transition_level_request(
		level_path: String, point: String, relative_point: String,
		is_relative_x: bool, is_relative_y: bool)
signal navigability_changed(rect: Rect2, is_navigable: bool)

signal player_push_freeze_state_request
signal player_push_transition_state_request
signal player_pop_state_request

signal floating_text_display_request(text: String, world_pos: Vector2)
signal subtitle_display_request(message: String)
signal tooltip_display_request(message: String)

signal camera_set_limits_request(top_left: Vector2, bottom_right: Vector2)
signal camera_follow_anchor_request(anchor: Node2D)
signal camera_unfollow_anchor_request

signal dialog_show_request
signal dialog_hide_request
signal dialog_clear_name_request
signal dialog_display_name_request(name: String)
signal dialog_display_message_request(message: String)
signal dialog_display_options_request(texts: PackedStringArray)
signal dialog_message_finished
signal dialog_option_pressed(index: int)

signal radar_render_level_request
signal radar_render_point_request(radar_point: RadarPoint)
signal radar_render_vision_area_request(vision_area: VisionArea)
signal radar_render_laser_wall_request(laser_wall: LaserWall)
signal radar_camera_follow_anchor_request(anchor: Node2D)
signal radar_camera_unfollow_anchor_request

# Subscribe a callable to an event signal.
func subscribe(event: Signal, callable: Callable, flags: int = 0) -> void:
	unsubscribe(event, callable)
	
	if event.connect(callable, flags) != OK:
		unsubscribe(event, callable)


# Subscribe a callable with a node target to an event signal and automatically
# unsubscribe the target node when it exits the scene tree.
func subscribe_node(event: Signal, callable: Callable, flags: int = 0) -> void:
	subscribe(event, callable, flags)
	
	var node: Node = callable.get_object() as Node
	
	if not is_instance_valid(node):
		return
	
	if not node.tree_exiting.is_connected(_unsubscribe_node):
		if node.tree_exiting.connect(_unsubscribe_node.bind(node), CONNECT_ONE_SHOT) != OK:
			if node.tree_exiting.is_connected(_unsubscribe_node):
				node.tree_exiting.disconnect(_unsubscribe_node)


# Unsubscribe a callable from an event signal.
func unsubscribe(event: Signal, callable: Callable) -> void:
	if event.is_connected(callable):
		event.disconnect(callable)


# Unsubscribe a node from all of its subscribed event signals.
func _unsubscribe_node(node: Node) -> void:
	for connection in node.get_incoming_connections():
		var event: Signal = connection["signal"]
		
		if event.get_object_id() != get_instance_id():
			continue
		
		event.disconnect(connection.callable)
