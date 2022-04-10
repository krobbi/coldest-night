class_name RunNSTrigger
extends Trigger

# Run NightScript Trigger
# A run NightScript trigger is a trigger that runs a NightScript program when
# entered by a player.

export(String) var program: String

# Virtual _player_enter method. Runs when a player enters the trigger. Runs a
# NightScript program.
func _player_enter(_player: Player) -> void:
	Global.events.emit_signal("nightscript_run_program_request", program)
