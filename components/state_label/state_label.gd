extends Control

# State Label
# A state label is a debug component that displays a state machine's current
# state.

export(NodePath) var _state_machine_path: NodePath

onready var _state_machine: StateMachine = get_node(_state_machine_path)
onready var _label: Label = $Label

# Run when the state label finishes entering the scene tree. Show the state
# label if the game is in debug mode. Otherwise, free the state label.
func _ready() -> void:
	if OS.is_debug_build():
		show()
	else:
		queue_free()


# Run on every physics frame. Update the state label's text.
func _physics_process(_delta: float) -> void:
	_label.text = _state_machine.get_state_name()
