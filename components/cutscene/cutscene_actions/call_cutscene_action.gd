class_name CallCutsceneAction
extends CutsceneAction

# Call Cutscene Action
# A call cutscene action is a cutscene action that calls a method of an object.

var _object: Object
var _method: String
var _args: Array

# Initialize the call cutscene action's object, method, and arguments.
func _init(object_ref: Object, method_val: String, args_ref: Array = []) -> void:
	_object = object_ref
	_method = method_val
	_args = args_ref


# Run when the call cutscene action begins. Call the method.
func begin() -> void:
	_object.callv(_method, _args)
