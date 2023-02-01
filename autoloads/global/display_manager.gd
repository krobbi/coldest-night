class_name DisplayManager
extends Reference

# Display Manager
# The display manager is a global utility that handles storing and controlling
# the state of the display. It can be accessed from any script by using
# `Global.display`.

signal screen_stretch_changed

enum ScaleMode {STRETCH, PIXEL, ASPECT}

var legible_font: bool = false setget set_legible_font
var fullscreen: bool = ProjectSettings.get_setting(
		"display/window/size/fullscreen") setget set_fullscreen
var vsync: bool = ProjectSettings.get_setting("display/window/vsync/use_vsync") setget set_vsync
var pixel_snap: bool = false setget set_pixel_snap
var window_scale: int = 1 setget set_window_scale
var scale_mode: int = ScaleMode.ASPECT setget set_scale_mode

var _resolution: Vector2 = Vector2(
		max(1.0, float(ProjectSettings.get_setting("display/window/size/width"))),
		max(1.0, float(ProjectSettings.get_setting("display/window/size/height"))))
var _window_scale_max: int = _get_max_window_scale(0.0, 0.0)
var _window_scale_default: int = _get_max_window_scale(64.0, 0.0333)
var _is_handling_resize: bool = false
var _should_apply_window_scale: bool = false

# HACK: Preloading these themes as constants would cause any unimported
# dependencies (such as image files) to be lost from the themes.
var _text_themes: Array = [
	load("res://resources/themes/dialogs/plain_dialog.tres"),
	load("res://resources/themes/credits.tres"),
	load("res://resources/themes/menu_card.tres"),
	load("res://resources/themes/menu_row.tres"),
	load("res://resources/themes/popup_text.tres"),
]

# Connect the display manager to the configuration bus.
func _init() -> void:
	Global.config.connect_bool("accessibility.legible_font", self, "set_legible_font")
	Global.config.connect_bool("display.fullscreen", self, "set_fullscreen")
	Global.config.connect_bool("display.vsync", self, "set_vsync")
	Global.config.connect_bool("display.pixel_snap", self, "set_pixel_snap")
	Global.config.connect_int("display.window_scale", self, "set_window_scale")
	Global.config.connect_string("display.scale_mode", self, "_set_scale_mode_string")


# Set whether an alternative, more legible font is used.
func set_legible_font(value: bool) -> void:
	Global.config.set_bool("accessibility.legible_font", value)
	
	if legible_font == value:
		return
	
	legible_font = value
	var font: DynamicFont = _load_font("atkinson_hyperlegible" if legible_font else "coldnight")
	
	for theme in _text_themes:
		theme.default_font = font


# Set whether the display is fullscreen.
func set_fullscreen(value: bool) -> void:
	Global.config.set_bool("display.fullscreen", value)
	
	if fullscreen == value:
		return
	
	fullscreen = value
	
	if fullscreen:
		yield(Global.tree, "idle_frame")
		OS.window_borderless = true
		yield(Global.tree, "idle_frame")
		OS.window_fullscreen = true
		yield(Global.tree, "idle_frame")
		_set_handling_resize(false)
	else:
		OS.window_fullscreen = false
		OS.window_borderless = false
		
		if _should_apply_window_scale:
			_apply_window_scale()
		
		_set_handling_resize(scale_mode == ScaleMode.PIXEL)
	
	if scale_mode == ScaleMode.PIXEL:
		_apply_pixel_perfect()


# Set whether the display uses vsync.
func set_vsync(value: bool) -> void:
	Global.config.set_bool("display.vsync", value)
	
	if vsync == value:
		return
	
	vsync = value
	OS.vsync_enabled = vsync


# Set whether the display uses pixel snapping.
func set_pixel_snap(value: bool) -> void:
	Global.config.set_bool("display.pixel_snap", value)
	
	if pixel_snap == value:
		return
	
	pixel_snap = value
	_apply_screen_stretch()
	
	if scale_mode == ScaleMode.PIXEL:
		_apply_pixel_perfect()


# Set the display's window scale.
func set_window_scale(value: int) -> void:
	if _window_scale_default == value or value <= 0:
		window_scale = _window_scale_default
	elif value >= _window_scale_max:
		window_scale = _window_scale_max
	else:
		window_scale = value
	
	Global.config.set_int("display.window_scale", window_scale)
	
	if fullscreen:
		_should_apply_window_scale = true
	else:
		_apply_window_scale()


# Set the display's scale mode.
func set_scale_mode(value: int) -> void:
	if scale_mode == value:
		return
	
	match value:
		ScaleMode.STRETCH:
			scale_mode = ScaleMode.STRETCH
			_set_handling_resize(false)
			Global.config.set_string("display.scale_mode", "stretch")
		ScaleMode.PIXEL:
			scale_mode = ScaleMode.PIXEL
			_set_handling_resize(not fullscreen)
			Global.config.set_string("display.scale_mode", "pixel")
		ScaleMode.ASPECT, _:
			scale_mode = ScaleMode.ASPECT
			_set_handling_resize(false)
			Global.config.set_string("display.scale_mode", "aspect")
	
	_apply_screen_stretch()
	
	if scale_mode == ScaleMode.PIXEL:
		_apply_pixel_perfect()


# Get the display's maximum window scale:
func get_window_scale_max() -> int:
	return _window_scale_max


# Get a dictionary of window scale options:
func get_window_scale_options() -> Dictionary:
	var options: Dictionary = {}
	
	for i in range(1, _window_scale_max + 1):
		options[tr("OPTION.DISPLAY.WINDOW_SCALE.VALUE").format({"window_scale": i})] = i
	
	return options


# Get a dictionary of scale mode options:
func get_scale_mode_options() -> Dictionary:
	return {
		"OPTION.DISPLAY.SCALE_MODE.STRETCH": "stretch",
		"OPTION.DISPLAY.SCALE_MODE.ASPECT": "aspect",
		"OPTION.DISPLAY.SCALE_MODE.PIXEL": "pixel",
	}


# Disconnect the display manager from the configuration bus and stop handling
# resizing the display.
func destruct() -> void:
	Global.config.disconnect_value("display.scale_mode", self, "_set_scale_mode_string")
	Global.config.disconnect_value("display.window_scale", self, "set_window_scale")
	Global.config.disconnect_value("display.pixel_snap", self, "set_pixel_snap")
	Global.config.disconnect_value("display.vsync", self, "set_vsync")
	Global.config.disconnect_value("display.fullscreen", self, "set_fullscreen")
	Global.config.disconnect_value("accessibility.legible_font", self, "set_legible_font")
	_set_handling_resize(false)


# Set whether resizing the display is being handled.
func _set_handling_resize(value: bool) -> void:
	if _is_handling_resize == value:
		return
	
	if value:
		if Global.tree.connect("screen_resized", self, "_apply_pixel_perfect") == OK:
			_is_handling_resize = true
		elif Global.tree.is_connected("screen_resized", self, "_apply_pixel_perfect"):
			Global.tree.disconnect("screen_resized", self, "_apply_pixel_perfect")
	else:
		Global.tree.disconnect("screen_resized", self, "_apply_pixel_perfect")
		_is_handling_resize = false


# Set the display's scale mode from its configuration string.
func _set_scale_mode_string(value: String) -> void:
	match value:
		"stretch":
			set_scale_mode(ScaleMode.STRETCH)
		"pixel":
			set_scale_mode(ScaleMode.PIXEL)
		"aspect", _:
			set_scale_mode(ScaleMode.ASPECT)


# Get the maximum integral window scale that can fit on the screen with a given
# margin size.
func _get_max_window_scale(margin_min: float, margin_scale: float) -> int:
	var screen_size: Vector2 = OS.get_screen_size()
	var max_scales: Vector2 = (screen_size - Vector2(
			max(margin_min, screen_size.x * margin_scale),
			max(margin_min, screen_size.y * margin_scale)
	)) / _resolution
	return int(max(1.0, min(max_scales.x, max_scales.y)))


# Apply the appropriate screen stretch based on the display's current state.
func _apply_screen_stretch() -> void:
	Global.tree.set_screen_stretch(
			SceneTree.STRETCH_MODE_VIEWPORT if pixel_snap else SceneTree.STRETCH_MODE_2D,
			SceneTree.STRETCH_ASPECT_IGNORE if scale_mode == ScaleMode.STRETCH
			else SceneTree.STRETCH_ASPECT_KEEP, _resolution)
	emit_signal("screen_stretch_changed")


# Apply the pixel-perfect scale mode to the display.
func _apply_pixel_perfect() -> void:
	var window_size: Vector2 = OS.window_size
	var viewport_scale: float = floor(
			max(1.0, min(window_size.x / _resolution.x, window_size.y / _resolution.y)))
	var viewport_size: Vector2 = _resolution * viewport_scale
	var viewport_position: Vector2 = ((window_size - viewport_size) * 0.5).floor()
	var margin_l: int = int(max(0.0, viewport_position.x))
	var margin_t: int = int(max(0.0, viewport_position.y))
	var margin_r: int = int(max(0.0, window_size.x - viewport_size.x)) - margin_l
	var margin_b: int = int(max(0.0, window_size.y - viewport_size.y)) - margin_t
	Global.tree.root.set_attach_to_screen_rect(Rect2(viewport_position, viewport_size))
	VisualServer.black_bars_set_margins(margin_l, margin_t, margin_r, margin_b)


# Apply the display's window scale to the display.
func _apply_window_scale() -> void:
	_should_apply_window_scale = false
	OS.window_size = _resolution * window_scale
	OS.center_window()


# Load a font from its font key.
func _load_font(font_key: String) -> DynamicFont:
	return load("res://resources/fonts/%s.tres" % font_key) as DynamicFont
