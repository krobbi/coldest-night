class_name DialogInterpreter
extends Node

# Dialog Interpreter
# A dialog interpreter is a component of a dialog display that handles
# interpreting dialog trees, and provides methods and signals to interface with
# the dialog display.

signal dialog_opening;
signal dialog_opened;
signal dialog_closing;
signal dialog_closed;
signal message_displayed(text);
signal message_finished;
signal menu_displayed(texts);
signal menu_hidden;
signal option_hovered(index);
signal option_selected(index);

enum State {
	CLOSED,
	OPEN,
	LOCKED,
	CLOSING,
	OPENING,
	DISPLAYING_MESSAGE,
	DISPLAYING_MENU,
};

var _save_data: SaveData = Global.save.get_working_data();
var _state: int = State.CLOSED;
var _tree: DialogTree = DialogTree.new();
var _builder: DialogTreeBuilder;
var _running: bool = false; # Running flag.
var _branched: bool = false; # Branched flag.
var _bc: int = 0; # Branch counter.
var _lc: int = 0; # Leaf counter.
var _menu_selection: int = 0;
var _menu_branches: PoolIntArray = PoolIntArray();
var _menu_texts: PoolStringArray = PoolStringArray();

# Virtual _ready method. Runs when the dialog interpreter entes the scene tree.
# Polymorphically instantiates the dialog tree builder based on whether the game
# is running as a debug build or as a release build:
func _ready() -> void:
	# CNEP:DEBUG
	if OS.is_debug_build():
		_builder = load("res://utils/dialog/debug/dialog_parser.gd").new(_tree);
		return;
	# CNEP:END_DEBUG
	
	_builder = load("res://utils/dialog/release/dialog_loader.gd").new(_tree);


# Virtual _exit_tree method. Runs when the dialog interpreter exits the scene
# tree. Frees the dialog parser and destructs and frees the dialog tree:
func _exit_tree() -> void:
	_builder.free();
	_tree.destruct();
	_tree.free();


# Starts opening the dialog interpreter from a dialog source file's key:
func open(key: String) -> void:
	if _state != State.CLOSED:
		return;
	
	_state = State.OPENING;
	_running = false;
	_branched = false;
	_builder.build(key);
	
	if _tree.has_branch(_tree.ReservedBranch.REPEAT) and _get_flag("seen_dialog", key) != 0:
		_bc = _tree.ReservedBranch.REPEAT;
	else:
		_bc = _tree.ReservedBranch.MAIN;
	
	_lc = 0;
	_clear_menu();
	_set_flag("seen_dialog", key, 1);
	emit_signal("dialog_opening");


# Starts closing the dialog interpreter:
func close() -> void:
	if _state != State.OPEN:
		return;
	
	_state = State.CLOSING;
	_running = false;
	_builder.reset();
	_branched = false;
	_bc = _tree.ReservedBranch.MAIN;
	_lc = 0;
	_clear_menu();
	emit_signal("dialog_closing");


# Handles an 'OK' input from the dialog display:
func input_ok() -> void:
	match _state:
		State.OPEN:
			_run();
		State.DISPLAYING_MESSAGE:
			emit_signal("message_finished");
		State.DISPLAYING_MENU:
			_state = State.LOCKED;
			emit_signal("option_selected", _menu_selection);
			_hide_menu();
			_bc = _menu_branches[_menu_selection];
			_lc = 0;
			_branched = false;
			_state = State.OPEN;
			_run();


# Handles an 'up' input from the dialog display:
func input_up() -> void:
	if _state != State.DISPLAYING_MENU:
		return;
	
	if _menu_selection <= 0:
		_menu_selection = _menu_branches.size() - 1;
	else:
		_menu_selection -= 1;
	
	emit_signal("option_hovered", _menu_selection);


# Handles a 'down' input from the dialog display:
func input_down() -> void:
	if _state != State.DISPLAYING_MENU:
		return;
	
	if _menu_selection >= _menu_branches.size() - 1:
		_menu_selection = 0;
	else:
		_menu_selection += 1;
	
	emit_signal("option_hovered", _menu_selection);


# Handles an 'hover' input from the dialog display:
func input_hover(index: int) -> void:
	if _state != State.DISPLAYING_MENU or index == _menu_selection:
		return;
	
	if index < 0:
		index = 0;
	elif index >= _menu_branches.size():
		index = _menu_branches.size() - 1;
	
	_menu_selection = index;
	emit_signal("option_hovered", _menu_selection);


# Notifies the dialog interpreter that the dialog display has finished opening
# and starts interpreting the dialog tree:
func notify_open() -> void:
	if _state != State.OPENING:
		return;
	
	_state = State.OPEN;
	emit_signal("dialog_opened");
	_run();


# Notifies the dialog interpreter that the dialog display has finished closing:
func notify_closed() -> void:
	if _state != State.CLOSING:
		return;
	
	_state = State.CLOSED;
	emit_signal("dialog_closed");


# Notifies the dialog interpreter that the dialog display has finished
# displaying the message:
func notify_message_displayed() -> void:
	if _state != State.DISPLAYING_MESSAGE:
		return;
	
	_state = State.OPEN;
	emit_signal("message_finished");
	
	# Continue running if there is a menu:
	if _tree.has_leaf(_bc, _lc) and _tree.get_leaf(_bc, _lc).opcode == DialogOpcode.MNC:
		_run();


# Sets a flag from its namespace and key:
func _set_flag(namespace: String, key: String, value: int) -> void:
	_save_data.set_flag(namespace, key, value);


# Gets a flag from its namespace and key:
func _get_flag(namespace: String, key: String) -> int:
	return _save_data.get_flag(namespace, key);


# Branches the dialog:
func _branch(branch: int) -> void:
	_bc = branch;
	_lc = 0;
	_branched = true;


# Displays a message to the dialog display:
func _display_message(text: String) -> void:
	_state = State.DISPLAYING_MESSAGE;
	emit_signal("message_displayed", text);


# Clears the menu for the dialog display:
func _clear_menu() -> void:
	_menu_selection = 0;
	_menu_branches.resize(0);
	_menu_texts.resize(0);


# Displays the menu to the dialog display:
func _display_menu() -> void:
	_state = State.DISPLAYING_MENU;
	emit_signal("menu_displayed", _menu_texts);
	emit_signal("option_hovered", _menu_selection);


# Hides the menu to the dialog display:
func _hide_menu() -> void:
	emit_signal("menu_hidden");


# Runs the current dialog tree until it is paused:
func _run() -> void:
	if _running:
		return;
	
	_running = true;
	
	while _running:
		if not _tree.has_leaf(_bc, _lc) or _state != State.OPEN:
			close();
			return;
		
		_running = _execute();
		
		if _branched:
			_branched = false;
		else:
			_lc += 1;


# Executes the current dialog leaf and returns whether execution should continue
# from the dialog leaf:
func _execute() -> bool:
	var leaf: DialogLeaf = _tree.get_leaf(_bc, _lc);
	
	match leaf.opcode: # Op code:
		DialogOpcode.HLT: # Halt:
			close();
			return false;
		DialogOpcode.BRA: # Branch always:
			_branch(leaf.branch);
		DialogOpcode.BEQV: # Branch equals value:
			if _get_flag(leaf.namespace_left, leaf.key_left) == leaf.value:
				_branch(leaf.branch);
		DialogOpcode.BEQF: # Branch equals flag:
			if(
					_get_flag(leaf.namespace_left, leaf.key_left) ==
							_get_flag(leaf.namespace_right, leaf.key_right)
			):
				_branch(leaf.branch);
		DialogOpcode.BNEV: # Branch not equals value:
			if _get_flag(leaf.namespace_left, leaf.key_left) != leaf.value:
				_branch(leaf.branch);
		DialogOpcode.BNEF: # Branch not equals flag:
			if(
					_get_flag(leaf.namespace_left, leaf.key_left) !=
							_get_flag(leaf.namespace_right, leaf.key_right)
			):
				_branch(leaf.branch);
		DialogOpcode.BGTV: # Branch greater than value:
			if _get_flag(leaf.namespace_left, leaf.key_left) > leaf.value:
				_branch(leaf.branch);
		DialogOpcode.BGTF: # Branch greater than flag:
			if(
					_get_flag(leaf.namespace_left, leaf.key_left) >
							_get_flag(leaf.namespace_right, leaf.key_right)
			):
				_branch(leaf.branch);
		DialogOpcode.BGEF: # Branch greater than equals flag:
			if(
					_get_flag(leaf.namespace_left, leaf.key_left) >=
							_get_flag(leaf.namespace_right, leaf.key_right)
			):
				_branch(leaf.branch);
		DialogOpcode.BLTV: # Branch less than value:
			if _get_flag(leaf.namespace_left, leaf.key_left) < leaf.value:
				_branch(leaf.branch);
		DialogOpcode.ADV: # Add value to flag:
			_set_flag(
					leaf.namespace_left, leaf.key_left, _get_flag(
							leaf.namespace_left, leaf.key_left
					) + leaf.value
			);
		DialogOpcode.ADF: # Add flag to flag:
			_set_flag(
					leaf.namespace_left, leaf.key_left, _get_flag(
							leaf.namespace_left, leaf.key_left
					) + _get_flag(leaf.namespace_right, leaf.key_right)
			);
		DialogOpcode.SBF: # Subtract flag from flag:
			_set_flag(
					leaf.namespace_left, leaf.key_left, _get_flag(
							leaf.namespace_left, leaf.key_left
					) - _get_flag(leaf.namespace_right, leaf.key_right)
			);
		DialogOpcode.SFV: # Set flag from value:
			_set_flag(leaf.namespace_left, leaf.key_left, leaf.value);
		DialogOpcode.SFF: # Set flag from flag:
			_set_flag(
					leaf.namespace_left, leaf.key_left, _get_flag(
							leaf.namespace_right, leaf.key_right
					)
			);
		DialogOpcode.SAV: # Save game:
			Global.save.save_game();
		DialogOpcode.QTG: # Quit game:
			Global.quit(OK);
			return false;
		DialogOpcode.MSG: # Display message:
			_display_message(leaf.text);
			return false;
		DialogOpcode.MNC: # Clear menu:
			_clear_menu();
		DialogOpcode.MNA: # Append menu:
			_menu_branches.push_back(leaf.branch);
			_menu_texts.push_back(leaf.text);
		DialogOpcode.MND: # Display menu:
			_display_menu();
			return false;
		DialogOpcode.NOP: # No operation:
			pass;
		_:
			print("Dialog leaf has an unsupported opcode %d!" % leaf.opcode);
			return false;
	
	return true;
