class_name Player
extends Actor

# Player Base
# Players are actors that can be controlled by the user.

export(NodePath) var _freeze_state_path: NodePath
export(NodePath) var _moving_state_path: NodePath
export(NodePath) var _transitioning_state_path: NodePath

var _is_frozen: bool = false
var _thaw_state: State

onready var _freeze_state: State = get_node(_freeze_state_path)
onready var _moving_state: State = get_node(_moving_state_path)
onready var _transitioning_state: State = get_node(_transitioning_state_path)
onready var _interactor: Interactor = $SmoothPivot/Interactor
onready var _triggering_shape: CollisionShape2D = $TriggeringArea/TriggeringShape

# Run when the player enters the scene tree. Connect the player to the event
# bus.
func _enter_tree() -> void:
	Global.events.safe_connect("player_freeze_request", self, "freeze")
	Global.events.safe_connect("player_thaw_request", self, "thaw")
	Global.events.safe_connect("save_state_request", self, "_on_events_save_state_request")


# Run when the player exits the scene tree. Disconnect the player from the event
# bus.
func _exit_tree() -> void:
	Global.events.safe_disconnect("player_freeze_request", self, "freeze")
	Global.events.safe_disconnect("player_thaw_request", self, "thaw")
	Global.events.safe_disconnect("save_state_request", self, "_on_events_save_state_request")


# Get the player's interact input.
func get_interact_input() -> bool:
	return Input.is_action_just_pressed("interact")


# Get the player's move input.
func get_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


# Get the player's pause input.
func get_pause_input() -> bool:
	return Input.is_action_just_pressed("pause")


# Get the player's moving state.
func get_moving_state() -> State:
	return _moving_state


# Get the player's transitioning state.
func get_transitioning_state() -> State:
	return _transitioning_state


# Get whether the player is frozen.
func is_frozen() -> bool:
	return _is_frozen


# Freeze the player.
func freeze() -> void:
	if _is_frozen:
		return
	
	_is_frozen = true
	_thaw_state = state_machine.get_state()
	state_machine.change_state(_freeze_state)
	disable_triggers()


# Thaw the player.
func thaw() -> void:
	if not _is_frozen:
		return
	
	_is_frozen = false
	enable_triggers()
	state_machine.change_state(_thaw_state)


# Enables the player's ability to interact with triggers and interactables.
func enable_triggers() -> void:
	_triggering_shape.set_deferred("disabled", false)
	_interactor.enable()


# Disable the player's ability to interact with triggers and interactables.
func disable_triggers() -> void:
	_triggering_shape.set_deferred("disabled", true)
	_interactor.disable()


# Interact with the player's selected interactable if one is available.
func interact() -> void:
	_interactor.interact()


# Run when a state save is requested. Display floating text.
func _on_events_save_state_request() -> void:
	Global.events.emit_signal("floating_text_display_request", "FLOATING_TEXT.SAVED", position)
