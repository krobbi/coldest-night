class_name Cutscene
extends Node

# Cutscene
# A cutscene is a component that runs a queue of cutscene actions.

signal cutscene_finished

@export var _is_autorun: bool = false

var _menu_action: MenuCutsceneAction = MenuCutsceneAction.new()
var _current_action: CutsceneAction = null
var _action_queue: Array[CutsceneAction] = []

# Run when the cutscene enters the scene tree. Disable the cutscene's physics
# process and run the cutscene if it is an autorun.
func _ready() -> void:
	set_physics_process(false)
	
	if _is_autorun:
		call_deferred("run")


# Run on every physics frame while the cutscene has actions. Process the current
# action.
func _physics_process(delta: float) -> void:
	if not _current_action:
		if not _action_queue.is_empty():
			_current_action = _action_queue.pop_front()
			_current_action.begin()
		else:
			set_physics_process(false)
			return
	
	if _current_action.tick(delta):
		_current_action.end()
		_current_action = null
		
		if _action_queue.is_empty():
			set_physics_process(false)
			cutscene_finished.emit()


# Run the cutscene.
func run() -> void:
	# Include an empty cutscene action by default to ensure that the
	# `cutscene_finished` signal is emitted.
	add_action(CutsceneAction.new())


# Set a flag.
func set_flag(flag: String, value: int) -> void:
	SaveManager.get_working_data().set_flag(flag, value)


# Get a flag.
func get_flag(flag: String) -> int:
	return SaveManager.get_working_data().get_flag(flag)


# Add an action to the cutscene.
func add_action(action: CutsceneAction) -> void:
	_action_queue.push_back(action)
	set_physics_process(true)


# Call a callable.
func then(callable: Callable) -> void:
	add_action(CallCutsceneAction.new(callable))


# Wait for a signal.
func wait(awaited_signal: Signal) -> void:
	add_action(AwaitCutsceneAction.new(awaited_signal))


# Sleep for a duration in seconds.
func sleep(duration: float) -> void:
	add_action(SleepCutsceneAction.new(duration))


# Show the dialog display.
func show() -> void:
	then(func() -> void: EventBus.dialog_show_request.emit())


# Hide the dialog display.
func hide() -> void:
	then(func() -> void: EventBus.dialog_hide_request.emit())


# Display a dialog speaker.
func speaker(speaker_name: String = "") -> void:
	if speaker_name.is_empty():
		then(func() -> void: EventBus.dialog_clear_name_request.emit())
	else:
		then(func() -> void: EventBus.dialog_display_name_request.emit(speaker_name))


# Display a dialog message.
func say(message: String) -> void:
	then(func() -> void: EventBus.dialog_display_message_request.emit(message))
	wait(EventBus.dialog_message_finished)


# Add an option to the dialog menu.
func option(message: String, callable: Callable) -> void:
	_menu_action.add_option(message, callable)


# Display the dialog menu.
func menu() -> void:
	add_action(_menu_action)
	_menu_action = MenuCutsceneAction.new()


# Face an actor to an angle.
func face(actor_key: String, degrees: float) -> void:
	add_action(FaceCutsceneAction.new(get_tree(), actor_key, degrees))


# Path an actor to a target position.
func path(actor_key: String, target_pos: Vector2) -> void:
	add_action(PathCutsceneAction.new(get_tree(), actor_key, target_pos))


# Freeze the player.
func freeze() -> void:
	then(func() -> void: EventBus.player_push_freeze_state_request.emit())


# Unfreeze the player.
func unfreeze() -> void:
	then(func() -> void: EventBus.player_pop_state_request.emit())
