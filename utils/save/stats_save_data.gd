class_name StatsSaveData
extends Object

# Statistics Save Data
# Statistics save data are structures that represent persistent statistics that
# are stored in save files.

var time_fraction: float = 0.0
var time_seconds: int = 0
var time_minutes: int = 0
var time_hours: int = 0
var alert_count: int = 0

# Clears the statistics save data to empty values:
func clear() -> void:
	time_fraction = 0.0
	time_seconds = 0
	time_minutes = 0
	time_hours = 0
	alert_count = 0


# Accumulates the statistics save data's time:
func accumulate_time(delta: float) -> void:
	time_fraction += delta
	
	while time_fraction >= 1.0:
		time_fraction -= 1.0
		time_seconds += 1
		
		while time_seconds >= 60:
			time_seconds -= 60
			time_minutes += 1
			
			while time_minutes >= 60:
				time_minutes -= 60
				time_hours += 1


# Accumulates the statistics save data's alert count:
func accumulate_alert_count() -> void:
	if alert_count < 999:
		alert_count += 1
	else:
		alert_count = 999


# Serialize the stats save data to a JSON object.
func serialize() -> Dictionary:
	return {
		"timeHours": time_hours,
		"timeMinutes": time_minutes,
		"timeSeconds": time_seconds,
		"timeFraction": time_fraction,
		"alertCount": alert_count,
	}


# Deserialize the stats save data from a JSON object.
func deserialize(data: Dictionary) -> void:
	self.time_hours = int(data.get("timeHours", 0.0))
	self.time_minutes = int(data.get("timeMinutes", 0.0))
	self.time_seconds = int(data.get("timeSeconds", 0.0))
	self.time_fraction = float(data.get("timeFraction", 0.0))
	self.alert_count = int(data.get("alertCount", 0))
