class_name Player
extends Actor

# Player Base
# Players are actors that can be controlled by the user.

signal change_player_request

var _is_frozen: bool = false
var _thaw_state: String = ""

onready var _interactor: Interactor = $SmoothPivot/Interactor
onready var _triggering_shape: CollisionShape2D = $TriggeringArea/TriggeringShape

# Virtual _enter_tree method. Runs when the player enters the scene tree.
# Connects the player to the event bus:
func _enter_tree() -> void:
	Global.events.safe_connect("player_freeze_request", self, "freeze")
	Global.events.safe_connect("player_thaw_request", self, "thaw")
	Global.events.safe_connect("save_state_request", self, "_on_events_save_state_request")


# Virtual _exit_tree method. Runs when the player exits the scene tree.
# Disconnects the player from the event bus:
func _exit_tree() -> void:
	Global.events.safe_disconnect("player_freeze_request", self, "freeze")
	Global.events.safe_disconnect("player_thaw_request", self, "thaw")
	Global.events.safe_disconnect("save_state_request", self, "_on_events_save_state_request")


# Gets whether the player is frozen:
func is_frozen() -> bool:
	return _is_frozen


# Freezes the player:
func freeze() -> void:
	if _is_frozen:
		return
	
	_is_frozen = true
	_thaw_state = state_machine.get_key()
	state_machine.change_state("Scripted")


# Thaws the player:
func thaw() -> void:
	if not _is_frozen:
		return
	
	_is_frozen = false
	state_machine.change_state(_thaw_state)


# Enables the player's ability to interact with triggers and interactables:
func enable_triggers() -> void:
	_triggering_shape.set_deferred("disabled", false)
	_interactor.enable()


# Disables the player's ability to interact with triggers and interactables:
func disable_triggers() -> void:
	_triggering_shape.set_deferred("disabled", true)
	_interactor.disable()


# Interacts with the playe's selected interactable if one is available:
func interact() -> void:
	_interactor.interact()


# Requests that the current player is changed:
func request_change_player() -> void:
	emit_signal("change_player_request")


# Signal callback for save_state_request on the event bus. Displays floating
# text at the player's position if it is the current player:
func _on_events_save_state_request() -> void:
	if _thaw_state != "Scripted" or state_machine.get_key() != "Scripted":
		Global.events.emit_signal("floating_text_display_request", "FLOATING_TEXT.SAVED", position)
