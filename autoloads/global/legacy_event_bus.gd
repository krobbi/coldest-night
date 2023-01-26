class_name LegacyEventBus
extends Reference

# Event Bus
# The event bus is a global utility that handles loosely coupling objects by
# providing gameplay-related signals. The event bus can be accessed from any
# script by using 'Global.events'.

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
