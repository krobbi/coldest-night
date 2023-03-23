extends Trigger

# Run Cutscene Trigger
# A run cutscene trigger is a trigger that runs a cutscene when entered.

export(NodePath) var _cutscene_path: NodePath

onready var _cutscene: Cutscene = get_node(_cutscene_path)

# Run when the run cutscene trigger is entered. Run the run cutscene trigger's
# cutscene.
func _enter() -> void:
	_cutscene.run()
