extends Control

# Credits Scene
# The credits scene is a scene that displays the game's credits.

const CREDITS_PATH: String = "res://scenes/credits/credits_%s.txt"
const SPEED: float = 30.0

var _is_exiting: bool = false

onready var _credits_label: RichTextLabel = $CreditsLabel
onready var _credits_camera: Camera2D = $CreditsCamera

# Run when the credits scene is entered. Load and parse the credits file and
# play background music.
func _ready() -> void:
	var file: File = File.new()
	var path: String = CREDITS_PATH % LangManager.get_locale()
	
	if not file.file_exists(path):
		path = CREDITS_PATH % LangManager.get_default_locale()
	
	if file.open(path, File.READ) != OK:
		if file.is_open():
			file.close()
		
		_exit_credits()
		return
	
	_credits_label.bbcode_text = _parse_credits(file.get_as_text())
	file.close()
	AudioManager.play_music("credits", false)


# Run when the credits scene receives an input event. Handle controls for
# quitting to the menu scene.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_exit_credits()


# Run on every frame. Scroll the credits camera down and quit to the title
# screen scene if the credits are finished.
func _process(delta: float) -> void:
	_credits_camera.position.y += SPEED * delta
	
	if _credits_camera.position.y > _credits_label.rect_position.y + _credits_label.rect_size.y:
		_exit_credits()


# Parse a credits source to credits bbcode.
func _parse_credits(source: String) -> String:
	var is_line_centered: bool = false
	var result: String = ""
	
	for line in source.split("\n"):
		line = line.strip_edges()
		
		if line.begins_with("##"):
			line = "[color=#ff980e]%s[/color]" % line.substr(2).strip_edges(true, false)
			is_line_centered = false
		elif line.begins_with("#"):
			result = "%s\n\n" % result
			line = "[color=#ff980e]%s[/color]" % line.substr(1).strip_edges(true, false)
			is_line_centered = true
		
		if is_line_centered and not line.empty():
			line = "[center]%s[/center]" % line
		
		result = "%s%s\n" % [result, line]
	
	return result.strip_edges()


# Exit the credits scene.
func _exit_credits() -> void:
	if _is_exiting:
		return
	
	_is_exiting = true
	Global.change_scene("menu")
