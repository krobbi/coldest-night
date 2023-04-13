extends Trigger

# Run Cutscene Trigger
# A run cutscene trigger is a trigger that runs a cutscene when entered.

@export var _cutscene: Cutscene

# Run when the run cutscene trigger is entered. Run the run cutscene trigger's
# cutscene.
func _on_entered() -> void:
	_cutscene.run()
