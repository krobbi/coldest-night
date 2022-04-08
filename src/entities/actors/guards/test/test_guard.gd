extends Actor

# Test Guard
# A test guard is a temporary guard actor used for testing guard AI.

enum Facing {UP, RIGHT, DOWN, LEFT}

export(Facing) var _facing: int = Facing.RIGHT

var target: Player = null
var investigated_pos: Vector2 = Vector2.ZERO

# Virtual _ready method. Runs when the guard finishes entering the scene tree.
# Sets the guard's initial facing direction:
func _ready() -> void:
	match _facing:
		Facing.UP:
			smooth_pivot.rotation = PI * -0.5
		Facing.RIGHT:
			smooth_pivot.rotation = 0.0
		Facing.DOWN:
			smooth_pivot.rotation = PI * 0.5
		Facing.LEFT:
			smooth_pivot.rotation = PI


# Gets whether the guard is idle, e.g. willing to investigate something:
func is_idle() -> bool:
	match state_machine.get_key():
		"Scripted", "Looking", "Investigating":
			return true
		_:
			return false


# Investigates a torus shape around a world position:
func investigate(world_pos: Vector2, min_distance: float, max_distance: float) -> void:
	var distance: float = rand_range(min_distance, max_distance)
	var angle: float = rand_range(-PI, PI)
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance
	investigated_pos = world_pos + offset
	state_machine.change_state("Investigating")


# Requests other guards to investigate a world position:
func request_investigation(world_pos: Vector2, min_distance: float, max_distance: float) -> void:
	for guard in Global.tree.get_nodes_in_group("guards"):
		if guard == self:
			continue
		
		if guard.is_idle():
			guard.investigate(world_pos, min_distance, max_distance)


# Signal callback for player seen on the vision area. Runs when the test guard
# sees the player. Chases the player and requests other guards to investigate
# the player's position:
func _on_vision_area_player_seen(player: Player, world_pos: Vector2) -> void:
	target = player
	
	if not Global.config.get_bool("accessibility.never_game_over"):
		Global.events.emit_signal("game_over_request")
	elif state_machine.get_key() == "Scripted":
		Global.events.emit_signal("accumulate_alert_count_request")
	
	state_machine.change_state("Chasing")
	request_investigation(world_pos, 16.0, 64.0)


# Signal callback for player lost on the vision area. Runs when the test guard
# loses the player. Starts cheating and requests other guards to investigate the
# player's general last seen position:
func _on_vision_area_player_lost(player: Player, world_pos: Vector2) -> void:
	target = player
	state_machine.change_state("Cheating")
	request_investigation(world_pos, 128.0, 384.0)
