extends Node

# Cutscene Manager
# The cutscene manager is an autoload scene that handles running cutscenes. It
# can be accessed from any script by using `CutsceneManager`.

# Run a cutscene from its path. Run NightScript if the path is not a resource.
func run_cutscene(path: String) -> void:
	if path.begins_with("res://"):
		# TODO: Implement cutscenes.
		pass
	else:
		EventBus.emit_nightscript_run_script_request(path)
