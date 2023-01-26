class_name LegacyEventBus
extends Reference

# Event Bus
# The event bus is a global utility that handles loosely coupling objects by
# providing gameplay-related signals. The event bus can be accessed from any
# script by using 'Global.events'.

# warning-ignore: UNUSED_SIGNAL
signal nightscript_cache_program_request(program_key)
signal nightscript_flush_cache_request # warning-ignore: UNUSED_SIGNAL
# warning-ignore: UNUSED_SIGNAL
signal nightscript_run_program_request(program_key)
signal nightscript_stop_programs_request # warning-ignore: UNUSED_SIGNAL
signal nightscript_thread_finished # warning-ignore: UNUSED_SIGNAL
signal pause_menu_open_menu_request # warning-ignore: UNUSED_SIGNAL

# Safely connect a signal from the event bus to a target object's receiver
# method.
func safe_connect(
		signal_name: String, target: Object, method: String, binds: Array = [], flags: int = 0
) -> void:
	if is_connected(signal_name, target, method):
		return
	
	var error: int = connect(signal_name, target, method, binds, flags)
	
	if error and is_connected(signal_name, target, method):
		disconnect(signal_name, target, method)


# Safely disconnect a signal from the event bus to a target object's receiver
# method.
func safe_disconnect(signal_name: String, target: Object, method: String) -> void:
	if is_connected(signal_name, target, method):
		disconnect(signal_name, target, method)
