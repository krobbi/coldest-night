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
	
	if parse_result.error != OK or not parse_result.result or not parse_result.result is Dictionary:
		invalidate()
		return
	
	_data = parse_result.result


# Get the JSON reader's raw data.
func get_data() -> Dictionary:
	return _data


# Get whether the JSON reader is valid.
func is_valid() -> bool:
	return _is_valid


# Invalidate the JSON reader.
func invalidate() -> void:
	_is_valid = false
