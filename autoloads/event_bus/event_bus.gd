extends Node

# Event Bus
# The event bus is an autoload scene that loosely couples gameplay systems by
# providing globally accessible signals. The event bus can be accessed from any
# script by using `EventBus`.

signal save_state_request()
signal pause_game_request()
signal game_over_request()
signal transition_level_request(level_path, point, relative_point, is_relative_x, is_relative_y)

signal player_freeze_request()
signal player_unfreeze_request()
signal player_transition_request()

signal nightscript_run_script_request(script_key)
signal nightscript_stop_script_request()
signal nightscript_cache_script_request(script_key)
signal nightscript_flush_cache_request()

signal floating_text_display_request(text, world_pos)
signal subtitle_display_request(message)
signal tooltip_display_request(message)

signal camera_set_limits_request(top_left, bottom_right)
signal camera_follow_anchor_request(anchor)
signal camera_unfollow_anchor_request()

signal dialog_show_request()
signal dialog_hide_request()
signal dialog_clear_name_request()
signal dialog_display_name_request(name)
signal dialog_display_message_request(message)
signal dialog_display_options_request(texts)
signal dialog_message_finished()
signal dialog_option_pressed(index)

signal radar_clear_request()
signal radar_render_level_request()
signal radar_render_point_request(radar_point)
signal radar_referesh_entities_request()
signal radar_camera_follow_anchor_request(anchor)
signal radar_camera_unfollow_anchor_request()

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


# Emit a save state request event.
func emit_save_state_request() -> void:
	emit_signal("save_state_request")


# Emit a pause game request event.
func emit_pause_game_request() -> void:
	emit_signal("pause_game_request")


# Emit a game over request event.
func emit_game_over_request() -> void:
	emit_signal("game_over_request")


# Emit a transition level request event.
func emit_transition_level_request(
		level_path: String, point: String, relative_point: String,
		is_relative_x: bool, is_relative_y: bool) -> void:
	emit_signal(
			"transition_level_request", level_path, point, relative_point,
			is_relative_x, is_relative_y)


# Emit a player freeze request event.
func emit_player_freeze_request() -> void:
	emit_signal("player_freeze_request")


# Emit a player unfreeze request event.
func emit_player_unfreeze_request() -> void:
	emit_signal("player_unfreeze_request")


# Emit a player transition request event.
func emit_player_transition_request() -> void:
	emit_signal("player_transition_request")


# Emit a NightScript run script request event.
func emit_nightscript_run_script_request(script_key: String) -> void:
	emit_signal("nightscript_run_script_request", script_key)


# Emit a NightScript stop script request event.
func emit_nightscript_stop_script_request() -> void:
	emit_signal("nightscript_stop_script_request")


# Emit a NightScript cache script request event.
func emit_nightscript_cache_script_request(script_key: String) -> void:
	emit_signal("nightscript_cache_script_request", script_key)


# Emit a NightScript flush cache request event.
func emit_nightscript_flush_cache_request() -> void:
	emit_signal("nightscript_flush_cache_request")


# Emit a floating text display request event.
func emit_floating_text_display_request(text: String, world_pos: Vector2) -> void:
	emit_signal("floating_text_display_request", text, world_pos)


# Emit a subtitle display request event.
func emit_subtitle_display_request(message: String) -> void:
	emit_signal("subtitle_display_request", message)


# Emit a tooltip display request event.
func emit_tooltip_display_request(message: String) -> void:
	emit_signal("tooltip_display_request", message)


# Emit a camera set limits request event.
func emit_camera_set_limits_request(top_left: Vector2, bottom_right: Vector2) -> void:
	emit_signal("camera_set_limits_request", top_left, bottom_right)


# Emit a camera follow anchor request event.
func emit_camera_follow_anchor_request(anchor: Node2D) -> void:
	emit_signal("camera_follow_anchor_request", anchor)


# Emit a camera unfollow anchor request event.
func emit_camera_unfollow_anchor_request() -> void:
	emit_signal("camera_unfollow_anchor_request")


# Emit a dialog show request event.
func emit_dialog_show_request() -> void:
	emit_signal("dialog_show_request")


# Emit a dialog hide request event.
func emit_dialog_hide_request() -> void:
	emit_signal("dialog_hide_request")


# Emit a dialog clear name request event.
func emit_dialog_clear_name_request() -> void:
	emit_signal("dialog_clear_name_request")


# Emit a dialog display name request event.
func emit_dialog_display_name_request(name: String) -> void:
	emit_signal("dialog_display_name_request", name)


# Emit a dialog display message request event.
func emit_dialog_display_message_request(message: String) -> void:
	emit_signal("dialog_display_message_request", message)


# Emit a dialog display options request event.
func emit_dialog_display_options_request(texts: PoolStringArray) -> void:
	emit_signal("dialog_display_options_request", texts)


# Emit a dialog message finished event.
func emit_dialog_message_finished() -> void:
	emit_signal("dialog_message_finished")


# Emit a dialog option pressed event.
func emit_dialog_option_pressed(index: int) -> void:
	emit_signal("dialog_option_pressed", index)


# Emit a radar clear request event.
func emit_radar_clear_request() -> void:
	emit_signal("radar_clear_request")


# Emit a radar render level request event.
func emit_radar_render_level_request() -> void:
	emit_signal("radar_render_level_request")


# Emit a radar render point request event.
func emit_radar_render_point_request(radar_point: RadarPoint) -> void:
	emit_signal("radar_render_point_request", radar_point)


# Emit a radar refresh entities request event.
func emit_radar_refresh_entities_request() -> void:
	emit_signal("radar_referesh_entities_request")


# Emit a radar camera follow anchor request event.
func emit_radar_camera_follow_anchor_request(anchor: Node2D) -> void:
	emit_signal("radar_camera_follow_anchor_request", anchor)


# Emit a radar camera unfollow anchor request event.
func emit_radar_camera_unfollow_anchor_request() -> void:
	emit_signal("radar_camera_unfollow_anchor_request")


# Unsubscribe a node from all of its subscribed events.
func _unsubscribe_node(target: Node) -> void:
	for connection in target.get_incoming_connections():
		if connection.source != self:
			continue
		
		unsubscribe(connection.signal_name, target, connection.method_name)
