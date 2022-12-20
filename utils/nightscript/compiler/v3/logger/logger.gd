extends Reference

# Logger
# A logger is a structure used by the NightScript compiler that manages logging
# and sorting log records.

const LogRecord: GDScript = preload("log_record.gd")
const Span: GDScript = preload("span.gd")

var records: Array = []

# Get the logger's records.
func get_records() -> Array:
	return records


# Return whether the logger has records.
func has_records() -> bool:
	return not records.empty()


# Clear the logger's records.
func clear_records() -> void:
	records.clear()


# Log an error from its message and span.
func log_error(message: String, span: Span) -> void:
	var record: LogRecord = LogRecord.new(message, span.duplicate())
	var index: int = records.size()
	
	while index > 0:
		var previous: LogRecord = records[index - 1]
		
		if record.is_logged_after(previous):
			break
		
		index -= 1
	
	records.insert(index, record)
