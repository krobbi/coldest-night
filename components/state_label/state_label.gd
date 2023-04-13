extends Control

# State Label
# A state label is a debug component that displays a state machine's current
# state.

@export var _state_machine: StateMachine

@onready var _label: Label = $Label

# Run when the state label enters the scene tree. Disable the state label's
# physics process and subscribe the state label to the configuration bus if the
# game is in debug mode. Otherwise, free the state label.
func _enter_tree() -> void:
	set_physics_process(false)
	
	if OS.is_debug_build():
		ConfigBus.subscribe_node_bool("debug.show_state_labels", _on_visibility_changed)
	else:
		queue_free()


# Run on every physics frame while the state label's physics process is enabled.
# Update the state label's text.
func _physics_process(_delta: float) -> void:
	_label.text = _state_machine.get_state().name


# Run when the state label's visibility changes. Set the state label's physics
# process and visibility.
func _on_visibility_changed(value: bool) -> void:
	set_physics_process(value)
	set_visible(value)
