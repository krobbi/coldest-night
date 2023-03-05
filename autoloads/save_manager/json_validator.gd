class_name JSONValidator
extends Reference

# JSON Validator
# A JSON validator is a wrapper class for parsing and validating JSON data.

var _is_valid: bool = true
var _data_stack: Array

# Clear the JSON validator.
func _init() -> void:
	clear()


# Get the JSON validator's root data.
func get_root_data() -> Dictionary:
	return _data_stack[0]


# Get the JSON validator's leaf data.
func get_leaf_data():
	return _data_stack[-1]


# Get the JSON validator's leaf data's keys.
func get_keys() -> Array:
	var leaf = get_leaf_data()
	
	if typeof(leaf) == TYPE_DICTIONARY:
		return leaf.keys()
	elif typeof(leaf) == TYPE_ARRAY:
		return range(leaf.size())
	else:
		return []


# Get a property from the JSON validator from its key. Return `default` if the
# property does not exist.
func get_property(key, default = null):
	if has_property(key):
		return get_leaf_data()[key]
	else:
		return default


# Get whether the JSON validator is valid.
func is_valid() -> bool:
	return _is_valid


# Return whether the JSON validator's leaf data has a property from its key.
func has_property(key) -> bool:
	var leaf = get_leaf_data()
	
	if typeof(leaf) == TYPE_DICTIONARY and typeof(key) == TYPE_STRING:
		return leaf.has(key)
	elif typeof(leaf) == TYPE_ARRAY and typeof(key) == TYPE_INT:
		return key >= 0 and key < leaf.size()
	else:
		return false


# Return whether the JSON validator's leaf data has an enum property.
func has_enum(key, values: Array) -> bool:
	if has_property(key):
		return get_property(key) in values
	else:
		return false


# Return whether the JSON validator's leaf data has an int property. Integer
# float values are accepted as JSON has an ambiguous number format. `INF` and
# `NAN` are not accepted.
func has_int(key) -> bool:
	if not has_property(key):
		return false
	
	var value = get_property(key)
	
	if typeof(value) == TYPE_INT:
		return true
	elif typeof(value) == TYPE_REAL:
		return not is_inf(value) and not is_nan(value) and floor(value) == value
	else:
		return false


# Return whether the JSON validator's leaf data has a float property. Int values
# are accepted as JSON has an ambiguous number format. `INF` and `NAN` are not
# accepted.
func has_float(key) -> bool:
	if not has_property(key):
		return false
	
	var value = get_property(key)
	
	if typeof(value) == TYPE_INT:
		return true
	elif typeof(value) == TYPE_REAL:
		return not is_inf(value) and not is_nan(value)
	else:
		return false


# Return whether the JSON validator's leaf data has a string property.
func has_string(key) -> bool:
	if has_property(key):
		return typeof(get_property(key)) == TYPE_STRING
	else:
		return false


# Return whether the JSON validator's leaf data has a dictionary property.
func has_dictionary(key) -> bool:
	if has_property(key):
		return typeof(get_property(key)) == TYPE_DICTIONARY
	else:
		return false


# Return whether the JSON validator's leaf data has an array property.
func has_array(key) -> bool:
	if has_property(key):
		return typeof(get_property(key)) == TYPE_ARRAY
	else:
		return false


# Clear the JSON validator.
func clear() -> void:
	_is_valid = true
	_data_stack = [{}]


# Invalidate the JSON validator.
func invalidate() -> void:
	_is_valid = false


# Initialize the JSON validator from a JSON file's path.
func from_path(path: String) -> void:
	clear()
	var file: File = File.new()
	
	if file.open(path, File.READ) != OK:
		if file.is_open():
			file.close()
		
		invalidate()
		return
	
	var json: String = file.get_as_text()
	file.close()
	from_json(json)


# Initialize the JSON vaidator from a JSON string.
func from_json(json: String) -> void:
	clear()
	
	if not validate_json(json).empty():
		invalidate()
		return
	
	var parse_result: JSONParseResult = JSON.parse(json)
	
	if parse_result.error == OK and typeof(parse_result.result) == TYPE_DICTIONARY:
		from_data(parse_result.result)
	else:
		invalidate()


# Initialize the JSON validator from a data dictionary.
func from_data(data: Dictionary) -> void:
	clear()
	_data_stack[0] = data


# Invalidate the JSON validator if its leaf data does not have a property.
func check_property(key) -> void:
	if not has_property(key):
		invalidate()


# Invalidate the JSON validator if its leaf data does not have an enum property.
func check_enum(key, values: Array) -> void:
	if not has_enum(key, values):
		invalidate()


# Invalidate the JSON validator if its leaf data does not have an int property.
func check_int(key) -> void:
	if not has_int(key):
		invalidate()


# Invalidate the JSON validator if its leaf data does not have a float property.
func check_float(key) -> void:
	if not has_float(key):
		invalidate()


# Invalidate the JSON validator if its leaf data does not have a string
# property.
func check_string(key) -> void:
	if not has_string(key):
		invalidate()


# Invalidate the JSON validator if its leaf data does not have a dictionary
# property.
func check_dictionary(key) -> void:
	if not has_dictionary(key):
		invalidate()


# Invalidae the JSON validator if its leaf data does not have an array property.
func check_array(key) -> void:
	if not has_array(key):
		invalidate()


# Enter a dictionary property of the JSON validator's leaf data as the new leaf
# data.
func enter_dictionary(key) -> void:
	if has_dictionary(key):
		_data_stack.push_back(get_property(key))
	else:
		invalidate()
		_data_stack.push_back({})


# Enter an array property of the JSON validator's leaf data as the new leaf
# data.
func enter_array(key) -> void:
	if has_array(key):
		_data_stack.push_back(get_property(key))
	else:
		invalidate()
		_data_stack.push_back([])


# Exit the JSON validator's leaf data.
func exit() -> void:
	if _data_stack.size() > 1:
		_data_stack.remove(_data_stack.size() - 1)
	else:
		invalidate()
