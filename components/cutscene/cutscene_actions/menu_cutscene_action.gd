class_name MenuCutsceneAction
extends CutsceneAction

# Menu Cutscene Action
# A menu cutscene action is a cutscene action that manages a dialog menu.

var _messages: PackedStringArray = PackedStringArray()
var _callables: Array[Callable] = []
var _is_finished: bool = false

# Run when the menu cutscene action begins. Subscribe the menu cutscene action
# to the event bus and display the menu cutscene action's messages.
func begin() -> void:
	EventBus.subscribe(EventBus.dialog_option_pressed, _on_dialog_option_pressed, CONNECT_ONE_SHOT)
	EventBus.dialog_display_options_request.emit(_messages)


# Tick the menu cutscene action and return whether it has finished.
func tick(_delta: float) -> bool:
	return _is_finished


# Add an option to the menu cutscene action.
func add_option(message: String, callable: Callable) -> void:
	_messages.push_back(message)
	_callables.push_back(callable)


# Run when a dialog option is pressed. Call the option's callable if it is valid
# and mark the menu cutscene action as finished.
func _on_dialog_option_pressed(index: int) -> void:
	var callable: Callable = _callables[index]
	
	if callable.is_valid():
		callable.call()
	
	_is_finished = true
