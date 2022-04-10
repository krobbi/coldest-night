class_name DisplayManager
extends Object

# Display Manager
# The display manager is a global utility that handles storing and controlling
# the state of the display. It can be accessed from any script by using
# 'Global.display'.

signal screen_stretch_changed

enum ScaleMode {STRETCH, PIXEL, ASPECT}

var legible_font: bool = false setget set_legible_font
var fullscreen: bool = ProjectSettings.get_setting(
		"display/window/size/fullscreen"
) setget set_fullscreen
var vsync: bool = ProjectSettings.get_setting("display/window/vsync/use_vsync") setget set_vsync
var pixel_snap: bool = false setget set_pixel_snap
var scale_mode: int = ScaleMode.ASPECT setget set_scale_mode
var window_scale: int = 1 setget set_window_scale

var _tree: SceneTree
var _config: ConfigBus
var _logger: Logger
var _viewport: Viewport
var _resolution: Vector2 = Vector2(
		max(1.0, float(ProjectSettings.get_setting("display/window/size/width"))),
		max(1.0, float(ProjectSettings.get_setting("display/window/size/height")))
)
var _window_scale_max: int = _get_max_window_scale(0.0, 0.0)
var _window_scale_default: int = _get_max_window_scale(64.0, 0.0333)
var _is_handling_resize: bool = false
var _should_apply_window_scale: bool = false

# Preloading these themes as constants would cause unimported asset dependencies
# to be lost:
var _text_themes: Array = [
	load("res://assets/themes/floating_text.tres"),
	load("res://assets/themes/dialogs/plain_dialog.tres"),
	load("res://assets/themes/menu.tres"),
	load("res://assets/themes/title.tres"),
]

# Constructor. Connects the display manager's configuration values:
func _init(tree_ref: SceneTree, config_ref: ConfigBus, logger_ref: Logger) -> void:
	_tree = tree_ref
	_config = config_ref
	_logger = logger_ref
	_viewport = _tree.root
	_config.connect_bool("accessibility.legible_font", self, "set_legible_font")
	_config.connect_bool("display.fullscreen", self, "set_fullscreen")
	_config.connect_bool("display.vsync", self, "set_vsync")
	_config.connect_bool("display.pixel_snap", self, "set_pixel_snap")
	_config.connect_string("display.scale_mode", self, "_set_scale_mode_string")
	_config.connect_int("display.window_scale", self, "set_window_scale")


# Sets whether an alternative, more legible font is used:
func set_legible_font(value: bool) -> void:
	_config.set_bool("accessibility.legible_font", value)
	
	if legible_font == value:
		return
	
	legible_font = value
	var font: DynamicFont = _load_font("atkinson_hyperlegible" if legible_font else "coldnight")
	
	for theme in _text_themes:
		theme.default_font = font


# Sets whether the display is fullscreen:
func set_fullscreen(value: bool) -> void:
	_config.set_bool("display.fullscreen", value)
	
	if fullscreen == value:
		return
	
	fullscreen = value
	
	if fullscreen:
		yield(_tree, "idle_frame")
		OS.window_borderless = true
		yield(_tree, "idle_frame")
		OS.window_fullscreen = true
		yield(_tree, "idle_frame")
		_set_handling_resize(false)
	else:
		OS.window_fullscreen = false
		OS.window_borderless = false
		
		if _should_apply_window_scale:
			_apply_window_scale()
		
		_set_handling_resize(scale_mode == ScaleMode.PIXEL)
	
	if scale_mode == ScaleMode.PIXEL:
		_apply_pixel_perfect()


# Sets whether the display uses vsync:
func set_vsync(value: bool) -> void:
	_config.set_bool("display.vsync", value)
	
	if vsync == value:
		return
	
	vsync = value
	OS.vsync_enabled = vsync


# Sets whether the display uses pixel snapping:
func set_pixel_snap(value: bool) -> void:
	_config.set_bool("display.pixel_snap", value)
	
	if pixel_snap == value:
		return
	
	pixel_snap = value
	_apply_screen_stretch()
	
	if scale_mode == ScaleMode.PIXEL:
		_apply_pixel_perfect()


# Sets the display's scale mode:
func set_scale_mode(value: int) -> void:
	if scale_mode == value:
		return
	
	match value:
		ScaleMode.STRETCH:
			scale_mode = ScaleMode.STRETCH
			_set_handling_resize(false)
			_config.set_string("display.scale_mode", "stretch")
		ScaleMode.PIXEL:
			scale_mode = ScaleMode.PIXEL
			_set_handling_resize(not fullscreen)
			_config.set_string("display.scale_mode", "pixel")
		ScaleMode.ASPECT, _:
			scale_mode = ScaleMode.ASPECT
			_set_handling_resize(false)
			_config.set_string("display.scale_mode", "aspect")
	
	_apply_screen_stretch()
	
	if scale_mode == ScaleMode.PIXEL:
		_apply_pixel_perfect()


# Sets the display's window scale:
func set_window_scale(value: int) -> void:
	if _window_scale_default == value or value <= 0:
		window_scale = _window_scale_default
	elif value >= _window_scale_max:
		window_scale = _window_scale_max
	else:
		window_scale = value
	
	_config.set_int("display.window_scale", window_scale)
	
	if fullscreen:
		_should_apply_window_scale = true
	else:
		_apply_window_scale()


# Gets the display's maximum window scale:
func get_window_scale_max() -> int:
	return _window_scale_max


# Gets a dictionary of window scale options and their strings:
func get_window_scale_options() -> Dictionary:
	var options: Dictionary = {}
	
	for i in range(1, _window_scale_max + 1):
		options[i] = "%dx" % i
	
	return options


# Destructor. Disconnects the display manager's configuration values and stops
# handling resizing the display:
func destruct() -> void:
	_config.disconnect_value("display.window_scale", self, "set_window_scale")
	_config.disconnect_value("display.scale_mode", self, "_set_scale_mode_string")
	_config.disconnect_value("display.pixel_snap", self, "set_pixel_snap")
	_config.disconnect_value("display.vsync", self, "set_vsync")
	_config.disconnect_value("display.fullscreen", self, "set_fullscreen")
	_config.disconnect_value("accessibility.legible_font", self, "set_legible_font")


# Sets whether resizing the display is being handled:
func _set_handling_resize(value: bool) -> void:
	if _is_handling_resize == value:
		return
	
	if value:
		var error: int = _tree.connect("screen_resized", self, "_apply_pixel_perfect")
		
		if error:
			if _tree.is_connected("screen_resized", self, "_apply_pixel_perfect"):
				_tree.disconnect("screen_resized", self, "_apply_pixel_perfect")
			
			_logger.err_display_handle_resize(error)
		else:
			_is_handling_resize = true
	else:
		_tree.disconnect("screen_resized", self, "_apply_pixel_perfect")
		_is_handling_resize = false


# Sets the display's scale mode from its configuration string:
func _set_scale_mode_string(value: String) -> void:
	match value:
		"stretch":
			set_scale_mode(ScaleMode.STRETCH)
		"pixel":
			set_scale_mode(ScaleMode.PIXEL)
		"aspect", _:
			set_scale_mode(ScaleMode.ASPECT)


# Gets the maximum integral window scale that can fit on the screen with a given
# margin size:
func _get_max_window_scale(margin_min: float, margin_scale: float) -> int:
	var screen_size: Vector2 = OS.get_screen_size()
	var max_scales: Vector2 = (screen_size - Vector2(
			max(margin_min, screen_size.x * margin_scale),
			max(margin_min, screen_size.y * margin_scale)
	)) / _resolution
	return int(max(1.0, min(max_scales.x, max_scales.y)))


# Applies the appropriate screen stretch based on the display's current state:
func _apply_screen_stretch() -> void:
	_tree.set_screen_stretch(
			SceneTree.STRETCH_MODE_VIEWPORT if pixel_snap else SceneTree.STRETCH_MODE_2D,
			SceneTree.STRETCH_ASPECT_IGNORE if scale_mode == ScaleMode.STRETCH
			else SceneTree.STRETCH_ASPECT_KEEP, _resolution
	)
	emit_signal("screen_stretch_changed")


# Applies the pixel-perfect scale mode to the display:
func _apply_pixel_perfect() -> void:
	var window_size: Vector2 = OS.window_size
	var viewport_scale: float = floor(
			max(1.0, min(window_size.x / _resolution.x, window_size.y / _resolution.y))
	)
	var viewport_size: Vector2 = _resolution * viewport_scale
	var viewport_position: Vector2 = ((window_size - viewport_size) * 0.5).floor()
	var margin_l: int = int(max(0.0, viewport_position.x))
	var margin_t: int = int(max(0.0, viewport_position.y))
	var margin_r: int = int(max(0.0, window_size.x - viewport_size.x)) - margin_l
	var margin_b: int = int(max(0.0, window_size.y - viewport_size.y)) - margin_t
	_viewport.set_attach_to_screen_rect(Rect2(viewport_position, viewport_size))
	VisualServer.black_bars_set_margins(margin_l, margin_t, margin_r, margin_b)


# Applies the display's window scale to the display:
func _apply_window_scale() -> void:
	_should_apply_window_scale = false
	OS.window_size = _resolution * window_scale
	OS.center_window()


# Loads a font from its font key:
func _load_font(font_key: String) -> DynamicFont:
	var path: String = "res://assets/fonts/%s.tres" % font_key.replace(".", "/")
	
	if ResourceLoader.exists(path, "DynamicFont"):
		return load(path) as DynamicFont
	else:
		_logger.err_font_not_found(font_key)
		return load("res://assets/fonts/coldnight.tres") as DynamicFont
