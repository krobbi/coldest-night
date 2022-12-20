extends Reference

# Span
# A span is a structure used by the NightScript compiler that represents a span
# between two positions in NightScript source code.

var name: String
var start_offset: int
var start_line: int
var start_column: int
var end_offset: int
var end_line: int
var end_column: int

# Reset the span to the beginning of the NightScript source code.
func _init() -> void:
	reset("")


# Return the span's string representation.
func _to_string() -> String:
	var result: String = "%d:%d - %d:%d" % [start_line, start_column, end_line, end_column]
	
	if end_offset - start_offset <= 1:
		result = "%d:%d" % [start_line, start_column]
	elif start_line == end_line:
		result = "%d:%d-%d" % [start_line, start_column, end_column]
	
	if not name.empty():
		return "%s %s" % [name, result]
	
	return result


# Reset the span to the beginning of the NightScript source code with a module
# name.
func reset(name_val: String) -> void:
	name = name_val
	start_offset = 0
	start_line = 1
	start_column = 1
	shrink_to_start()


# Expand the span's end position by one character.
func expand_by_character(character: String, tab_size: int) -> void:
	end_offset += 1
	
	match character:
		"\t":
			end_column += tab_size - (end_column - 1) % tab_size
		"\n":
			end_column = 1
			end_line += 1
		_:
			end_column += 1


# Expand the span to include another span.
func expand_to_span(other) -> void:
	if other.start_offset < start_offset:
		start_offset = other.start_offset
		start_line = other.start_line
		start_column = other.start_column
	
	if other.end_offset > end_offset:
		end_offset = other.end_offset
		end_line = other.end_line
		end_column = other.end_column


# Shrink the span to an empty span at its start position.
func shrink_to_start() -> void:
	end_offset = start_offset
	end_line = start_line
	end_column = start_column


# Shrink the span to an empty span at its end position.
func shrink_to_end() -> void:
	start_offset = end_offset
	start_line = end_line
	start_column = end_column


# Copy another span by value.
func copy(other: Reference) -> void:
	name = other.name
	start_offset = other.start_offset
	start_line = other.start_line
	start_column = other.start_column
	end_offset = other.end_offset
	end_line = other.end_line
	end_column = other.end_column


# Create a new copy of the span by value.
func duplicate() -> Reference:
	var copy: Reference = get_script().new()
	copy.copy(self)
	return copy
