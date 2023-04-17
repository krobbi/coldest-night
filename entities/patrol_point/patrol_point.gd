class_name PatrolPoint
extends Marker2D

# Patrol Point
# A patrol point is an entity that represents a target position of a patrol
# route and contains patrol actions.

signal face_requested(angle: float)
signal navigation_requested(next_patrol_point: PatrolPoint, next_section: int)

enum PatrolOpcode {END_OF_SECTION, FACE, GOTO, SYNCH, WAIT}

@export var _patrol_script_point_paths: Array[NodePath]
@export_multiline var _patrol_script: String

var _is_occupied: bool = false
var _patrol_actions: Array[Dictionary] = []
var _section_table: Array[int] = [0]
var _action_index: int = 0
var _waited_time: float = 0.0

# Run when the patrol point enters the scene tree. Disable the patrol point's
# physics process and compile the patrol point's patrol script.
func _ready() -> void:
	set_physics_process(false)
	_compile()


# Run on every physics frame while the patrol point is occupied. Process the
# patrol point's actions.
func _physics_process(delta: float) -> void:
	if _action_index < 0 or _action_index >= len(_patrol_actions):
		set_physics_process(false)
		return
	
	var action: Dictionary = _patrol_actions[_action_index]
	
	match action.opcode:
		PatrolOpcode.END_OF_SECTION:
			_action_index = len(_patrol_actions)
		PatrolOpcode.FACE:
			face_requested.emit(action.angle)
			_action_index += 1
		PatrolOpcode.GOTO:
			navigation_requested.emit(action.point, action.section)
			_action_index += 1
		PatrolOpcode.SYNCH:
			if action.point.is_occupied():
				_action_index += 1
		PatrolOpcode.WAIT:
			_waited_time += delta
			
			if _waited_time >= action.duration:
				_waited_time = 0.0
				_action_index += 1


# Get whether the patrol point is occupied.
func is_occupied() -> bool:
	return _is_occupied


# Mark the patrol point as occupied at a section.
func occupy(section: int) -> void:
	if _is_occupied:
		return
	
	_is_occupied = true
	_action_index = _section_table[section]
	_waited_time = 0.0
	set_physics_process(true)


# Mark the patrol point as unoccupied.
func unoccupy() -> void:
	if not _is_occupied:
		return
	
	_is_occupied = false
	set_physics_process(false)


# Compile the patrol point's patrol actions.
func _compile() -> void:
	for line in _patrol_script.split("\n", false):
		var arguments: PackedStringArray = line.strip_edges().split(" ", false)
		
		if arguments.is_empty():
			continue
		
		if arguments[0] == "face" and len(arguments) == 2:
			var angle: float
			
			if arguments[1] == "up":
				angle = -PI / 2.0
			elif arguments[1] == "right":
				angle = 0.0
			elif arguments[1] == "down":
				angle = PI / 2.0
			elif arguments[1] == "left":
				angle = PI
			else:
				angle = deg_to_rad(float(arguments[1]))
			
			_patrol_actions.push_back({"opcode": PatrolOpcode.FACE, "angle": angle})
		elif arguments[0] == "goto" and len(arguments) == 2:
			var point_index: int = int(arguments[1])
			
			if point_index < 0 or point_index >= len(_patrol_script_point_paths):
				continue
			
			var point: PatrolPoint = get_node(_patrol_script_point_paths[point_index])
			_patrol_actions.push_back({"opcode": PatrolOpcode.GOTO, "point": point, "section": 0})
		elif arguments[0] == "goto" and len(arguments) == 3:
			var point_index: int = int(arguments[1])
			
			if point_index < 0 or point_index >= len(_patrol_script_point_paths):
				continue
			
			var point: PatrolPoint = get_node(_patrol_script_point_paths[point_index])
			var section: int = int(arguments[2])
			_patrol_actions.push_back({
				"opcode": PatrolOpcode.GOTO,
				"point": point,
				"section": section,
			})
		elif arguments[0] == "section" and len(arguments) == 1:
			_patrol_actions.push_back({"opcode": PatrolOpcode.END_OF_SECTION})
			_section_table.push_back(len(_patrol_actions))
		elif arguments[0] == "sync" and len(arguments) == 2:
			var point_index: int = int(arguments[1])
			
			if point_index < 0 or point_index >= len(_patrol_script_point_paths):
				continue
			
			var point: PatrolPoint = get_node(_patrol_script_point_paths[point_index])
			_patrol_actions.push_back({"opcode": PatrolOpcode.SYNCH, "point": point})
		elif arguments[0] == "wait" and len(arguments) == 2:
			var duration: float = float(arguments[1])
			_patrol_actions.push_back({"opcode": PatrolOpcode.WAIT, "duration": duration})
