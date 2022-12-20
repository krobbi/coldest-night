extends Label

# State Label
# A state label is a test component of an entity that displays a state machine's
# current state.

export(NodePath) var _state_machine_path: NodePath = NodePath()

var _state_machine: StateMachine = null

# Virtual _ready method. Runs when the state label enters the scene tree. Sets
# and connects the state label's state machine:
func _ready() -> void:
	if(
			not OS.is_debug_build() or not _state_machine_path
			or not get_node(_state_machine_path) is StateMachine
	):
		queue_free()
		return
	
	_state_machine = get_node(_state_machine_path)
	text = _state_machine.get_key()
	show()
	var error: int = _state_machine.connect("state_changed", self, "set_text")
	
	if error and _state_machine.is_connected("state_changed", self, "set_text"):
		_state_machine.disconnect("state_changed", self, "set_text")


# Virtual _enter_tree method. Runs when the state label enters the scene tree.
# Reconnects the state label's state machine:
func _enter_tree() -> void:
	if not _state_machine or _state_machine.is_connected("state_changed", self ,"set_text"):
		return
	
	var error: int = _state_machine.connect("state_changed", self, "set_text")
	
	if error and _state_machine.is_connected("state_changed", self, "set_text"):
		_state_machine.disconnect("state_changed", self, "set_text")


# Virtual _exit_tree method. Runs when the state label exits the scene tree.
# Disconnects the state label's state machine:
func _exit_tree() -> void:
	if _state_machine and _state_machine.is_connected("state_changed", self, "set_text"):
		_state_machine.disconnect("state_changed", self, "set_text")
