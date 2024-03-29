class_name DialogTagParser
extends Node

# Dialog Tag Parser
# A dialog tag parser is a component of a dialog display that handles parsing
# and stripping dialog tags from dialog messages and emitting signals for dialog
# behaviors at requested positions in the parsed dialog message.

class FloatDialogTag extends RefCounted:
	
	# Float Dialog Tag
	# A float dialog tag is a helper structure used by a dialog tag parser that
	# represents the position and value of a float dialog tag.
	
	var position: int
	var value: float
	
	# Set the float dialog tag's position and value.
	func _init(position_val: int, value_val: float) -> void:
		position = position_val
		value = value_val


signal pause_requested(duration: float)
signal speed_requested(speed: float)

var _pause_tags: Array[FloatDialogTag] = []
var _speed_tags: Array[FloatDialogTag] = []
var _bbcode_regex: RegEx = _create_regex("\\[[^[\\]]*?\\]")
var _tag_regex: RegEx = _create_regex("{[^{}]*?}")
var _pause_regex: RegEx = _create_regex("{p=\\d+(\\.\\d+)?}")
var _speed_regex: RegEx = _create_regex("{s=\\d+(\\.\\d+)?}")
var _decimal_regex: RegEx = _create_regex("\\d+(\\.\\d+)?")

# Parse and strip dialog tags from a dialog message.
func parse(message: String) -> String:
	_pause_tags = _parse_float_tags(message, _pause_regex, 1)
	_speed_tags = _parse_float_tags(message, _speed_regex, 1)
	return _tag_regex.sub(message, "", true)


# Request signals for dialog behaviors at a position in the parsed dialog
# message.
func request(position: int) -> void:
	for pause_tag in _pause_tags:
		if pause_tag.position == position:
			pause_requested.emit(pause_tag.value)
			break
	
	for speed_tag in _speed_tags:
		if speed_tag.position == position:
			speed_requested.emit(speed_tag.value)
			return


# Get a position in a parsed dialog message from a position in an unparsed
# dialog message.
func _get_parsed_position(message: String, position: int) -> int:
	var left: String = message.left(position)
	
	for result in _bbcode_regex.search_all(left):
		position -= result.get_string().length()
	
	for result in _tag_regex.search_all(left):
		position -= result.get_string().length()
	
	return position


# Create a new compiled RegEx from a regular expression pattern.
func _create_regex(pattern: String) -> RegEx:
	var regex: RegEx = RegEx.new()
	regex.compile(pattern)
	return regex


# Parse an array of float tags from a dialog message.
func _parse_float_tags(message: String, tag_regex: RegEx, offset: int) -> Array[FloatDialogTag]:
	var float_tags: Array[FloatDialogTag] = []
	
	for result in tag_regex.search_all(message):
		var tag_position: int = _get_parsed_position(message, result.get_start()) - offset
		var tag_value: float = float(_decimal_regex.search(result.get_string()).get_string())
		float_tags.push_back(FloatDialogTag.new(maxi(tag_position, 0), tag_value))
	
	return float_tags
