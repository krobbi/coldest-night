class_name NightScript
extends Node

# NightScript Component
# A NightScript component is a component that handles NightScript functionality.

class NSOp extends Object:
	
	# NightScript Operation
	# A NightScript operation is a helper structure used by a NightScript
	# component that represents an operation that can be performed by a
	# NightScript component.
	
	var opcode: int
	var operand: int = 0
	
	# Sets the NightScript operation's opcode.
	func _init(opcode_val: int) -> void:
		opcode = opcode_val


class NSMachine extends Object:
	
	# NightScript Machine
	# A NightScript machine is a helper structure used by a NightScript
	# component that contains a NightScript program's properties, operations,
	# and registers.
	
	var is_seen: bool
	var is_pausable: bool
	var string_table: PoolStringArray = PoolStringArray()
	var ops: Array = []
	var pc: int
	var option_pointers: Array = []
	var option_texts: Array = []
	var pathing_actors: Array = []
	
	# Constructor. Deserializes the NightScript machine from a NightScript
	# program's bytecode and whether the NightScript program has already been
	# run:
	func _init(bytecode: PoolByteArray, is_seen_val: bool) -> void:
		is_seen = is_seen_val
		
		var stream: SerialReadStream = SerialReadStream.new(bytecode)
		stream.jump(1) # Skip magic number.
		
		is_pausable = bool(stream.get_u8())
		
		var string_count: int = stream.get_u32()
		string_table.resize(string_count)
		
		for i in range(string_count):
			string_table[i] = stream.get_utf8_u32()
		
		var op_count: int = stream.get_u32()
		ops.resize(op_count)
		
		for i in range(op_count):
			var op: NSOp = NSOp.new(stream.get_u8())
			
			if op.opcode == PUSH_INT or op.opcode == PUSH_STRING:
				op.operand = stream.get_s32()
			
			ops[i] = op
	
	
	# Destructor. Frees the NightScript machine's NightScript operations:
	func destruct() -> void:
		for op in ops:
			op.free()


class NSThread extends Object:
	
	# NightScript Thread
	# A NightScript thread is a helper structure used by a NightScript component
	# that represents a thread of NightScript execution and contains a stack of
	# NightScript machines.
	
	signal call_program_request(program_key)
	
	enum State {STOPPED, RUNNING, AWAITING, SLEEPING}
	
	const MACHINE_STACK_LIMIT: int = 16
	
	var state: int = State.RUNNING
	var sleep_timer: float = 0.0
	var machine_stack: Array = []
	var machine: NSMachine = null
	var stack: Array = []
	
	# Sets a flag from its namespace and key:
	func set_flag(namespace: String, key: String, value: int) -> void:
		Global.save.get_working_data().set_flag(namespace, key, value)
	
	
	# Gets a flag from its namespace and key:
	func get_flag(namespace: String, key: String) -> int:
		return Global.save.get_working_data().get_flag(namespace, key)
	
	
	# Pushes a new current NightScript machine to the NightScript thread from a
	# NightScript program's bytecode and whether the NightScript program has
	# already been run:
	func push_machine(bytecode: PoolByteArray, is_seen: bool) -> void:
		if machine_stack.size() >= MACHINE_STACK_LIMIT:
			return
		
		machine = NSMachine.new(bytecode, is_seen)
		machine_stack.push_back(machine)
	
	
	# Pops the current NightScript machine from the NightScript thread:
	func pop_machine() -> void:
		if not machine:
			return
		
		machine.destruct()
		machine.free()
		machine_stack.remove(machine_stack.size() - 1)
		
		if machine_stack.empty():
			machine = null
			state = State.STOPPED
		else:
			machine = machine_stack[-1]
	
	
	# Pauses the NightScript thread until a signal is emitted from a source
	# object:
	func await(source: Object, signal_name: String) -> void:
		if state != State.RUNNING:
			return
		
		var error: int = source.connect(
				signal_name, self, "_on_await_finished", [], CONNECT_ONESHOT
		)
		
		if not error:
			state = State.AWAITING
		elif source.is_connected(signal_name, self, "_on_await_finished"):
			source.disconnect(signal_name, self, "_on_await_finished")
	
	
	# Steps the NightScript thread:
	func step() -> void:
		var op: NSOp = machine.ops[machine.pc]
		machine.pc += 1
		
		match op.opcode:
			HALT:
				pop_machine()
			RUN_PROGRAM:
				Global.events.emit_signal("nightscript_run_program_request", stack.pop_back())
			CALL_PROGRAM:
				emit_signal("call_program_request", stack.pop_back())
			SLEEP:
				sleep_timer = float(stack.pop_back()) * 0.001
				state = State.SLEEPING
			JUMP:
				machine.pc = stack.pop_back()
			JUMP_ZERO:
				var jump_address: int = stack.pop_back()
				
				if stack.pop_back() == 0:
					machine.pc = jump_address
			JUMP_NOT_ZERO:
				var jump_address: int = stack.pop_back()
				
				if stack.pop_back() != 0:
					machine.pc = jump_address
			DROP:
				stack.remove(stack.size() - 1)
			DUPLICATE:
				stack.push_back(stack[-1])
			PUSH_IS_REPEAT:
				stack.push_back(int(machine.is_seen))
			PUSH_INT:
				stack.push_back(op.operand)
			PUSH_STRING:
				stack.push_back(machine.string_table[op.operand])
			LOAD_FLAG:
				var key: String = stack.pop_back()
				var namespace: String = stack.pop_back()
				stack.push_back(get_flag(namespace, key))
			STORE_FLAG:
				var key: String = stack.pop_back()
				var namespace: String = stack.pop_back()
				set_flag(namespace, key, stack[-1])
			UNARY_NEGATE: # Negate:
				stack.push_back(-stack.pop_back())
			UNARY_NOT:
				stack.push_back(int(stack.pop_back() == 0))
			BINARY_ADD:
				stack.push_back(stack.pop_back() + stack.pop_back())
			BINARY_SUBTRACT:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(left - right)
			BINARY_MULTIPLY:
				stack.push_back(stack.pop_back() * stack.pop_back())
			BINARY_EQUALS:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left == right))
			BINARY_NOT_EQUALS:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left != right))
			BINARY_GREATER:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left > right))
			BINARY_GREATER_EQUALS:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left >= right))
			BINARY_LESS:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left < right))
			BINARY_LESS_EQUALS:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left <= right))
			BINARY_AND:
				stack.push_back(int(stack.pop_back() != 0 and stack.pop_back() != 0))
			BINARY_OR:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left != 0 or right != 0))
			SHOW_DIALOG:
				Global.events.emit_signal("dialog_show_dialog_request")
			HIDE_DIALOG:
				Global.events.emit_signal("dialog_hide_dialog_request")
			CLEAR_DIALOG_NAME:
				Global.events.emit_signal("dialog_clear_name_request")
			DISPLAY_DIALOG_NAME:
				Global.events.emit_signal("dialog_display_name_request", stack.pop_back())
			DISPLAY_DIALOG_MESSAGE:
				await(Global.events, "dialog_message_finished")
				Global.events.emit_signal("dialog_display_message_request", stack.pop_back())
			STORE_DIALOG_MENU_OPTION:
				var pointer: int = stack.pop_back()
				var text: String = stack.pop_back()
				machine.option_pointers.push_back(pointer)
				machine.option_texts.push_back(text)
			SHOW_DIALOG_MENU:
				if machine.option_pointers.empty():
					pop_machine()
					return
				
				var error: int = Global.events.connect(
						"dialog_option_pressed", self,
						"_on_dialog_option_pressed", [], CONNECT_ONESHOT
				)
				
				if error:
					if Global.events.is_connected(
							"dialog_option_pressed", self, "_on_dialog_option_pressed"
					):
						Global.events.disconnect(
								"dialog_option_pressed", self, "_on_dialog_option_pressed"
						)
					
					pop_machine()
					return
				
				state = State.AWAITING
				Global.events.emit_signal(
						"dialog_display_options_request", PoolStringArray(machine.option_texts)
				)
			ACTOR_FACE_DIRECTION:
				var degrees: int = stack.pop_back()
				var key: String = stack.pop_back()
				var actor: Actor = _get_scripted_actor(key)
				
				if actor:
					actor.smooth_pivot.pivot_to(deg2rad(float(degrees)))
			ACTOR_FIND_PATH:
				var point: String = stack.pop_back()
				var key: String = stack.pop_back()
				var actor: Actor = _get_scripted_actor(key)
				
				if actor:
					actor.find_nav_path_point(point)
					machine.pathing_actors.push_back(actor)
			RUN_ACTOR_PATHS:
				for actor in machine.pathing_actors:
					if actor:
						actor.run_nav_path()
			AWAIT_ACTOR_PATHS:
				for i in range(machine.pathing_actors.size() - 1, - 1, -1):
					var actor: Actor = machine.pathing_actors[i]
					
					if not actor or not actor.is_pathing():
						machine.pathing_actors.remove(i)
				
				if not machine.pathing_actors.empty():
					machine.pc -= 1
			FREEZE_PLAYER:
				Global.events.emit_signal("player_freeze_request")
			THAW_PLAYER:
				Global.events.emit_signal("player_thaw_request")
			QUIT_TO_TITLE:
				state = State.STOPPED
				Global.change_scene("menu")
			PAUSE_GAME:
				Global.tree.paused = true
			UNPAUSE_GAME:
				Global.tree.paused = false
			SAVE_GAME:
				Global.save.save_game()
			SAVE_CHECKPOINT:
				Global.save.save_checkpoint()
	
	
	# Gets a scripted actor from its actor key. Returns null if the scripted
	# actor is unavailable:
	func _get_scripted_actor(actor_key: String) -> Actor:
		for actor in Global.tree.get_nodes_in_group("actors"):
			if actor.actor_key == actor_key and actor.state_machine.get_key() == "Scripted":
				return actor
		
		return null
	
	
	# Signal callback for an awaited signal. Runs when the awaited signal is
	# emitted. Resumes the NightScript thread:
	func _on_await_finished() -> void:
		if state == State.AWAITING:
			state = State.RUNNING
	
	
	# Callback for pressing an option on the dialog display. Branches and
	# resumes the NightScript thread if it is awaiting a menu option:
	func _on_dialog_option_pressed(index: int) -> void:
		if state != State.AWAITING:
			return
		
		if index < 0 or index >= machine.option_pointers.size():
			index = machine.option_pointers.size() - 1
		
		machine.pc = machine.option_pointers[index]
		machine.option_pointers.clear()
		machine.option_texts.clear()
		state = State.RUNNING
	
	
	# Destructor. Destructs and frees the NightScript thread's NightScript
	# machines:
	func destruct() -> void:
		for stack_machine in machine_stack:
			stack_machine.destruct()
			stack_machine.free()

enum {
	HALT = 0x00,
	RUN_PROGRAM = 0x01,
	CALL_PROGRAM = 0x02,
	SLEEP = 0x03,
	JUMP = 0x04,
	JUMP_ZERO = 0x05,
	JUMP_NOT_ZERO = 0x06,
	DROP = 0x07,
	DUPLICATE = 0x08,
	PUSH_IS_REPEAT = 0x09,
	PUSH_INT = 0x0a,
	PUSH_STRING = 0x0b,
	LOAD_FLAG = 0x0c,
	STORE_FLAG = 0x0d,
	UNARY_NEGATE = 0x0e,
	UNARY_NOT = 0x0f,
	BINARY_ADD = 0x10,
	BINARY_SUBTRACT = 0x11,
	BINARY_MULTIPLY = 0x12,
	BINARY_EQUALS = 0x13,
	BINARY_NOT_EQUALS = 0x14,
	BINARY_GREATER = 0x15,
	BINARY_GREATER_EQUALS = 0x16,
	BINARY_LESS = 0x17,
	BINARY_LESS_EQUALS = 0x18,
	BINARY_AND = 0x19,
	BINARY_OR = 0x1a,
	SHOW_DIALOG = 0x1b,
	HIDE_DIALOG = 0x1c,
	CLEAR_DIALOG_NAME = 0x1d,
	DISPLAY_DIALOG_NAME = 0x1e,
	DISPLAY_DIALOG_MESSAGE = 0x1f,
	STORE_DIALOG_MENU_OPTION = 0x20,
	SHOW_DIALOG_MENU = 0x21,
	ACTOR_FACE_DIRECTION = 0x22,
	ACTOR_FIND_PATH = 0x23,
	RUN_ACTOR_PATHS = 0x24,
	AWAIT_ACTOR_PATHS = 0x25,
	FREEZE_PLAYER = 0x26,
	THAW_PLAYER = 0x27,
	QUIT_TO_TITLE = 0x28,
	PAUSE_GAME = 0x29,
	UNPAUSE_GAME = 0x2a,
	SAVE_GAME = 0x2b,
	SAVE_CHECKPOINT = 0x2c,
}

const THREAD_LIMIT: int = 16
const RUN_STEP_LIMIT: int = 32
const BYTECODE_MAGIC: int = 0xfe
const EMPTY_BYTECODE: PoolByteArray = PoolByteArray([
	BYTECODE_MAGIC, # 0xfe - Illegal UTF-8 byte, file is not text.
	0x00, # Don't stop on pause.
	0x00, 0x00, 0x00, 0x00, # 0 strings.
	0x01, 0x00, 0x00, 0x00, # 1 operation.
	HALT, # Halt.
])

var _is_caching: bool = true
var _program_cache: Dictionary = {}
var _threads: Array = []

# Virtual _ready method. Runs when the NightScript component enters the scene
# tree. Disables the NightScript component's physics process and connects the
# NightScript component to the event bus and language manager:
func _ready() -> void:
	set_physics_process(false)
	Global.events.safe_connect("nightscript_run_program_request", self, "run_program")
	Global.events.safe_connect("nightscript_stop_programs_request", self, "stop_programs")
	Global.events.safe_connect("nightscript_cache_program_request", self, "cache_program")
	Global.events.safe_connect("nightscript_flush_cache_request", self, "flush_cache")
	
	var error: int = Global.lang.connect("locale_changed", self, "_on_lang_locale_changed")
	
	if error:
		if Global.lang.is_connected("locale_changed", self, "_on_lang_locale_changed"):
			Global.lang.disconnect("locale_changed", self, "_on_lang_locale_changed")
		
		_is_caching = false


# Virtual _physics process. Runs on every physics frame. Steps the NightScript
# component:
func _physics_process(delta: float) -> void:
	for i in range(_threads.size() - 1, -1, -1):
		var thread: NSThread = _threads[i]
		
		if thread.machine.is_pausable and Global.tree.paused:
			continue
		
		if thread.state == NSThread.State.SLEEPING:
			thread.sleep_timer -= delta
			
			if thread.sleep_timer <= 0.0:
				thread.state = NSThread.State.RUNNING
		
		var steps: int = RUN_STEP_LIMIT
		
		while thread.state == NSThread.State.RUNNING and steps:
			thread.step()
			steps -= 1
		
		if thread.state == NSThread.State.STOPPED:
			if thread.is_connected("call_program_request", self, "_call_program"):
				thread.disconnect("call_program_request", self, "_call_program")
			
			thread.destruct()
			thread.free()
			_threads.remove(i)
			
			if _threads.empty():
				set_physics_process(false)
			
			Global.events.emit_signal("nightscript_thread_finished")


# Virtual _exit_tree method. Runs when the NightScript component exits the scene
# tree. Disconnects the NightScript component from the event bus and language
# manager:
func _exit_tree() -> void:
	if Global.lang.is_connected("locale_changed", self, "_on_lang_locale_changed"):
		Global.lang.disconnect("locale_changed", self, "_on_lang_locale_changed")
	
	Global.events.safe_disconnect("nightscript_flush_cache_request", self, "flush_cache")
	Global.events.safe_disconnect("nightscript_cache_program_request", self, "cache_program")
	Global.events.safe_disconnect("nightscript_stop_programs_request", self, "stop_programs")
	Global.events.safe_disconnect("nightscript_run_program_request", self, "run_program")
	stop_programs()


# Runs a NightScript program in a new NightScript thread:
func run_program(program_key: String) -> void:
	if _threads.size() >= THREAD_LIMIT:
		return
	
	var thread: NSThread = NSThread.new()
	var error: int = thread.connect("call_program_request", self, "_call_program", [thread])
	
	if error and thread.is_connected("call_program_request", self, "_call_program"):
		thread.disconnect("call_program_request", self, "_call_program")
	
	_call_program(program_key, thread)
	var steps: int = RUN_STEP_LIMIT
	
	while thread.state == NSThread.State.RUNNING and steps:
		thread.step()
		steps -= 1
	
	if thread.state == NSThread.State.STOPPED:
		if thread.is_connected("call_program_request", self, "_call_program"):
			thread.disconnect("call_program_request", self, "_call_program")
		
		thread.destruct()
		thread.free()
		Global.events.emit_signal("nightscript_thread_finished")
	else:
		_threads.push_back(thread)
		set_physics_process(true)


# Forcibly stops all NightScript programs:
func stop_programs() -> void:
	set_physics_process(false)
	
	for thread in _threads:
		if thread.is_connected("call_program_request", self, "_call_program"):
			thread.disconnect("call_program_request", self, "_call_program")
		
		thread.destruct()
		thread.free()
	
	_threads.clear()


# Caches a NightScript program from its program key if it is cacheable:
func cache_program(program_key: String) -> void:
	if not _is_caching or _program_cache.has(program_key):
		return
	
	_program_cache[program_key] = _get_bytecode(program_key)


# Flushes the NightScript program cache:
func flush_cache() -> void:
	_program_cache.clear()


# Gets a NightScript program's bytecode from its program key:
func _get_bytecode(program_key: String) -> PoolByteArray:
	if _program_cache.has(program_key):
		return _program_cache[program_key]
	
	var file: File = File.new()
	var path: String = "res://resources/data/nightscript/%s.%s.ns" % [
			program_key, Global.lang.get_locale()]
	
	if not file.file_exists(path):
		path = "res://resources/data/nightscript/%s.ns" % program_key
		
		if not file.file_exists(path):
			path = "res://resources/data/nightscript/%s.%s.ns" % [
					program_key, Global.lang.get_default_locale()]
			
			if not file.file_exists(path):
				return EMPTY_BYTECODE
	
	if file.open(path, File.READ) == OK:
		var bytes: PoolByteArray = file.get_buffer(file.get_len())
		file.close()
		
		if not bytes.empty() and bytes[0] == BYTECODE_MAGIC:
			return bytes
	else:
		if file.is_open():
			file.close()
		
		return EMPTY_BYTECODE
	
	if OS.is_debug_build():
		var compiler: Reference = load("res://utils/nightscript/compiler/ns_compiler.gd").new()
		return compiler.compile_path(Global.lang.get_locale(), path, Global.config.get_bool(
				"debug.optimize_nightscript"))
	
	return EMPTY_BYTECODE


# Calls a NightScript program on top of an existing NightScript thread:
func _call_program(program_key: String, thread: NSThread) -> void:
	var bytecode: PoolByteArray = _get_bytecode(program_key)
	
	if _is_caching and not _program_cache.has(program_key):
		_program_cache[program_key] = bytecode
	
	thread.push_machine(bytecode, bool(thread.get_flag("nightscript_seen", program_key)))
	thread.set_flag("nightscript_seen", program_key, 1)


# Signal callback for locale_changed on the language manager. Runs when the
# locale changes. Flushes the NightScript program cache:
func _on_lang_locale_changed(_locale: String) -> void:
	flush_cache()
