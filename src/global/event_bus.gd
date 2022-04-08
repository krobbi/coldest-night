class_name EventBus
extends Object

# Event Bus
# The event bus is a global utility that handles loosely coupling objects by
# providing gameplay-related signals. The event bus can be accessed from any
# script by using 'Global.event'.

signal accumulate_alert_count_request # warning-ignore: UNUSED_SIGNAL
signal accumulate_time_request(delta) # warning-ignore: UNUSED_SIGNAL
signal camera_unfocus_request # warning-ignore: UNUSED_SIGNAL
signal fade_in_request # warning-ignore: UNUSED_SIGNAL
signal fade_out_request # warning-ignore: UNUSED_SIGNAL
signal faded_in # warning-ignore: UNUSED_SIGNAL
signal faded_out # warning-ignore: UNUSED_SIGNAL
signal flag_changed(namespace, key, value) # warning-ignore: UNUSED_SIGNAL
# warning-ignore: UNUSED_SIGNAL
signal floating_text_display_request(text, world_pos)
signal game_over_request # warning-ignore: UNUSED_SIGNAL
signal player_freeze_request # warning-ignore: UNUSED_SIGNAL
signal player_thaw_request # warning-ignore: UNUSED_SIGNAL
signal run_ns_request(program_key) # warning-ignore: UNUSED_SIGNAL
signal save_state_request # warning-ignore: UNUSED_SIGNAL

# Safely connects a signal from the event bus to a target object's receiver
# method:
func safe_connect(signal_name: String, target: Object, method: String) -> void:
	if is_connected(signal_name, target, method):
		return
	
	var error: int = connect(signal_name, target, method)
	
	if error and is_connected(signal_name, target, method):
		disconnect(signal_name, target, method)


# Safely disconnects a signal from the event bus to a target object's receiver
# method:
func safe_disconnect(signal_name: String, target: Object, method: String) -> void:
	if is_connected(signal_name, target, method):
		disconnect(signal_name, target, method)
