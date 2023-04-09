extends Control

# Credits Scene
# The credits scene is a scene that displays the game's credits.

const CREDITS_PATH: String = "res://scenes/credits/credits_%s.txt"
const SPEED: float = 30.0

@export var _exit_scene_path: String # (String, FILE, "*.tscn")
@export var _music: AudioStream

var _is_exiting: bool = false

@onready var _credits_label: RichTextLabel = $CreditsLabel
@onready var _credits_camera: Camera2D = $CreditsCamera

# Run when the credits scene is entered. Load and parse the credits file and
# play background music.
func _ready() -> void:
	var path: String = CREDITS_PATH % LangManager.get_locale()
	
	if not FileAccess.file_exists(path):
		path = CREDITS_PATH % LangManager.get_default_locale()
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		_exit_credits()
		return
	
	_credits_label.text = _parse_credits(file.get_as_text())
	file.close()
	AudioManager.play_music(_music, false)


# Run when the credits scene receives an input event. Handle controls for
# skipping the credits.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_exit_credits()


# Run on every frame. Scroll the credits camera down and exit the credits scene
# if the credits are finished.
func _process(delta: float) -> void:
	_credits_camera.position.y += SPEED * delta
	
	if _credits_camera.position.y > _credits_label.position.y + _credits_label.size.y:
		_exit_credits()


# Add a line to BBCode text as a workaround for rich text labels condensing
# repeated lines.
func _add_line(text: String) -> String:
	if text.ends_with("\n"):
		return "%s \n" % text
	else:
		return "%s\n" % text


# Parse a credits source to credits BBCode.
func _parse_credits(source: String) -> String:
	var is_line_centered: bool = false
	var result: String = ""
	
	for line in source.split("\n"):
		line = line.strip_edges()
		
		if line.begins_with("##"):
			line = "[color=#ff980e]%s[/color]" % line.substr(2).strip_edges(true, false)
			is_line_centered = false
		elif line.begins_with("#"):
			result = _add_line(_add_line(result))
			line = "[color=#ff980e]%s[/color]" % line.substr(1).strip_edges(true, false)
			is_line_centered = true
		
		if is_line_centered and not line.is_empty():
			line = "[center]%s[/center]" % line
		
		result = _add_line("%s%s" % [result, line])
	
	return result.strip_edges()


# Exit the credits scene.
func _exit_credits() -> void:
	if _is_exiting:
		return
	
	_is_exiting = true
	SceneManager.change_scene_to_file(_exit_scene_path)
