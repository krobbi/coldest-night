class_name NSInterpreter
extends Node

# NightScript Interpreter
# A NightScript interpreter is a NightScript utility that handles interpreting
# NightScript programs.

class NSMachine extends Object:
	
	# NightScript Machine
	# A NightScript machine is a helper structure used by a NightScript
	# interpreter that contains a NightScript program and its registers.
	
	var program: NSProgram = NSProgram.new()
	var pc: int
	var x: int = 0
	var y: int = 0
	var option_pointers: Array = []
	var option_texts: Array = []
	var active_option_pointers: Array = []
	var actor_key: String = ""
	var pathing_actors: Array = []
	
	# Constructor. Deserializes the NightScript machine's NightScript program's
	# bytecode and initializes the NightScript machine's registers:
	func _init(bytecode: PoolByteArray, is_seen: bool) -> void:
		program.deserialize_bytecode(bytecode)
		pc = program.vector_repeat if is_seen else program.vector_main
	
	
	# Destructor. Destructs and frees the NightScript machine's NightScript
	# program:
	func destruct() -> void:
		program.destruct()
		program.free()


signal program_finished

enum State {STOPPED, STARTING, RUNNING, AWAITING}

const MACHINE_STACK_LIMIT: int = 8
const EMPTY_BYTECODE: PoolByteArray = PoolByteArray([
	0x00, # Not cacheable.
	0x00, 0x00, # 0 strings.
	0x00, 0x00, # 0 flags.
	0x00, 0x00, # Main vector.
	0x00, 0x00, # Repeat vector.
	0x01, 0x00, # 1 operation.
	NSOp.HLT, # Halt.
])

export(NodePath) var _dialog_path: NodePath = NodePath()
export(String) var _autorun: String

var _state: int = State.STOPPED
var _dialog: Dialog = null
var _is_caching: bool = true
var _bytecode_cache: Dictionary = {}
var _machine_stack: Array = []
var _machine: NSMachine = null

# Virtual _ready method. Runs when the NightScript interpreter enters the scene
# tree. Finds the NightScript interpreter's dialog display, connects the
# NightScript interpreter to the language manager, and runs the NightScript
# interpreter's autorun program:
func _ready() -> void:
	if _dialog_path and get_node(_dialog_path) is Dialog:
		_dialog = get_node(_dialog_path)
	
	var error: int = Global.lang.connect("locale_changed", self, "_on_lang_locale_changed")
	
	if error and Global.lang.is_connected("locale_changed", self, "_on_lang_locale_chanegd"):
		Global.lang.disconnect("locale_changed", self, "_on_lang_locale_changed")
		_is_caching = false
	
	if not _autorun.empty():
		run_program(_autorun)


# Virtual _process method. Runs on every frame. Steps the NightScript
# interpreter:
func _process(_delta: float) -> void:
	if _state == State.RUNNING:
		_step()


# Virtual _exit_tree method. Runs when the NightScript interpreter exits the
# scene tree. Destructs and frees the NightScript interpreter's NightScript
# machines and disconnects the NightScript interpreter from the language
# manager:
func _exit_tree() -> void:
	for machine in _machine_stack:
		machine.destruct()
		machine.free()
	
	if Global.lang.is_connected("locale_changed", self, "_on_lang_locale_changed"):
		Global.lang.disconnect("locale_changed", self, "_on_lang_locale_changed")


# Runs a NightScript program from its program key:
func run_program(program_key: String) -> void:
	if _state != State.STOPPED:
		return
	
	_state = State.STARTING
	_push_machine(program_key)
	_state = State.RUNNING


# Flushes the NightScript bytecode cache:
func flush_cache() -> void:
	_bytecode_cache.clear()


# Sets a flag from its namespace and key:
func _set_flag(namespace: String, key: String, value: int) -> void:
	Global.save.get_working_data().set_flag(namespace, key, value)


# Gets a flag from its namespace and key:
func _get_flag(namespace: String, key: String) -> int:
	return Global.save.get_working_data().get_flag(namespace, key)


# Gets NightScript bytecode from a NightScript program key:
func _get_bytecode(program_key: String) -> PoolByteArray:
	if _bytecode_cache.has(program_key):
		return _bytecode_cache[program_key]
	
	var base_path: String = "res://n/%s/%s.nsc"
	var global_locale: String = "g"
	
	if OS.is_debug_build():
		program_key = program_key.replace(".", "/")
		base_path = "res://assets/data/nightscript/%s/%s.ns"
		global_locale = "global"
	
	var file: File = File.new()
	var path: String = base_path % [Global.lang.locale, program_key]
	
	if not file.file_exists(path):
		path = base_path % [global_locale, program_key]
		
		if not file.file_exists(path):
			path = base_path % [Global.lang.get_default_locale(), program_key]
			
			if not file.file_exists(path):
				Global.logger.err_nsc_not_found(program_key)
				return EMPTY_BYTECODE
	
	var error: int = file.open(path, File.READ)
	
	if error:
		if file.is_open():
			file.close()
		
		Global.logger.err_nsc_read(program_key, error)
		return EMPTY_BYTECODE
	
	if OS.is_debug_build():
		var source: String = file.get_as_text()
		file.close()
		var compiler: Reference = load("res://utils/nightscript/debug/ns_compiler.gd").new()
		return compiler.compile_source(source)
	
	var bytecode: PoolByteArray = file.get_buffer(file.get_len())
	file.close()
	return bytecode


# Gets a scripted actor from its actor key. Returns null if the scripted actor
# is unavailable:
func _get_scripted_actor(actor_key: String) -> Actor:
	for actor in Global.tree.get_nodes_in_group("actors"):
		if actor.actor_key == actor_key and actor.state_machine.get_key() == "Scripted":
			return actor
	
	return null


# Pushes a new NightScript machine to the NightScript machine stack from its
# program key:
func _push_machine(program_key: String) -> void:
	if _machine_stack.size() >= MACHINE_STACK_LIMIT:
		return
	
	var bytecode: PoolByteArray = _get_bytecode(program_key)
	_machine = NSMachine.new(bytecode, _get_flag("ns_seen", program_key) != 0)
	_machine_stack.push_back(_machine)
	_set_flag("ns_seen", program_key, 1)
	
	if(
			_is_caching and _machine.program.is_cacheable
			and not program_key.empty() and not _bytecode_cache.has(program_key)
	):
		_bytecode_cache[program_key] = bytecode


# Pops the current NightScript machine from the NightScript machine stack:
func _pop_machine() -> void:
	if not _machine:
		return
	
	_machine.destruct()
	_machine.free()
	_machine_stack.remove(_machine_stack.size() - 1)
	
	if _machine_stack.empty():
		_machine = null
		_state = State.STOPPED
		emit_signal("program_finished")
	else:
		_machine = _machine_stack[-1]


# Pauses the NightScript interpreter until a signal is received from a source
# object:
func _await(source: Object, signal_name: String) -> void:
	if _state != State.RUNNING:
		return
	
	var error: int = source.connect(signal_name, self, "_on_await_finished", [], CONNECT_ONESHOT)
	
	if not error:
		_state = State.AWAITING
	elif source.is_connected(signal_name, self, "_on_await_finished"):
		source.disconnect(signal_name, self, "_on_await_finished")


# Pauses the NightScript interpreter until an option is pressed on the dialog:
func _await_option() -> void:
	if _state != State.RUNNING or not _dialog:
		return
	
	var error: int = _dialog.connect(
			"option_pressed", self, "_on_dialog_option_pressed", [], CONNECT_ONESHOT
	)
	
	if not error:
		_state = State.AWAITING
	elif _dialog.is_connected("option_pressed", self, "_on_dialog_option_pressed"):
		_dialog.disconnect("option_pressed", self, "_on_dialog_option_pressed")


# Steps the current NightScript machine:
func _step() -> void:
	var op: NSOp = _machine.program.ops[_machine.pc]
	_machine.pc += 1
	
	match op.op:
		NSOp.HLT: # Halt:
			_pop_machine()
		NSOp.RUN: # Run:
			_push_machine(op.txt)
		NSOp.SLP: # Sleep:
			_await(Global.tree.create_timer(float(op.val) * 0.01), "timeout")
		NSOp.JMP: # Jump:
			_machine.pc = op.val
		NSOp.BEQ: # Branch equals:
			if _machine.x == _machine.y:
				_machine.pc = op.val
		NSOp.BNE: # Branch not equals:
			if _machine.x != _machine.y:
				_machine.pc = op.val
		NSOp.BGT: # Branch greater than:
			if _machine.x > _machine.y:
				_machine.pc = op.val
		NSOp.BGE: # Branch greater equals:
			if _machine.x >= _machine.y:
				_machine.pc = op.val
		NSOp.LXC: # Load X constant:
			_machine.x = op.val
		NSOp.LXF: # Load X flag:
			_machine.x = _get_flag(op.txt, op.key)
		NSOp.STX: # Store X:
			_set_flag(op.txt, op.key, _machine.x)
		NSOp.LYC: # Load Y constant:
			_machine.y = op.val
		NSOp.LYF: # Load Y flag:
			_machine.y = _get_flag(op.txt, op.key)
		NSOp.STY: # Store Y:
			_set_flag(op.txt, op.key, _machine.y)
		NSOp.DGS: # Dialog show:
			if _dialog:
				_dialog.show_dialog()
		NSOp.DGH: # Dialog hide:
			if _dialog:
				_dialog.hide_dialog()
		NSOp.DNC: # Dialog name clear:
			if _dialog:
				_dialog.clear_name()
		NSOp.DND: # Dialog name display:
			if _dialog:
				_dialog.display_name(op.txt)
		NSOp.DGM: # Dialog message:
			if _dialog:
				_await(_dialog, "message_finished")
				_dialog.display_message(op.txt)
		NSOp.MNO: # Menu option:
			_machine.option_pointers.push_back(op.val)
			_machine.option_texts.push_back(op.txt)
		NSOp.MNS: # Menu show:
			if _machine.option_pointers.empty():
				_pop_machine()
				return
			
			_machine.active_option_pointers = _machine.option_pointers.duplicate()
			_machine.option_pointers.clear()
			
			if _dialog:
				_await_option()
				_dialog.display_options(_machine.option_texts)
			
			_machine.option_texts.clear()
		NSOp.LAK: # Load actor key:
			_machine.actor_key = op.txt
		NSOp.AFD: # Actor face direction:
			var actor: Actor = _get_scripted_actor(_machine.actor_key)
			
			if actor:
				actor.smooth_pivot.pivot_to(deg2rad(float(_machine.x)))
		NSOp.APF: # Actor path find:
			var actor: Actor = _get_scripted_actor(_machine.actor_key)
			
			if actor:
				actor.find_nav_path_point(op.txt)
				_machine.pathing_actors.push_back(actor)
		NSOp.APR: # Actor path run:
			for actor in _machine.pathing_actors:
				if actor:
					actor.run_nav_path()
		NSOp.APA: # Actor path await:
			for i in range(_machine.pathing_actors.size() - 1, -1, -1):
				if not _machine.pathing_actors[i] or not _machine.pathing_actors[i].is_pathing():
					_machine.pathing_actors.remove(i)
			
			if not _machine.pathing_actors.empty():
				_machine.pc -= 1
		NSOp.PLF: # Player freeze:
			Global.events.emit_signal("player_freeze_request")
		NSOp.PLT: # Player thaw:
			Global.events.emit_signal("player_thaw_request")
		NSOp.QTT: # Quit to title:
			_pop_machine()
			Global.change_scene("title")
		NSOp.PSE: # Pause:
			Global.tree.paused = true
		NSOp.UNP: # Unpause:
			Global.tree.paused = false
		NSOp.SAV: # Save:
			Global.save.save_game()
		NSOp.CKP: # Checkpoint:
			Global.save.save_checkpoint()


# Signal callback for an awaited signal. Runs when the awaited signal is
# received. Resumes the NightScript interpreter if it is awaiting:
func _on_await_finished() -> void:
	if _state == State.AWAITING:
		_state = State.RUNNING


# Signal callback for option_pressed on the dialog. Runs when a dialog option is
# pressed. Branches and resumes the NightScript interpreter if it is awaiting:
func _on_dialog_option_pressed(index: int) -> void:
	if _state != State.AWAITING:
		return
	
	if index < 0 or index >= _machine.active_option_pointers.size():
		index = _machine.active_option_pointers.size() - 1
	
	_machine.pc = _machine.active_option_pointers[index]
	_machine.active_option_pointers.clear()
	_state = State.RUNNING


# Signal callback for locale_changed on the language manager. Runs when the
# locale changes. Flushes the NightScript bytecode cache:
func _on_lang_locale_changed(_locale: String) -> void:
	flush_cache()
