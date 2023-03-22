class_name MenuCutsceneAction
extends CutsceneAction

# Menu Cutscene Action
# A menu cutscene action is a cutscene action that manages a dialog menu.

var _messages: PoolStringArray = PoolStringArray()
var _objects: Array = []
var _methods: PoolStringArray = PoolStringArray()
var _args: Array = []
var _is_finished: bool = false

# Run when the menu cutscene action begins. Subscribe the menu cutscene action
# to the event bus and display the menu cutscene action's messages.
func begin() -> void:
	EventBus.subscribe(
			"dialog_option_pressed", self, "_on_dialog_option_pressed", [], CONNECT_ONESHOT)
	EventBus.emit_dialog_display_options_request(_messages)


# Tick the menu cutscene action and return whether it has finished.
func tick(_delta: float) -> bool:
	return _is_finished


# Add an option to the menu cutscene action.
func add_option(message: String, object: Object, method: String, args: Array) -> void:
	_messages.push_back(message)
	_objects.push_back(object)
	_methods.push_back(method)
	_args.push_back(args)


# Run when a dialog option is pressed. Call an option method and mark the menu
# cutscene action as finished.
func _on_dialog_option_pressed(index: int) -> void:
	var object: Object = _objects[index]
	var method: String = _methods[index]
	var args: Array = _args[index]
	
	if is_instance_valid(object) and object.has_method(method):
		object.callv(method, args)
	
	_is_finished = true
