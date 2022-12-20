extends Reference

# Log Record
# A log record is a structure used by the NightScript compiler that represents a
# logged error with a message and span.

const Span: GDScript = preload("span.gd")

var message: String
var span: Span

# Set the log record's message and span.
func _init(message_val: String, span_ref: Span) -> void:
	message = message_val
	span = span_ref


# Return the log record's string representation.
func _to_string() -> String:
	return "%s: %s" % [span, message]


# Get whether the log record should be logged after another log record:
func is_logged_after(other: Reference) -> bool:
	var name_comparison: int = span.name.casecmp_to(other.span.name)
	
	if name_comparison > 0:
		return true
	elif name_comparison < 0:
		return false
	
	if span.start_offset > other.span.start_offset:
		return true
	elif span.start_offset < other.span.start_offset:
		return false
	
	if span.end_offset < other.span.end_offset:
		return true
	elif span.end_offset > other.span.end_offset:
		return false
	
	return true
