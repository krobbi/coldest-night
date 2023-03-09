extends Node

# Display Manager
# The display manager is an autoload scene that controls the state of the
# display. It can be accessed from any script by using `DisplayManager`.

const FONTS_DIR: String = "user://fonts/"
const PALETTE: Dictionary = {
	"white": Color("#f1f2f1"),
	"red": Color("#ad1818"),
	"orange": Color("ff980e"),
	"yellow": Color("#fff959"),
	"dark_green": Color("#169e26"),
	"green": Color("#8ffa37"),
	"blue": Color("#45c5d9"),
}

var _resolution: Vector2 = Vector2(
		max(1.0, float(ProjectSettings.get_setting("display/window/size/width"))),
		max(1.0, float(ProjectSettings.get_setting("display/window/size/height"))))
var _max_window_scale: int = _get_max_window_scale(0.0, 0.0)
var _default_window_scale: int = _get_max_window_scale(64.0, 0.0333)
var _is_awaiting_scale_change: bool = false
var _is_handling_resize: bool = false

var _text_themes: Array = [
	load("res://resources/themes/dialogs/plain_dialog.tres"),
	load("res://resources/themes/credits.tres"),
	load("res://resources/themes/menu_card.tres"),
	load("res://resources/themes/menu_row.tres"),
	load("res://resources/themes/popup_text.tres"),
]

var _custom_fonts: Dictionary = {}

# Run when the display manager enters the scene tree. Subscribe the display
# manager to the configuration bus and refresh the custom fonts.
func _ready() -> void:
	ConfigBus.subscribe_node_bool("display.fullscreen", self, "_on_fullscreen_changed")
	ConfigBus.subscribe_node_bool("display.vsync", self, "_on_vsync_changed")
	ConfigBus.subscribe_node_bool("display.pixel_snap", self, "_on_pixel_snap_changed")
	ConfigBus.subscribe_node_int("display.window_scale", self, "_set_window_scale")
	ConfigBus.subscribe_node_string("display.scale_mode", self, "_on_scale_mode_changed")
	ConfigBus.subscribe_node_string("font.family", self, "_set_font_family")
	ConfigBus.subscribe_node_int("font.size", self, "_on_font_size_changed")
	refresh_custom_fonts()


# Run when the display manager receives an input event. Handle controls for
# toggling fullscreen.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		ConfigBus.set_bool("display.fullscreen", not ConfigBus.get_bool("display.fullscreen"))


# Run when the display manager exits the scene tree. Stop handling resizing the
# display.
func _exit_tree() -> void:
	_set_handling_resize(false)


# Get the display's maximum window scale.
func get_max_window_scale() -> int:
	return _max_window_scale


# Get a palette color from its color name.
func get_palette_color(color_name: String) -> Color:
	return PALETTE.get(color_name, PALETTE.orange)


# Get a dictionary of color options.
func get_color_options() -> Dictionary:
	var color_options = {}
	
	for color_name in PALETTE:
		color_options["OPTION.RADAR.COLOR.%s" % color_name.to_upper()] = color_name
	
	return color_options


# Get a dictionary of font options.
func get_font_options() -> Dictionary:
	var font_options: Dictionary = {
		"OPTION.FONT.FAMILY.COLDNIGHT": "coldnight",
		"OPTION.FONT.FAMILY.ATKINSON_HYPERLEGIBLE": "atkinson_hyperlegible",
	}
	
	var counter: int = 0
	
	for custom_font in _custom_fonts:
		counter += 1
		font_options[tr("OPTION.FONT.FAMILY.CUSTOM").format({"counter": counter})] = custom_font
	
	return font_options


# Get a dictionary of window scale options.
func get_window_scale_options() -> Dictionary:
	var options: Dictionary = {}
	
	for i in range(1, _max_window_scale + 1):
		options[tr("OPTION.DISPLAY.WINDOW_SCALE.VALUE").format({"window_scale": i})] = i
	
	return options


# Get a dictionary of scale mode options.
func get_scale_mode_options() -> Dictionary:
	return {
		"OPTION.DISPLAY.SCALE_MODE.STRETCH": "stretch",
		"OPTION.DISPLAY.SCALE_MODE.ASPECT": "aspect",
		"OPTION.DISPLAY.SCALE_MODE.PIXEL": "pixel",
	}


# Refresh the list of custom fonts.
func refresh_custom_fonts() -> void:
	_custom_fonts.clear()
	var dir: Directory = Directory.new()
	
	if not dir.dir_exists(FONTS_DIR) and dir.make_dir(FONTS_DIR) != OK or dir.open(FONTS_DIR) != OK:
		return
	elif dir.list_dir_begin(true) != OK:
		dir.list_dir_end()
		return
	
	var file_name: String = dir.get_next()
	
	while not file_name.empty():
		var path: String = FONTS_DIR.plus_file(file_name)
		
		if ResourceLoader.exists(path, "DynamicFontData"):
			var font: DynamicFont = DynamicFont.new()
			font.size = ConfigBus.get_int("font.size", 20)
			font.font_data = load(path)
			_custom_fonts[path] = font
		
		file_name = dir.get_next()
	
	dir.list_dir_end()


# Set the font family.
func _set_font_family(value: String) -> void:
	var font: DynamicFont = _load_font(value)
	
	if not font:
		ConfigBus.set_string("font.family", "coldnight")
		return
	
	for theme in _text_themes:
		theme.default_font = font


# Set the window scale.
func _set_window_scale(value: int) -> void:
	if value <= 0:
		ConfigBus.set_int("display.window_scale", _default_window_scale)
		return
	elif value > _max_window_scale:
		ConfigBus.set_int("display.window_scale", _max_window_scale)
		return
	
	OS.window_size = _resolution * float(value)
	OS.center_window()
	
	if ConfigBus.get_bool("display.fullscreen"):
		_is_awaiting_scale_change = true


# Set whether resizing the display is being handled.
func _set_handling_resize(value: bool) -> void:
	if _is_handling_resize == value:
		return
	
	if value:
		if get_tree().connect("screen_resized", self, "_apply_pixel_perfect") == OK:
			_is_handling_resize = true
		elif get_tree().is_connected("screen_resized", self, "_apply_pixel_perfect"):
			get_tree().disconnect("screen_resized", self, "_apply_pixel_perfect")
	else:
		get_tree().disconnect("screen_resized", self, "_apply_pixel_perfect")
		_is_handling_resize = false


# Get the maximum integral window scale that can fit on the screen with a given
# margin size.
func _get_max_window_scale(margin_min: float, margin_scale: float) -> int:
	var screen_size: Vector2 = OS.get_screen_size()
	var max_scales: Vector2 = (screen_size - Vector2(
			max(margin_min, screen_size.x * margin_scale),
			max(margin_min, screen_size.y * margin_scale))) / _resolution
	return int(max(1.0, min(max_scales.x, max_scales.y)))


# Load a dynamic font from its config key. Return `null` if the dynamic font
# cannot be loaded.
func _load_font(config_key: String) -> DynamicFont:
	if config_key.begins_with(FONTS_DIR):
		if _custom_fonts.has(config_key):
			return _custom_fonts[config_key]
		
		if ResourceLoader.exists(config_key, "DynamicFontData"):
			var font: DynamicFont = DynamicFont.new()
			font.size = ConfigBus.get_int("font.size", 20)
			font.font_data = load(config_key)
			_custom_fonts[config_key] = font
			return font
	else:
		var path: String = "res://resources/fonts/%s.tres" % config_key
		
		if ResourceLoader.exists(path, "DynamicFont"):
			return load(path) as DynamicFont
	
	return null


# Apply the pixel-perfect scale mode to the display.
func _apply_pixel_perfect() -> void:
	var window_size: Vector2 = OS.window_size
	var viewport_scale: float = floor(
			min(window_size.x / _resolution.x, window_size.y / _resolution.y))
	
	if viewport_scale < 1.0:
		return
	
	var viewport_size: Vector2 = _resolution * viewport_scale
	var viewport_position: Vector2 = ((window_size - viewport_size) * 0.5).floor()
	var margin_l: int = int(max(0.0, viewport_position.x))
	var margin_t: int = int(max(0.0, viewport_position.y))
	var margin_r: int = int(max(0.0, window_size.x - viewport_size.x)) - margin_l
	var margin_b: int = int(max(0.0, window_size.y - viewport_size.y)) - margin_t
	get_tree().root.set_attach_to_screen_rect(Rect2(viewport_position, viewport_size))
	VisualServer.black_bars_set_margins(margin_l, margin_t, margin_r, margin_b)


# Run when the font size changes in the configuration bus. Change the size of
# custom fonts.
func _on_font_size_changed(value: int) -> void:
	if value < 15:
		value = 15
	elif value > 25:
		value = 25
	
	for path in _custom_fonts:
		_custom_fonts[path].size = value
	
	_set_font_family(ConfigBus.get_string("font.family", "coldnight"))
	ConfigBus.set_int("font.size", value) # Round to int.


# Run when the fullscreen state changes in the configuration bus. Set whether
# the window is fullscreen.
func _on_fullscreen_changed(value: bool) -> void:
	OS.window_fullscreen = value
	
	if not value and _is_awaiting_scale_change:
		_is_awaiting_scale_change = false
		_set_window_scale(ConfigBus.get_int("display.window_scale", _default_window_scale))
	
	if ConfigBus.get_string("display.scale_mode") == "pixel":
		_set_handling_resize(not value)
		_apply_pixel_perfect()


# Run when the vsync state changes in the configuration bus. Set whether vsync
# is enabled.
func _on_vsync_changed(value: bool) -> void:
	OS.vsync_enabled = value


# Run when the pixel snap state changes in the configuration bus. Set whether
# pixel snapping is enabled.
func _on_pixel_snap_changed(value: bool) -> void:
	get_tree().set_screen_stretch(
			SceneTree.STRETCH_MODE_VIEWPORT if value else SceneTree.STRETCH_MODE_2D,
			SceneTree.STRETCH_ASPECT_IGNORE if ConfigBus.get_string(
					"display.scale_mode") == "stretch" else SceneTree.STRETCH_ASPECT_KEEP,
			_resolution)
	
	if ConfigBus.get_string("display.scale_mode") == "pixel":
		_apply_pixel_perfect()


# Run when the scale mode changes in the configuration bus. Set the scale mode.
func _on_scale_mode_changed(value: String) -> void:
	var stretch_mode: int = (
			SceneTree.STRETCH_MODE_VIEWPORT if ConfigBus.get_bool("display.pixel_snap")
			else SceneTree.STRETCH_MODE_2D)
	
	if value == "stretch":
		_set_handling_resize(false)
		get_tree().set_screen_stretch(stretch_mode, SceneTree.STRETCH_ASPECT_IGNORE, _resolution)
	elif value == "aspect":
		_set_handling_resize(false)
		get_tree().set_screen_stretch(stretch_mode, SceneTree.STRETCH_ASPECT_KEEP, _resolution)
	elif value == "pixel":
		get_tree().set_screen_stretch(stretch_mode, SceneTree.STRETCH_ASPECT_KEEP, _resolution)
		_apply_pixel_perfect()
		_set_handling_resize(not ConfigBus.get_bool("display.fullscreen"))
	else:
		ConfigBus.set_string("display.scale_mode", "aspect")
