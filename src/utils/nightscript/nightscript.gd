class_name NightScript
extends Node

# NightScript Component
# A NightScript component is a component that handles NightScript functionality.

class NSOp extends Object:
	
	# NightScript Operation
	# A NightScript operation is a helper structure used by a NightScript
	# component that represents an operation that can be performed by a
	# NightScript component.
	
	var op: int
	var val: int
	var txt: String
	var key: String
	
	# Constructor. Sets the NightScript operation's opcode:
	func _init(op_val: int) -> void:
		op = op_val


class NSMachine extends Object:
	
	# NightScript Machine
	# A NightScript machine is a helper structure used by a NightScript
	# component that contains a NightScript program's properties, operations,
	# and registers.
	
	var is_cacheable: bool
	var is_pausable: bool
	var vector_main: int
	var vector_repeat: int
	var ops: Array = []
	var pc: int
	var actor_key: String
	var option_pointers: Array = []
	var option_texts: Array = []
	var pathing_actors: Array = []
	
	# Constructor. Deserializes the NightScript machine from a NightScript
	# program's bytecode and whether the NightScript program has already been
	# run:
	func _init(bytecode: PoolByteArray, is_seen: bool) -> void:
		var stream: SerialReadStream = SerialReadStream.new(bytecode)
		var program_flags: int = stream.get_u8()
		is_cacheable = bool(program_flags & FLAG_CACHEABLE)
		is_pausable = bool(program_flags & FLAG_PAUSABLE)
		vector_main = stream.get_u16()
		vector_repeat = stream.get_u16()
		pc = vector_repeat if is_seen else vector_main
		var string_count: int = stream.get_u16()
		var string_table: PoolStringArray = PoolStringArray()
		string_table.resize(string_count)
		
		for i in range(string_count):
			string_table[i] = stream.get_utf8_u16()
		
		var flag_part_count: int = stream.get_u16()
		var flag_table: PoolIntArray = PoolIntArray()
		flag_table.resize(flag_part_count)
		
		for i in range(flag_part_count):
			flag_table[i] = stream.get_u16()
		
		var op_count: int = stream.get_u16()
		ops.resize(op_count)
		
		for i in range(op_count):
			var opcode: int = stream.get_u8()
			var op: NSOp = NSOp.new(opcode)
			var operands: int = get_operands(opcode)
			
			if operands & OPERAND_VAL:
				op.val = stream.get_s16()
			
			if operands & OPERAND_PTR:
				op.val = stream.get_u16()
			
			if operands & OPERAND_FLG:
				var index: int = stream.get_u16()
				op.txt = string_table[flag_table[index]]
				op.key = string_table[flag_table[index + 1]]
			
			if operands & OPERAND_TXT:
				op.txt = string_table[stream.get_u16()]
			
			ops[i] = op
	
	
	# Destructor. Frees the NightScript machine's NightScript operations:
	func destruct() -> void:
		for op in ops:
			op.free()
	
	
	# Gets a NightScript operand mask from a NightScript opcode:
	static func get_operands(opcode: int) -> int:
		match opcode:
			CLP, RUN, DND, DGM, LAK, APF:
				return OPERAND_TXT
			JMP, BNZ:
				return OPERAND_PTR
			PHC:
				return OPERAND_VAL
			PHF, STF:
				return OPERAND_FLG
			MNO:
				return OPERAND_PTR | OPERAND_TXT
			_:
				return 0


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
		
		match op.op:
			# Control flow:
			HLT: # Halt:
				pop_machine()
			CLP: # Call program:
				emit_signal("call_program_request", op.txt)
			RUN: # Run:
				Global.events.emit_signal("nightscript_run_program_request", op.txt)
			SLP: # Sleep:
				sleep_timer = float(stack.pop_back()) * 0.01
				state = State.SLEEPING
			JMP: # Jump:
				machine.pc = op.val
			BNZ: # Branch not zero:
				if stack.pop_back() != 0:
					machine.pc = op.val
			
			# Stack operations:
			PHC: # Push constant:
				stack.push_back(op.val)
			PHF: # Push flag:
				stack.push_back(get_flag(op.txt, op.key))
			DUP: # Duplicate:
				stack.push_back(stack[-1])
			POP: # Pop:
				stack.remove(stack.size() - 1)
			STF: # Store flag:
				set_flag(op.txt, op.key, stack[-1])
			
			# Stack arithmetic and logic:
			NEG: # Negate:
				stack.push_back(-stack.pop_back())
			ADD: # Add:
				stack.push_back(stack.pop_back() + stack.pop_back())
			SUB: # Subtract:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(left - right)
			MUL: # Multiply:
				stack.push_back(stack.pop_back() * stack.pop_back())
			CEQ: # Compare equals:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left == right))
			CNE: # Compare not equals:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left != right))
			CGT: # Compare greater than:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left > right))
			CGE: # Compare greater equals:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left >= right))
			CLT: # Compare less than:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left < right))
			CLE: # Compare less equals:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left <= right))
			NOT: # Not:
				stack.push_back(int(stack.pop_back() == 0))
			AND: # And:
				stack.push_back(int(stack.pop_back() != 0 and stack.pop_back() != 0))
			LOR: # Logical or:
				var right: int = stack.pop_back()
				var left: int = stack.pop_back()
				stack.push_back(int(left != 0 or right != 0))
			
			# Dialog operations:
			DGS: # Dialog show:
				Global.events.emit_signal("dialog_show_dialog_request")
			DGH: # Dialog hide:
				Global.events.emit_signal("dialog_hide_dialog_request")
			DNC: # Dialog name clear:
				Global.events.emit_signal("dialog_clear_name_request")
			DND: # Dialog name display:
				Global.events.emit_signal("dialog_display_name_request", op.txt)
			DGM: # Dialog message:
				await(Global.events, "dialog_message_finished")
				Global.events.emit_signal("dialog_display_message_request", op.txt)
			MNO: # Menu option:
				machine.option_pointers.push_back(op.val)
				machine.option_texts.push_back(op.txt)
			MNS: # Menu show:
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
			
			# Actor operations:
			LAK: # Load actor key:
				machine.actor_key = op.txt
			AFD: # Actor face direction:
				var actor: Actor = _get_scripted_actor(machine.actor_key)
				
				if actor:
					actor.smooth_pivot.pivot_to(deg2rad(float(stack.pop_back())))
				else:
					stack.remove(stack.size() - 1)
			APF: # Actor path find:
				var actor: Actor = _get_scripted_actor(machine.actor_key)
				
				if actor:
					actor.find_nav_path_point(op.txt)
					machine.pathing_actors.push_back(actor)
			APR: # Actor path run:
				for actor in machine.pathing_actors:
					if actor:
						actor.run_nav_path()
			APA: # Actor path await:
				for i in range(machine.pathing_actors.size() - 1, - 1, -1):
					var actor: Actor = machine.pathing_actors[i]
					
					if not actor or not actor.is_pathing():
						machine.pathing_actors.remove(i)
				
				if not machine.pathing_actors.empty():
					machine.pc -= 1
			PLF: # Player freeze:
				Global.events.emit_signal("player_freeze_request")
			PLT: # Player thaw:
				Global.events.emit_signal("player_thaw_request")
			
			# External operations:
			QTT: # Quit to title:
				state = State.STOPPED
				Global.change_scene("menu")
			PSE: # Pause:
				Global.tree.paused = true
			UNP: # Unpause:
				Global.tree.paused = false
			SAV: # Save:
				Global.save.save_game()
			CKP: # Checkpoint:
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
	# Section 0 - Control flow:
	HLT = 0x00, # Halt.
	CLP = 0x01, # Call program.
	RUN = 0x02, # Run.
	SLP = 0x03, # Sleep.
	JMP = 0x04, # Jump.
	BNZ = 0x05, # Branch not zero.
	
	# Section 1 - Stack operations:
	PHC = 0x10, # Push constant.
	PHF = 0x11, # Push flag.
	DUP = 0x12, # Duplicate.
	POP = 0x13, # Pop.
	STF = 0x14, # Store flag.
	
	# Section 2 - Stack arithmetic and logic:
	NEG = 0x20, # Negate.
	ADD = 0x21, # Add.
	SUB = 0x22, # Subtract.
	MUL = 0x23, # Multiply.
	CEQ = 0x24, # Compare equals.
	CNE = 0x25, # Compare not equals.
	CGT = 0x26, # Compare greater than.
	CGE = 0x27, # Compare greater equals.
	CLT = 0x28, # Compare less than.
	CLE = 0x29, # Compare less equals.
	NOT = 0x2a, # Not.
	AND = 0x2b, # And.
	LOR = 0x2c, # Logical or.
	
	# Section 3 - Dialog operations:
	DGS = 0x30, # Dialog show.
	DGH = 0x31, # Dialog hide.
	DNC = 0x32, # Dialog name clear.
	DND = 0x33, # Dialog name display.
	DGM = 0x34, # Dialog message.
	MNO = 0x35, # Menu option.
	MNS = 0x36, # Menu show.
	
	# Section 4 - Actor operations:
	LAK = 0x40, # Load actor key.
	AFD = 0x41, # Actor face direction.
	APF = 0x42, # Actor path find.
	APR = 0x43, # Actor path run.
	APA = 0x44, # Actor path await.
	PLF = 0x45, # Player freeze.
	PLT = 0x46, # Player thaw.
	
	# Section 5 - External operations:
	QTT = 0x50, # Quit to title.
	PSE = 0x51, # Pause.
	UNP = 0x52, # Unpause.
	SAV = 0x53, # Save.
	CKP = 0x54, # Checkpoint.
}

enum {
	OPERAND_VAL = 0b0001, # Value.
	OPERAND_PTR = 0b0010, # Pointer.
	OPERAND_FLG = 0b0100, # Flag.
	OPERAND_TXT = 0b1000, # Text.
}

enum {
	FLAG_CACHEABLE = 0b01, # Program's bytecode may be cached.
	FLAG_PAUSABLE = 0b10, # Program will not run while the game is paused.
}

const THREAD_LIMIT: int = 16
const RUN_STEP_LIMIT: int = 32
const EMPTY_BYTECODE: PoolByteArray = PoolByteArray([
	0x00, # Not cacheable or pausable.
	0x00, 0x00, # Main vector.
	0x00, 0x00, # Repeat vector.
	0x00, 0x00, # 0 strings.
	0x00, 0x00, # 0 flags.
	0x01, 0x00, # 1 operation.
	HLT, # Halt.
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
	if not _is_caching or program_key.empty() or _program_cache.has(program_key):
		return
	
	var bytecode: PoolByteArray = _get_bytecode(program_key)
	
	if not bytecode.empty() and bytecode[0] & FLAG_CACHEABLE:
		_program_cache[program_key] = bytecode


# Flushes the NightScript program cache:
func flush_cache() -> void:
	_program_cache.clear()


# Gets a NightScript program's bytecode from its program key:
func _get_bytecode(program_key: String):
	if _program_cache.has(program_key):
		return _program_cache[program_key]
	
	var file: File = File.new()
	var path: String = "res://%s.%s.nsc" % [Global.lang.get_locale(), program_key]
	
	# DEBUG:BEGIN
	if OS.is_debug_build():
		path = "res://assets/data/nightscript/%s/%s.ns" % [
			Global.lang.get_locale(), program_key.replace(".", "/")
		]
	# DEBUG:END
	
	if not file.file_exists(path):
		path = "res://g.%s.nsc" % program_key
		
		# DEBUG:BEGIN
		if OS.is_debug_build():
			path = "res://assets/data/nightscript/global/%s.ns" % program_key.replace(".", "/")
		# DEBUG:END
		
		if not file.file_exists(path):
			path = "res://%s.%s.nsc" % [Global.lang.get_default_locale(), program_key]
			
			# DEBUG:BEGIN
			if OS.is_debug_build():
				path = "res://assets/data/nightscript/%s/%s.ns" % [
					Global.lang.get_default_locale(), program_key.replace(".", "/")
				]
			# DEBUG:END
			
			if not file.file_exists(path):
				Global.logger.err_nsc_not_found(program_key)
				return EMPTY_BYTECODE
	
	var error: int = file.open(path, File.READ)
	
	if error:
		if file.is_open():
			file.close()
		
		Global.logger.err_nsc_read(program_key, error)
		return EMPTY_BYTECODE
	
	# DEBUG:BEGIN
	if OS.is_debug_build():
		var source: String = file.get_as_text()
		file.close()
		var compiler: Reference = load("res://utils/nightscript/compiler/ns_compiler.gd").new()
		return compiler.compile_source(source, Global.config.get_bool("debug.optimize_nightscript"))
	# DEBUG:END
	
	var bytecode: PoolByteArray = file.get_buffer(file.get_len())
	file.close()
	return bytecode


# Calls a NightScript program on top of an existing NightScript thread:
func _call_program(program_key: String, thread: NSThread) -> void:
	var bytecode: PoolByteArray = _get_bytecode(program_key)
	
	if(
			_is_caching and not program_key.empty()
			and not _program_cache.has(program_key) and not bytecode.empty()
			and bytecode[0] & FLAG_CACHEABLE
	):
		_program_cache[program_key] = bytecode
	
	thread.push_machine(bytecode, bool(thread.get_flag("nightscript_seen", program_key)))
	thread.set_flag("nightscript_seen", program_key, 1)


# Signal callback for locale_changed on the language manager. Runs when the
# locale changes. Flushes the NightScript program cache:
func _on_lang_locale_changed(_locale: String) -> void:
	flush_cache()
