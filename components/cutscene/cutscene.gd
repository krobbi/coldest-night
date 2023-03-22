class_name Cutscene
extends Node

# Cutscene
# A cutscene is a component that runs a queue of cutscene actions.

signal cutscene_finished

export(bool) var _is_autorun: bool = false

var _current_action: CutsceneAction = null
var _action_queue: Array = []

# Run when the cutscene enters the scene tree. Disable the cutscene's physics
# process and run the cutscene if it is an autorun.
func _ready() -> void:
	set_physics_process(false)
	
	if _is_autorun:
		run()


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
			end()
			emit_signal("cutscene_finished")


# Run the cutscene.
func run() -> void:
	nop()


# Run when the cutscene ends.
func end() -> void:
	pass


# Add an action to the cutscene.
func add_action(action: CutsceneAction) -> void:
	_action_queue.push_back(action)
	set_physics_process(true)


# Run an empty cutscene action.
func nop() -> void:
	add_action(CutsceneAction.new())


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
