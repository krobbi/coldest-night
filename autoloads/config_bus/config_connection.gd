class_name ConfigConnection
extends Reference

# Configuration Connection
# A configuration connection is a structure used by the configuration bus that
# represents a connection from the configuration bus to a target method.

var _config_key: String
var _target: Object
var _method: String
var _cast_type: int
var _binds: Array
var _is_severed: bool = false

# Set the configuraton connection's configuration key, target, method, cast type
# and binds.
func _init(
		config_key_val: String, target_ref: Object, method_val: String,
		cast_type_val: int, binds_ref: Array) -> void:
	_config_key = config_key_val
	_target = target_ref
	_method = method_val
	_cast_type = cast_type_val
	_binds = binds_ref


# Get the configuration connection's configuration key.
func get_config_key() -> String:
	return _config_key


# Get the configuration connection's target.
func get_target() -> Object:
	return _target


# Get whether the connection is severed.
func is_severed() -> bool:
	return _is_severed


# Return whether the configuration connection has a signature configuration key,
# target, and method.
func has_signature(config_key_val: String, target_ref: Object, method_val: String) -> bool:
	return _config_key == config_key_val and _target == target_ref and _method == method_val


# Emit a configuration event from the configuration connection with a value.
func emit(value) -> void:
	if _is_severed or not _target or not _target.has_method(_method):
		sever()
		return
	
	var args: Array = _binds.duplicate()
	args.insert(0, cast(value, _cast_type))
	_target.callv(_method, args)


# Sever the configuration connection.
func sever() -> void:
	_is_severed = true


# Cast a variable-type value to a type.
static func cast(value, type: int):
	match type:
		TYPE_BOOL:
			return cast_bool(value)
		TYPE_INT:
			return cast_int(value)
		TYPE_REAL:
			return cast_float(value)
		TYPE_STRING:
			return cast_string(value)
		_:
			return value


# Cast a variable-type value to a bool.
static func cast_bool(value) -> bool:
	return true if value else false


# Cast a variable-type value to an int.
static func cast_int(value) -> int:
	match typeof(value):
		TYPE_BOOL, TYPE_REAL, TYPE_STRING:
			return int(value)
		TYPE_INT:
			return value
		_:
			return 0


# Cast a variable-type value to a float.
static func cast_float(value) -> float:
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return float(value)
		TYPE_REAL:
			return value
		_:
			return 0.0


# Cast a variable-type value to a string.
static func cast_string(value) -> String:
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_REAL:
			return String(value)
		TYPE_STRING:
			return value
		_:
			return ""
