## A menu row that controls an input mapping.
extends MenuRow

## The action to control.
@export var _action: String

## Whether the control menu row is waiting for input.
var _is_active: bool = false

## The [Button] for activating the control menu row.
@onready var _button: Button = $Content/Button

## The [Timer] for deactivating the control menu row.
@onready var _input_timer: Timer = $InputTimer

## The [AudioStreamPlayer] to play when the action is remapped.
@onready var _mapped_player: AudioStreamPlayer = $MappedPlayer

## Run when the control menu row is ready. Set the control menu row's tooltip
## and text and connect the control menu row to the input manager.
func _ready() -> void:
	tooltip = "TOOLTIP.CONTROL.%s" % _action.to_upper()
	$Content/Label.text = "ACTION.%s" % _action.to_upper()
	_deactivate()
	InputManager.mappings_applied.connect(_deactivate)


## Run when the control menu row exits the scene tree. Disconnect the control
## menu row from the input manager.
func _exit_tree() -> void:
	InputManager.mappings_applied.disconnect(_deactivate)


# Run when the control menu row receives an input event. Remap the control menu
# row's action if the control button is waiting for input.
func _input(event: InputEvent) -> void:
	if _is_active and InputManager.map_action_event(_action, event):
		get_viewport().set_input_as_handled() # Consume the input.
		_mapped_player.play()


## Activate the control menu row.
func _activate() -> void:
	_is_active = true
	_button.set_pressed_no_signal(true)
	_button.text = "INPUT.PROMPT"
	_input_timer.start()


## Deactivate the control menu row.
func _deactivate() -> void:
	_is_active = false
	_input_timer.stop()
	_button.set_pressed_no_signal(false)
	_button.text = InputManager.get_mapping_name(_action)


## Run when the control menu row's [Button] is toggled. Activate or deactivate
## the control menu row.
func _on_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_activate()
	else:
		_deactivate()
