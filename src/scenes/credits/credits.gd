extends Control

# Credits Scene
# The credits scene is a scene that displays the game's credits.

const SPEED: float = 30.0

var _is_exiting: bool = false

onready var _credits_label: RichTextLabel = $CreditsLabel
onready var _credits_camera: Camera2D = $CreditsCamera

# Virtual _ready method. Runs when the credits scene is entered. Loads and
# parses the credits file and plays background music:
func _ready() -> void:
	var file: File = File.new()
	var path: String = _get_credits_path()
	
	if not file.file_exists(path):
		Global.logger.err_credits_not_found(path)
		_exit_credits()
		return
	
	var error: int = file.open(path, File.READ)
	
	if error:
		if file.is_open():
			file.close()
		
		Global.logger.err_credits_read(path, error)
		_exit_credits()
		return
	
	var parser: CreditsParser = CreditsParser.new()
	_credits_label.bbcode_text = parser.parse_source(file.get_as_text())
	file.close()
	parser.free()
	Global.audio.play_music("credits", false)


# Virtual _input method. Runs when the credits scene receives an input event.
# Handles controls for quitting to the title screen scene:
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_exit_credits()


# Virtual _process method. Runs on every frame. Scrolls the credits camera down
# and quits to the title screen scene if the credits are finished:
func _process(delta: float) -> void:
	_credits_camera.position.y += SPEED * delta
	
	if _credits_camera.position.y > _credits_label.rect_position.y + _credits_label.rect_size.y:
		_exit_credits()


# Gets the path to a credits file from the current locale:
func _get_credits_path() -> String:
	var base_path: String = "res://%s.txt"
	
	# DEBUG:BEGIN
	if OS.is_debug_build():
		base_path = "res://assets/data/credits/credits_%s.txt"
	# DEBUG:END
	
	var dir: Directory = Directory.new()
	var path: String = base_path % Global.lang.get_locale()
	
	if dir.file_exists(path):
		return path
	else:
		return base_path % Global.lang.get_default_locale()


# Exits the credits scene:
func _exit_credits() -> void:
	if _is_exiting:
		return
	
	_is_exiting = true
	Global.change_scene("menu")
