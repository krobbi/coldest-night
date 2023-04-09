extends Actor

# Guard
# A guard is an actor that seeks the player and broadcasts messages to other
# guards.

@export var _investigating_state_path: NodePath
@export var _seen_player_state_path: NodePath
@export var _lost_player_state_path: NodePath
@export var start_facing: Facing = Facing.RIGHT

var target: Player = null
var investigated_pos: Vector2 = Vector2.ZERO

@onready var _investigating_state: State = get_node(_investigating_state_path)
@onready var _seen_player_state: State = get_node(_seen_player_state_path)
@onready var _lost_player_state: State = get_node(_lost_player_state_path)

# Run when the guard finishes entering the scene tree. Set the guard's initial
# facing direction.
func _ready() -> void:
	super()
	
	match start_facing:
		Facing.UP:
			_facing = Facing.UP
			smooth_pivot.rotation = PI * -0.5
		Facing.RIGHT:
			_facing = Facing.RIGHT
			smooth_pivot.rotation = 0.0
		Facing.DOWN:
			_facing = Facing.DOWN
			smooth_pivot.rotation = PI * 0.5
		Facing.LEFT:
			_facing = Facing.LEFT
			smooth_pivot.rotation = PI


# Get the guard's target.
func get_target() -> Node2D:
	return target


# Get whether the guard is willing to investigate something.
func is_idle() -> bool:
	return state_machine.get_state_name() in ["Pathing", "Patrolling", "Looking", "Investigating"]


# Investigate a torus shape around a world position.
func investigate(world_pos: Vector2, min_distance: float, max_distance: float) -> void:
	var distance: float = randf_range(min_distance, max_distance)
	var angle: float = randf_range(-PI, PI)
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance
	investigated_pos = world_pos + offset
	state_machine.change_state(_investigating_state)


# Request other guards to investigate a world position.
func request_investigation(world_pos: Vector2, min_distance: float, max_distance: float) -> void:
	for guard in get_tree().get_nodes_in_group("guards"):
		if guard == self:
			continue
		
		if guard.is_idle():
			guard.investigate(world_pos, min_distance, max_distance)


# Run when the guard sees the player. Chase the player and request other guards
# to investigate the player's position.
func _on_vision_area_player_seen(player: Player, world_pos: Vector2) -> void:
	target = player
	
	if is_idle():
		EventBus.subtitle_display_request.emit("SUBTITLE.BARK.SEEN")
	
	if not ConfigBus.get_bool("accessibility.never_game_over"):
		EventBus.game_over_request.emit()
	
	state_machine.change_state(_seen_player_state)
	request_investigation(world_pos, 16.0, 64.0)


# Run when the guard loses the player. Start cheating and request other guards
# to investigate the player's general last seen position.
func _on_vision_area_player_lost(player: Player, world_pos: Vector2) -> void:
	target = player
	state_machine.change_state(_lost_player_state)
	request_investigation(world_pos, 128.0, 384.0)


# Run when the guard sees something suspicious. Investigate the suspicious area.
func _on_vision_area_suspicion_seen(world_pos: Vector2) -> void:
	if is_idle():
		investigate(world_pos, 16.0, 64.0)
		EventBus.subtitle_display_request.emit("SUBTITLE.BARK.SUSPICIOUS")
