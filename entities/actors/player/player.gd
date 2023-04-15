class_name Player
extends Actor

# Player Base
# Players are actors that can be controlled by the user.

@export var _freeze_state: State
@export var _transition_state: State

var _save_data: SaveData = SaveManager.get_working_data()
var _state_stack: Array[State] = []

@onready var _interactor: Interactor = $SmoothPivot/Interactor
@onready var _triggering_shape: CollisionShape2D = $TriggeringArea/TriggeringShape

# Run when the player enters the scene tree. Subscribe the player to the event
# bus.
func _enter_tree() -> void:
	EventBus.subscribe_node(EventBus.player_push_freeze_state_request, push_freeze_state)
	EventBus.subscribe_node(EventBus.player_push_transition_state_request, push_transition_state)
	EventBus.subscribe_node(EventBus.player_pop_state_request, pop_state)
	EventBus.subscribe_node(EventBus.save_state_request, save_state)


# Get the player's interact input.
func get_interact_input() -> bool:
	return Input.is_action_just_pressed("interact")


# Get the player's move input.
func get_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()


# Get the player's pause input.
func get_pause_input() -> bool:
	return Input.is_action_just_pressed("pause")


# Push a state to the player's state stack.
func push_state(state: State) -> void:
	_triggering_shape.set_disabled.call_deferred(true)
	_interactor.disable()
	_state_stack.push_back(_state_machine.get_state())
	_state_machine.change_state(state)


# Push the freeze state to the player's state stack.
func push_freeze_state() -> void:
	push_state(_freeze_state)


# Push the transition state to the player's state stack.
func push_transition_state() -> void:
	push_state(_transition_state)


# Pop a state from the player's state stack.
func pop_state() -> void:
	if not _state_stack.is_empty():
		_state_machine.change_state(_state_stack.pop_back())
		
		if _state_stack.is_empty():
			_interactor.enable()
			_triggering_shape.set_disabled.call_deferred(false)


# Save the player's state and display floating text.
func save_state() -> void:
	_save_data.position = position
	_save_data.angle = smooth_pivot.rotation_degrees
	EventBus.floating_text_display_request.emit("FLOATING_TEXT.SAVED", position)
