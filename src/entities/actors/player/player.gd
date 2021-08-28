class_name Player
extends Actor

# Player
# The player is the actor that the user controls.

enum State {TRANSITIONING, MOVING};

const SPEED: float = 180.0;
const ACCELERATION: float = 1000.0;
const TRANSITION_ACCELERATION: float = 200.0;
const FRICTION: float = 1200.0;

var state: int = State.TRANSITIONING setget set_state;

var _input_vector: Vector2 = Vector2.ZERO;
var _velocity: Vector2 = Vector2.ZERO;

onready var _triggering_shape: CollisionShape2D = $TriggeringArea/TriggeringShape;
onready var _radar: Radar = Global.provider.get_radar();

# Virtual _ready method. Runs when the player finishes entering the scene tree
# for the first time. Registers the player to the global provider manager:
func _ready() -> void:
	Global.provider.set_player(self);


# Virtual _physics_process method. Runs on every physics frame while the player
# is in the scene tree. Handles a temporary state machine for the player:
func _physics_process(delta: float) -> void:
	match state:
		State.TRANSITIONING:
			_state_transitioning(delta);
		State.MOVING, _:
			_state_moving(delta);


# Virtual _exit_tree method. Runs when the player exits the scene tree.
# Unregisters the player from the global provider manager:
func _exit_tree() -> void:
	Global.provider.set_player(null);


# Sets the player's state:
func set_state(value: int) -> void:
	match value:
		State.TRANSITIONING:
			state = State.TRANSITIONING;
			_input_vector = _velocity.normalized();
		State.MOVING, _:
			state = State.MOVING;


# Enables the player's ability to interact with triggers:
func enable_triggers() -> void:
	_triggering_shape.set_disabled(false);


# Disables the player's ability to interact with triggers:
func disable_triggers() -> void:
	_triggering_shape.set_disabled(true);


# Clears the player's velocity:
func clear_velocity() -> void:
	_velocity = Vector2.ZERO;


# Processes the player's transitioning state:
func _state_transitioning(delta: float) -> void:
	_velocity = _velocity.move_toward(_input_vector * SPEED, TRANSITION_ACCELERATION * delta);
	_apply_velocity();


# Processes the player's moving state:
func _state_moving(delta: float) -> void:
	_input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left");
	_input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up");
	_input_vector = _input_vector.normalized();
	
	if _input_vector == Vector2.ZERO:
		_velocity = _velocity.move_toward(Vector2.ZERO, FRICTION * delta);
	else:
		_velocity = _velocity.move_toward(_input_vector * SPEED, ACCELERATION * delta);
	
	_apply_velocity();


# Applies the player's current velocity to its movement:
func _apply_velocity() -> void:
	_velocity = move_and_slide(_velocity);
	
	if _radar != null:
		_radar.set_player_pos(get_position());
