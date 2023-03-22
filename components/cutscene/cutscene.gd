class_name Cutscene
extends Node

# Cutscene
# A cutscene is a component that runs a queue of cutscene actions.

signal cutscene_finished

export(bool) var _is_autorun: bool = false

var _menu_action: MenuCutsceneAction = MenuCutsceneAction.new()
var _current_action: CutsceneAction = null
var _action_queue: Array = []

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
		if not _action_queue.empty():
			_current_action = _action_queue.pop_front()
			_current_action.begin()
		else:
			set_physics_process(false)
			return
	
	if _current_action.tick(delta):
		_current_action.end()
		_current_action = null
		
		if _action_queue.empty():
			set_physics_process(false)
			emit_signal("cutscene_finished")


# Run the cutscene.
func run() -> void:
	nop()


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


# Run an empty cutscene action.
func nop() -> void:
	add_action(CutsceneAction.new())


# Call a method.
func then(method: String, args: Array = [], object: Object = null) -> void:
	if not is_instance_valid(object):
		object = self
	
	add_action(CallCutsceneAction.new(object, method, args))


# Wait for a signal.
func wait(object: Object, signal_name: String) -> void:
	add_action(AwaitCutsceneAction.new(object, signal_name))


# Sleep for a duration in seconds.
func sleep(duration: float) -> void:
	add_action(SleepCutsceneAction.new(duration))


# Show the dialog display.
func show() -> void:
	add_action(CallCutsceneAction.new(EventBus, "emit_dialog_show_request"))


# Hide the dialog display.
func hide() -> void:
	add_action(CallCutsceneAction.new(EventBus, "emit_dialog_hide_request"))


# Display a dialog speaker.
func speaker(speaker_name: String = "") -> void:
	if speaker_name.empty():
		add_action(CallCutsceneAction.new(EventBus, "emit_dialog_clear_name_request"))
	else:
		add_action(CallCutsceneAction.new(
				EventBus, "emit_dialog_display_name_request", [speaker_name]))


# Display a dialog message.
func say(message: String) -> void:
	add_action(CallCutsceneAction.new(EventBus, "emit_dialog_display_message_request", [message]))
	add_action(AwaitCutsceneAction.new(EventBus, "dialog_message_finished"))


# Add an option to the dialog menu.
func option(message: String, method: String, args: Array = [], object: Object = null) -> void:
	if not is_instance_valid(object):
		object = self
	
	_menu_action.add_option(message, object, method, args)


# Display the dialog menu.
func menu() -> void:
	add_action(_menu_action)
	_menu_action = MenuCutsceneAction.new()


# Freeze the player.
func freeze() -> void:
	add_action(CallCutsceneAction.new(EventBus, "emit_player_freeze_request"))


# Unfreeze the player.
func unfreeze() -> void:
	add_action(CallCutsceneAction.new(EventBus, "emit_player_unfreeze_request"))
