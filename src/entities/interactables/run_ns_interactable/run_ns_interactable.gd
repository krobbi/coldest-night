class_name RunNSInteractable
extends Interactable

# Run NightScript Interactable
# A run NightScript interactable is an interactable that runs a NightScript
# program when interacted with by the current player.

export(String) var program: String

# Virtual _interact method. Runs when the run NightScript interactable is
# interacted with by the current player. Runs a NightScript program:
func _interact() -> void:
	Global.events.emit_signal("nightscript_run_program_request", program)
