class_name NightScript
extends Node

# NightScript Component
# A NightScript component is a component that handles NightScript functionality.

class NightScriptVirtualMachine extends Reference:
	
	# NightScript Virtual Machine
	# A NightScript virtual machine is a structure used by a NightScript
	# component that contains a NightScript program's state.
	
	signal push_machine(program_key)
	signal pop_machine
	
	var is_repeat: bool
	var is_pausable: bool
	var is_awaiting: bool = false
	var string_table: PoolStringArray = PoolStringArray()
	var memory: StreamPeerBuffer = StreamPeerBuffer.new()
	var stack: Array = []
	var frame_pointer: int = 0
	var option_pointers: Array = []
	var option_texts: Array = []
	var pathing_actors: Array = []
	var sleep_timer: float = 0.0
	
	# Deserialize the NightScript virtual machine from its thread ID, whether
	# the NightScript program is a repeat, and NightScript bytecode.
	func _init(is_repeat_val: bool, bytecode: PoolByteArray) -> void:
		is_repeat = is_repeat_val
		
		var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
		buffer.put_data(bytecode) # warning-ignore: RETURN_VALUE_DISCARDED
		buffer.seek(1) # Skip magic number.
		
		is_pausable = bool(buffer.get_u8())
		
		var string_count: int = buffer.get_u32()
		string_table.resize(string_count)
		
		for i in range(string_count):
			string_table[i] = buffer.get_data(buffer.get_u32())[1].get_string_from_utf8()
		
		# warning-ignore: RETURN_VALUE_DISCARDED
		memory.put_data(buffer.get_data(buffer.get_u32())[1])
		memory.seek(0)
	
	
	# Get an actor in the scripted state from its key.
	func get_scripted_actor(actor_key: String) -> Actor:
		for actor in Global.tree.get_nodes_in_group("actors"):
			if actor.actor_key == actor_key and actor.state_machine.get_key() == "Scripted":
				return actor
		
		return null
	
	
	# Step the NightScript virtual machine.
	func step() -> void:
		match memory.get_u8():
			HALT:
				is_awaiting = true
				emit_signal("pop_machine")
			RUN_PROGRAM:
				Global.events.emit_signal("nightscript_run_program_request", stack.pop_back())
			CALL_PROGRAM:
				is_awaiting = true
				emit_signal("push_machine", stack.pop_back())
			SLEEP:
				sleep_timer = float(stack.pop_back()) * 0.001
			JUMP:
				memory.seek(stack.pop_back())
			JUMP_ZERO:
				var jump_address: int = stack.pop_back()
				
				if stack.pop_back() == 0:
					memory.seek(jump_address)
			JUMP_NOT_ZERO:
				var jump_address: int = stack.pop_back()
				
				if stack.pop_back() != 0:
					memory.seek(jump_address)
			CALL_FUNCTION:
				var call_address: int = stack.pop_back()
				var argument_count: int = stack.pop_back()
				var arguments: Array = []
				
				for _i in range(argument_count):
					arguments.push_front(stack.pop_back())
				
				stack.push_back(memory.get_position())
				stack.push_back(frame_pointer)
				
				memory.seek(call_address)
				frame_pointer = stack.size()
				
				for argument in arguments:
					stack.push_back(argument)
			RETURN_FROM_FUNCTION:
				if frame_pointer <= 0:
					is_awaiting = true
					emit_signal("pop_machine")
					return
				
				var return_value = stack.pop_back()
				stack.resize(frame_pointer)
				
				frame_pointer = stack.pop_back()
				memory.seek(stack.pop_back())
				stack.push_back(return_value)
			DROP:
				stack.remove(stack.size() - 1)
			DUPLICATE:
				stack.push_back(stack[-1])
			PUSH_IS_REPEAT:
				stack.push_back(int(is_repeat))
			PUSH_INT:
				stack.push_back(memory.get_32())
			PUSH_STRING:
				stack.push_back(string_table[memory.get_32()])
			LOAD_LOCAL:
				var offset: int = stack.pop_back()
				stack.push_back(stack[frame_pointer + offset])
			STORE_LOCAL:
				var offset: int = stack.pop_back()
				stack[frame_pointer + offset] = stack[-1]
			LOAD_FLAG:
				var key: String = stack.pop_back()
				var namespace: String = stack.pop_back()
				stack.push_back(Global.save.get_working_data().get_flag(namespace, key))
			STORE_FLAG:
				var key: String = stack.pop_back()
				var namespace: String = stack.pop_back()
				Global.save.get_working_data().set_flag(namespace, key, stack[-1])
			UNARY_NEGATE:
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
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(right != 0 and left != 0))
			BINARY_OR:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left != 0 or right != 0))
			FORMAT_STRING:
				var value_count: int = stack.pop_back()
				var values: Array = []
				
				for _i in range(value_count):
					values.push_front(stack.pop_back())
				
				var format_string: String = stack.pop_back()
				stack.push_back(format_string.format(values))
			SHOW_DIALOG:
				Global.events.emit_signal("dialog_show_dialog_request")
			HIDE_DIALOG:
				Global.events.emit_signal("dialog_hide_dialog_request")
			CLEAR_DIALOG_NAME:
				Global.events.emit_signal("dialog_clear_name_request")
			DISPLAY_DIALOG_NAME:
				Global.events.emit_signal("dialog_display_name_request", stack.pop_back())
			DISPLAY_DIALOG_MESSAGE:
				is_awaiting = true
				Global.events.emit_signal("dialog_display_message_request", stack.pop_back())
				
				if Global.events.connect(
						"dialog_message_finished", self, "end_await", [], CONNECT_ONESHOT) != OK:
					if Global.events.is_connected("dialog_message_finished", self, "end_await"):
						Global.events.disconnect("dialog_message_finished", self, "end_await")
					
					is_awaiting = true
					emit_signal("pop_machine")
			STORE_DIALOG_MENU_OPTION:
				var pointer: int = stack.pop_back()
				var text: String = stack.pop_back()
				option_pointers.push_back(pointer)
				option_texts.push_back(text)
			SHOW_DIALOG_MENU:
				if option_pointers.empty():
					is_awaiting = true
					emit_signal("pop_machine")
					return
				
				if Global.events.connect("dialog_option_pressed", self, "select_option", [], CONNECT_ONESHOT) != OK:
					if Global.events.is_connected("dialog_option_pressed", self, "select_option"):
						Global.events.disconnect("dialog_option_pressed", self, "select_option")
					
					is_awaiting = true
					emit_signal("pop_machine")
					return
				
				is_awaiting = true
				Global.events.emit_signal(
						"dialog_display_options_request", PoolStringArray(option_texts))
			ACTOR_FACE_DIRECTION:
				var degrees: int = stack.pop_back()
				var key: String = stack.pop_back()
				var actor: Actor = get_scripted_actor(key)
				
				if actor:
					actor.smooth_pivot.pivot_to(deg2rad(float(degrees)))
			ACTOR_FIND_PATH:
				var point: String = stack.pop_back()
				var key: String = stack.pop_back()
				var actor: Actor = get_scripted_actor(key)
				
				if actor:
					actor.find_nav_path_point(point)
					pathing_actors.push_back(actor)
			RUN_ACTOR_PATHS:
				for actor in pathing_actors:
					if actor:
						actor.run_nav_path()
			AWAIT_ACTOR_PATHS:
				for i in range(pathing_actors.size() - 1, - 1, -1):
					var actor: Actor = pathing_actors[i]
					
					if not actor or not actor.is_pathing():
						pathing_actors.remove(i)
				
				if not pathing_actors.empty():
					memory.seek(memory.get_position() - 1)
			FREEZE_PLAYER:
				Global.events.emit_signal("player_freeze_request")
			THAW_PLAYER:
				Global.events.emit_signal("player_thaw_request")
			QUIT_TO_TITLE:
				is_awaiting = true
				Global.change_scene("menu")
			PAUSE_GAME:
				Global.tree.paused = true
			UNPAUSE_GAME:
				Global.tree.paused = false
			SAVE_GAME:
				Global.save.save_game()
			SAVE_CHECKPOINT:
				Global.save.save_checkpoint()
	
	
	# End the awaiting state.
	func end_await() -> void:
		is_awaiting = false
	
	
	# Select a dialog option.
	func select_option(index: int) -> void:
		if not is_awaiting or option_pointers.empty():
			emit_signal("pop_machine")
			return
		
		if index < 0 or index >= option_pointers.size():
			index = 0
		
		memory.seek(option_pointers[index])
		option_pointers.clear()
		option_texts.clear()
		is_awaiting = false


enum {
	HALT = 0x00,
	RUN_PROGRAM = 0x01,
	CALL_PROGRAM = 0x02,
	SLEEP = 0x03,
	JUMP = 0x04,
	JUMP_ZERO = 0x05,
	JUMP_NOT_ZERO = 0x06,
	CALL_FUNCTION = 0x07,
	RETURN_FROM_FUNCTION = 0x08,
	DROP = 0x09,
	DUPLICATE = 0x0a,
	PUSH_IS_REPEAT = 0x0b,
	PUSH_INT = 0x0c,
	PUSH_STRING = 0x0d,
	LOAD_LOCAL = 0x0e,
	STORE_LOCAL = 0x0f,
	LOAD_FLAG = 0x10,
	STORE_FLAG = 0x11,
	UNARY_NEGATE = 0x12,
	UNARY_NOT = 0x13,
	BINARY_ADD = 0x14,
	BINARY_SUBTRACT = 0x15,
	BINARY_MULTIPLY = 0x16,
	BINARY_EQUALS = 0x17,
	BINARY_NOT_EQUALS = 0x18,
	BINARY_GREATER = 0x19,
	BINARY_GREATER_EQUALS = 0x1a,
	BINARY_LESS = 0x1b,
	BINARY_LESS_EQUALS = 0x1c,
	BINARY_AND = 0x1d,
	BINARY_OR = 0x1e,
	FORMAT_STRING = 0x1f,
	SHOW_DIALOG = 0x20,
	HIDE_DIALOG = 0x21,
	CLEAR_DIALOG_NAME = 0x22,
	DISPLAY_DIALOG_NAME = 0x23,
	DISPLAY_DIALOG_MESSAGE = 0x24,
	STORE_DIALOG_MENU_OPTION = 0x25,
	SHOW_DIALOG_MENU = 0x26,
	ACTOR_FACE_DIRECTION = 0x27,
	ACTOR_FIND_PATH = 0x28,
	RUN_ACTOR_PATHS = 0x29,
	AWAIT_ACTOR_PATHS = 0x2a,
	FREEZE_PLAYER = 0x2b,
	THAW_PLAYER = 0x2c,
	QUIT_TO_TITLE = 0x2d,
	PAUSE_GAME = 0x2e,
	UNPAUSE_GAME = 0x2f,
	SAVE_GAME = 0x30,
	SAVE_CHECKPOINT = 0x31,
}

const THREAD_LIMIT: int = 16
const RUN_STEP_LIMIT: int = 16
const BYTECODE_MAGIC: int = 0xfe
const EMPTY_BYTECODE: PoolByteArray = PoolByteArray([
	BYTECODE_MAGIC, # 0xfe - Illegal UTF-8 byte, file is not text.
	0x00, # Don't stop on pause.
	0x00, 0x00, 0x00, 0x00, # 0 strings.
	0x01, 0x00, 0x00, 0x00, # 1 byte.
	HALT, # Halt.
])

var _is_caching: bool = true
var _program_cache: Dictionary = {}
var _threads: Array = []

# Run when the NightScript component enters the scene tree. Disable the physics
# process and connect to the event bus and language manager.
func _ready() -> void:
	set_physics_process(false)
	Global.events.safe_connect("nightscript_run_program_request", self, "run_program")
	Global.events.safe_connect("nightscript_stop_programs_request", self, "stop_programs")
	Global.events.safe_connect("nightscript_cache_program_request", self, "cache_program")
	Global.events.safe_connect("nightscript_flush_cache_request", self, "flush_cache")
	
	var error: int = Global.lang.connect("locale_changed", self, "flush_cache")
	
	if error:
		if Global.lang.is_connected("locale_changed", self, "flush_cache"):
			Global.lang.disconnect("locale_changed", self, "flush_cache")
		
		_is_caching = false


# Run on every physics frame. Step the NightScript component.
func _physics_process(delta: float) -> void:
	for thread in _threads:
		if thread.empty():
			continue
		
		var vm: NightScriptVirtualMachine = thread[-1]
		
		if vm.is_awaiting or vm.is_pausable and Global.tree.paused:
			continue
		
		if vm.sleep_timer > 0.0:
			vm.sleep_timer -= delta
			continue
		
		var steps: int = RUN_STEP_LIMIT
		
		while steps > 0:
			if vm.is_awaiting or vm.sleep_timer > 0.0 or vm.is_pausable and Global.tree.paused:
				break
			
			steps -= 1
			vm.step()


# Run when the NightScript component exits the scene tree. Disconnect the
# NightScript component from the event bus and language manager.
func _exit_tree() -> void:
	if Global.lang.is_connected("locale_changed", self, "flush_cache"):
		Global.lang.disconnect("locale_changed", self, "flush_cache")
	
	Global.events.safe_disconnect("nightscript_flush_cache_request", self, "flush_cache")
	Global.events.safe_disconnect("nightscript_cache_program_request", self, "cache_program")
	Global.events.safe_disconnect("nightscript_stop_programs_request", self, "stop_programs")
	Global.events.safe_disconnect("nightscript_run_program_request", self, "run_program")
	stop_programs()


# Run a NightScript program in an available NightScript thread.
func run_program(program_key: String) -> void:
	var thread_index: int = _threads.size()
	
	if thread_index < THREAD_LIMIT:
		_threads.push_back([])
	else:
		for i in range(THREAD_LIMIT):
			if _threads[i].empty():
				thread_index = i
				break
		
		if thread_index >= THREAD_LIMIT:
			return # All threads are busy.
	
	if _threads.size() >= THREAD_LIMIT:
		return
	
	_push_thread(program_key, thread_index)


# Forcibly stop all NightScript programs.
func stop_programs() -> void:
	while not _threads.empty():
		for thread_index in range(_threads.size()):
			_pop_thread(thread_index)
		
		while not _threads.empty() and _threads[-1].empty():
			_threads.pop_back()


# Cache a NightScript program from its program key.
func cache_program(program_key: String) -> void:
	if not _is_caching or _program_cache.has(program_key):
		return
	
	_program_cache[program_key] = _get_bytecode(program_key)


# Flush the NightScript program cache.
func flush_cache() -> void:
	_program_cache.clear()


# Get a NightScript program's bytecode from its program key.
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


# Push a thread thread from its index.
func _push_thread(program_key: String, thread_index: int) -> void:
	var bytecode: PoolByteArray = _get_bytecode(program_key)
	
	if _is_caching and not _program_cache.has(program_key):
		_program_cache[program_key] = bytecode
	
	var vm: NightScriptVirtualMachine = NightScriptVirtualMachine.new(
			Global.save.get_working_data().get_flag("ns_repeat", program_key) != 0, bytecode)
	Global.save.get_working_data().set_flag("ns_repeat", program_key, 1)
	
	if vm.connect("push_machine", self, "_push_thread", [thread_index]) != OK:
		if vm.is_connected("push_machine", self, "_push_thread"):
			vm.disconnect("push_machine", self, "_push_thread")
	
	if vm.connect("pop_machine", self, "_pop_thread", [thread_index]) != OK:
		if vm.is_connected("pop_machine", self, "_pop_thread"):
			vm.disconnect("pop_machine", self, "_pop_thread")
	
	_threads[thread_index].push_back(vm)
	set_physics_process(true)


# Pop a thread from its index.
func _pop_thread(thread_index: int) -> void:
	if thread_index < 0 or thread_index >= _threads.size() or _threads[thread_index].empty():
		return
	
	var vm: NightScriptVirtualMachine = _threads[thread_index].pop_back()
	
	if vm.is_connected("push_machine", self, "_call_program"):
		vm.disconnect("push_machine", self, "_call_program")
	
	if vm.is_connected("pop_machine", self, "_pop_thread"):
		vm.disconnect("pop_machine", self, "_pop_thread")
	
	if _threads[thread_index].empty():
		Global.events.emit_signal("nightscript_thread_finished")
	else:
		_threads[thread_index][-1].end_await()
	
	while not _threads.empty() and _threads[-1].empty():
		_threads.pop_back()
	
	if _threads.empty():
		set_physics_process(false)
