class_name ConfigConnection
extends RefCounted

# Configuration Connection
# A configuration connection is a structure used by the configuration bus that
# represents a connection from the configuration bus to a target method.

var _config_key: String
var _callable: Callable
var _cast_type: Variant.Type
var _is_severed: bool = false

# Set the configuraton connection's configuration key, callable, and cast type.
func _init(config_key_val: String, callable_ref: Callable, cast_type_val: Variant.Type) -> void:
	_config_key = config_key_val
	_callable = callable_ref
	_cast_type = cast_type_val


# Get the configuration connection's configuration key.
func get_config_key() -> String:
	return _config_key


# Get the configuration connection's target.
func get_target() -> Object:
	return _callable.get_object()


# Get whether the connection is severed.
func is_severed() -> bool:
	return _is_severed


# Return whether the configuration connection has a signature configuration key
# and callable.
func has_signature(config_key_val: String, callable_ref: Callable) -> bool:
	return (
			_config_key == config_key_val
			and _callable.get_object_id() == callable_ref.get_object_id()
			and _callable.get_method() == callable_ref.get_method())


# Emit a configuration event from the configuration connection with a value.
func emit(value: Variant) -> void:
	if _is_severed or _callable.is_null():
		sever()
		return
	
	_callable.call(_cast(value, _cast_type))


# Sever the configuration connection.
func sever() -> void:
	_is_severed = true


# Cast a variant to a type.
func _cast(value: Variant, type: Variant.Type) -> Variant:
	match type:
		TYPE_BOOL:
			return ConfigConnection.cast_bool(value)
		TYPE_INT:
			return ConfigConnection.cast_int(value)
		TYPE_FLOAT:
			return ConfigConnection.cast_float(value)
		TYPE_STRING:
			return ConfigConnection.cast_string(value)
	
	return value


# Cast a variant to a bool.
static func cast_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT:
			return value != 0
		TYPE_FLOAT:
			if is_finite(value):
				return value > 0.0 or value < -0.0
			else:
				return false
		TYPE_STRING:
			return not value.is_empty()
	
	return true if value else false


# Cast a variant to an int.
static func cast_int(value: Variant) -> int:
	match typeof(value):
		TYPE_BOOL, TYPE_STRING:
			return int(value)
		TYPE_INT:
			return value
		TYPE_FLOAT:
			if is_finite(value):
				return int(value)
			else:
				return 0
	
	return 0


# Cast a variant to a float.
static func cast_float(value: Variant) -> float:
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return float(value)
		TYPE_FLOAT:
			if is_finite(value):
				return value
			else:
				return 0.0
	
	return 0.0


# Cast a variant to a string.
static func cast_string(value: Variant) -> String:
	match typeof(value):
		TYPE_BOOL, TYPE_INT:
			return str(value)
		TYPE_FLOAT:
			if is_finite(value):
				return str(value)
			else:
				return "0.0"
		TYPE_STRING:
			return value
	
	return ""
