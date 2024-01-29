extends Control

# Credits Scene
# The credits scene is a scene that displays the game's credits.

const SPEED: float = 30.0
const HEADING_COLOR: Color = Color("#ff980e")
const SUBHEADING_COLOR: Color = Color("#a9b0b0")

const CREDITS: String = """
# Coldest Night Credits

## Lead Developer
Chris Roberts (Krobbizoid)

# Resources

## Godot Engine
### Game engine

Godot Engine contributors
Juan Linietsky
Ariel Manzur

## Faraway48
### Color palette

Igor Ferreira (Diemorth)

## Atkinson Hyperlegible Font
### Legible font

Braille Institute of America, Inc.

---

For full license texts, please refer to the readme.md file distributed with the game.

Copyright © 2021-2024 Chris Roberts (Krobbizoid).
All rights reserved.

# Thanks for playing!
"""

@export_file("*.tscn") var _exit_scene_path: String
@export var _music: AudioStream

var _is_exiting: bool = false

@onready var _credits_label: RichTextLabel = $CreditsLabel
@onready var _credits_camera: Camera2D = $CreditsCamera

# Run when the credits scene is entered. Parse the credits and play background
# music.
func _ready() -> void:
	_credits_label.text = _parse_credits(CREDITS)
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


# Add line breaks to BBCode text.
func _break_text(text: String, count: int = 1) -> String:
	for i in range(count):
		if text.ends_with("\n"):
			text += " " # Workaround for rich text labels condensing lines.
		
		text += "\n"
	
	return text


# Color BBCode text.
func _color_text(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]


# Parse a credits source to credits BBCode.
func _parse_credits(source: String) -> String:
	var is_line_centered: bool = false
	var result: String = ""
	
	for line in source.split("\n"):
		line = line.strip_edges()
		
		if line == "---":
			result = _break_text(result, 2)
			line = ""
			is_line_centered = true
		elif line.begins_with("###"):
			line = _color_text(line.substr(3).strip_edges(), SUBHEADING_COLOR)
			is_line_centered = false
		elif line.begins_with("##"):
			line = _color_text(line.substr(2).strip_edges(), HEADING_COLOR)
			is_line_centered = false
		elif line.begins_with("#"):
			result = _break_text(result, 2)
			line = _color_text(line.substr(1).strip_edges(), HEADING_COLOR)
			is_line_centered = true
		
		if is_line_centered and not line.is_empty():
			line = "[center]%s[/center]" % line
		
		result = _break_text(result + line)
	
	return result.strip_edges()


# Exit the credits scene.
func _exit_credits() -> void:
	if _is_exiting:
		return
	
	_is_exiting = true
	SceneManager.change_scene_to_file(_exit_scene_path)
