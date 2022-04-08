class_name CreditsParser
extends Object

# Credits Parser
# A credits parser is a utility that parses the contents of credits files to
# credits bbcode.

enum State {NORMAL, SMALL}

const HEADING_BBCODE: String = "[center][color=#ff980e]%s[/color][/center]\n"
const SUBHEADING_BBCODE: String = "[color=#ff980e]%s[/color]\n"
const PLAIN_BBCODE: String = "%s\n"
const BEGIN_SMALL_BBCODE: String = "[color=#a9b0b0][code]"
const SMALL_BBCODE: String = "%s\n"
const END_SMALL_BBCODE: String = "[/code][/color]"
const BEGIN_NAMES_BBCODE: String = "[table=2]"
const NAMES_BBCODE: String = "[cell]%s[/cell]"
const END_NAMES_BBCODE: String = "[/table]\n"

var _state: int = State.NORMAL
var _authors: Dictionary = Engine.get_author_info()

# Parses the contents of a credits file to credits bbcode:
func parse_source(source: String) -> String:
	_state = State.NORMAL
	var output: String = ""
	
	for line in source.split("\n"):
		output += _parse_line(line)
	
	return output


# Parses a line of a credits file:
func _parse_line(line: String) -> String:
	line = line.strip_edges()
	
	match _state:
		State.SMALL:
			return _parse_line_small(line)
		State.NORMAL, _:
			return _parse_line_normal(line)


# Parses a line of a credits file in the normal state:
func _parse_line_normal(line: String) -> String:
	if line == "Godot Engine Founders":
		return _parse_names(PoolStringArray(_authors.founders))
	elif line == "Godot Engine Lead Developers":
		return _parse_names(PoolStringArray(_authors.lead_developers))
	elif line == "Godot Engine Project Managers":
		return _parse_names(PoolStringArray(_authors.project_managers))
	elif line == "Godot Engine Developers":
		return _parse_names(PoolStringArray(_authors.developers))
	elif line == "```":
		_state = State.SMALL
		return BEGIN_SMALL_BBCODE
	elif line.begins_with("##"):
		return SUBHEADING_BBCODE % line.substr(2).strip_edges(true, false)
	elif line.begins_with("#"):
		return HEADING_BBCODE % line.substr(1).strip_edges(true, false)
	else:
		return PLAIN_BBCODE % line


# Parses a line of a credits file in the small state:
func _parse_line_small(line: String) -> String:
	if line == "```":
		_state = State.NORMAL
		return END_SMALL_BBCODE
	else:
		return SMALL_BBCODE % line


# Parses a list of names to bbcode:
func _parse_names(names: PoolStringArray) -> String:
	var output: String = BEGIN_NAMES_BBCODE if names.size() >= 10 else ""
	
	for name in names:
		output += (NAMES_BBCODE if names.size() >= 10 else PLAIN_BBCODE) % name
	
	output += END_NAMES_BBCODE if names.size() >= 10 else ""
	return output
