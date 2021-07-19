class_name Player
extends Actor

# Player
# The player is the actor that the user controls.

const SPEED: float = 180.0;
const ACCELERATION: float = 1000.0;
const FRICTION: float = 1200.0;

var input_vector: Vector2 = Vector2.ZERO;
var velocity: Vector2 = Vector2.ZERO;

onready var camera_anchor: RemoteTransform2D = $CameraAnchor;

# Virtual _physics_process method. Runs on every frame while the player is in
# the scene. Provides a temporary player controller:
func _physics_process(delta: float) -> void:
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left");
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up");
	input_vector = input_vector.normalized();
	
	if input_vector:
		velocity = velocity.move_toward(input_vector * SPEED, ACCELERATION * delta);
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta);
	
	velocity = move_and_slide(velocity);
