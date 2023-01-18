class_name JSONReader
extends Reference

# JSON Reader
# A JSON reader is a wrapper class for parsing, validating, and reading JSON
# data.

var _is_valid: bool = true
var _data: Dictionary = {}

# Parse the JSON reader's data from JSON source text.
func _init(source: String) -> void:
	if not validate_json(source).empty():
		invalidate()
		return
	
	var parse_result: JSONParseResult = JSON.parse(source)
	
	if parse_result.error != OK or typeof(parse_result.result) != TYPE_DICTIONARY:
		invalidate()
		return
	
	_data = parse_result.result


# Get the JSON reader's raw data.
func get_data() -> Dictionary:
	return _data


# Get a property from the JSON reader.
func get_property(property: String, default = null):
	return _data.get(property, default)


# Get whether the JSON reader is valid.
func is_valid() -> bool:
	return _is_valid


# Get whether the JSON reader has a property.
func has_property(property: String) -> bool:
	return _data.has(property)


# Get whether the JSON reader has an enum property.
func has_enum(property: String, values: Array) -> bool:
	if not has_property(property):
		return false
	
	return get_property(property) in values


# Get whether the JSON reader has a float property. Int types are also accepted
# as JSON has an ambiguous number format. Infinity and not a number are not
# accepted.
func has_float(property: String) -> bool:
	if not has_property(property):
		return false
	
	var value = get_property(property)
	
	if typeof(value) == TYPE_INT:
		return true
	elif typeof(value) == TYPE_REAL:
		return not is_inf(value) and not is_nan(value)
	
	return false


# Get whether the JSON reader has a string property.
func has_string(property: String) -> bool:
	if not has_property(property):
		return false
	
	return typeof(get_property(property)) == TYPE_STRING


# Get whether the JSON reader has a dictionary property.
func has_dictionary(property: String) -> bool:
	if not has_property(property):
		return false
	
	return typeof(get_property(property)) == TYPE_DICTIONARY


# Invalidate the JSON reader if it does not have a property.
func check_property(property: String) -> void:
	if not has_property(property):
		invalidate()


# Invalidate the JSON reader if it does not have an enum property.
func check_enum(property: String, values: Array) -> void:
	if not has_enum(property, values):
		invalidate()


# Invalidate the JSON reader if it does not have a float property.
func check_float(property: String) -> void:
	if not has_float(property):
		invalidate()


# Invalidate the JSON reader if it does not have a string property.
func check_string(property: String) -> void:
	if not has_string(property):
		invalidate()


# Invalidate the JSON reader if it does not have a dictionary property.
func check_dictionary(property: String) -> void:
	if not has_dictionary(property):
		invalidate()


# Invalidate the JSON reader.
func invalidate() -> void:
	_is_valid = false
