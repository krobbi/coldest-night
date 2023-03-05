class_name Player
extends Actor

# Player Base
# Players are actors that can be controlled by the user.

export(NodePath) var _freeze_state_path: NodePath
export(NodePath) var _moving_state_path: NodePath
export(NodePath) var _transitioning_state_path: NodePath

var _save_data: SaveData = SaveManager.get_working_data()
var _is_frozen: bool = false
var _unfreeze_state: State

onready var _freeze_state: State = get_node(_freeze_state_path)
onready var _moving_state: State = get_node(_moving_state_path)
onready var _transitioning_state: State = get_node(_transitioning_state_path)
onready var _interactor: Interactor = $SmoothPivot/Interactor
onready var _triggering_shape: CollisionShape2D = $TriggeringArea/TriggeringShape

# Run when the player enters the scene tree. Subscribe the player to the event
# bus.
func _enter_tree() -> void:
	EventBus.subscribe_node("player_freeze_request", self, "freeze")
	EventBus.subscribe_node("player_unfreeze_request", self, "unfreeze")
	EventBus.subscribe_node("player_transition_request", self, "transition")
	EventBus.subscribe_node("save_state_request", self, "save_state")


# Get the player's interact input.
func get_interact_input() -> bool:
	return Input.is_action_just_pressed("interact")


# Get the player's move input.
func get_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()


# Get the player's pause input.
func get_pause_input() -> bool:
	return Input.is_action_just_pressed("pause")


# Get the player's moving state.
func get_moving_state() -> State:
	return _moving_state


# Freeze the player.
func freeze() -> void:
	if _is_frozen:
		return
	
	_is_frozen = true
	_unfreeze_state = state_machine.get_state()
	state_machine.change_state(_freeze_state)
	disable_triggers()


# Unfreeze the player.
func unfreeze() -> void:
	if not _is_frozen:
		return
	
	_is_frozen = false
	enable_triggers()
	state_machine.change_state(_unfreeze_state)


# Transition the player.
func transition() -> void:
	state_machine.change_state(_transitioning_state)


# Enables the player's ability to interact with triggers and interactables.
func enable_triggers() -> void:
	_triggering_shape.set_deferred("disabled", false)
	_interactor.enable()


# Disable the player's ability to interact with triggers and interactables.
func disable_triggers() -> void:
	_triggering_shape.set_deferred("disabled", true)
	_interactor.disable()


# Save the player's state and display floating text.
func save_state() -> void:
	_save_data.position = position
	_save_data.angle = smooth_pivot.rotation_degrees
	EventBus.emit_floating_text_display_request("FLOATING_TEXT.SAVED", position)
