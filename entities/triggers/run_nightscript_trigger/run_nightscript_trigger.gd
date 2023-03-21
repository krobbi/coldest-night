extends Trigger

# Run NightScript Trigger
# A run NightScript trigger is a trigger that runs a NightScript script when
# entered.

export(String) var _script_key: String

# Get the run NightScript trigger's NightScript script key.
func get_nightscript_script_key() -> String:
	return _script_key


# Run when the run NightScript trigger is entered. Run a NightScript script.
func _enter() -> void:
	CutsceneManager.run_cutscene(_script_key)
