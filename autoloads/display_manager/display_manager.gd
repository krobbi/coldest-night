extends Node

# Display Manager
# The display manager is an autoload scene that controls the state of the
# display. It can be accessed from any script by using `DisplayManager`.

const FONTS_DIR: String = "user://fonts/"
const PALETTE: Dictionary = {
	"black": Color("#0d0709"),
	"white": Color("#f1f2f1"),
	"maroon": Color("#3d0518"),
	"red": Color("#ad1818"),
	"dark_orange": Color("#d94f0c"),
	"orange": Color("ff980e"),
	"yellow": Color("#fff959"),
	"dark_green": Color("#169e26"),
	"green": Color("#8ffa37"),
	"blue": Color("#45c5d9"),
}

var _resolution: Vector2i = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
var _text_themes: Array[Theme] = [
	load("res://resources/themes/dialogs/plain_dialog.tres") as Theme,
	load("res://resources/themes/credits.tres") as Theme,
	load("res://resources/themes/menu_card.tres") as Theme,
	load("res://resources/themes/menu_row.tres") as Theme,
	load("res://resources/themes/popup_text.tres") as Theme,
]
var _custom_fonts: Dictionary = {}

# Run when the display manager enters the scene tree. Set the clear color and
# subscribe the display manager to the configuration bus and refresh the custom
# fonts.
func _ready() -> void:
	RenderingServer.set_default_clear_color(PALETTE.black)
	ConfigBus.subscribe_node_bool("display.fullscreen", _on_fullscreen_changed)
	ConfigBus.subscribe_node_bool("display.vsync", _on_vsync_changed)
	ConfigBus.subscribe_node_bool("display.pixel_snap", _on_pixel_snap_changed)
	ConfigBus.subscribe_node_int("display.window_scale", _set_window_scale)
	ConfigBus.subscribe_node_string("font.family", _on_font_family_changed)
	ConfigBus.subscribe_node_int("font.size", _on_font_size_changed)
	refresh_custom_fonts()


# Run when the display manager receives an input event. Handle controls for
# toggling fullscreen.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		ConfigBus.set_bool("display.fullscreen", not ConfigBus.get_bool("display.fullscreen"))


# Get the display's maximum window scale.
func get_max_window_scale() -> int:
	var max_scale: Vector2i = DisplayServer.screen_get_usable_rect().size / _resolution
	return maxi(mini(max_scale.x, max_scale.y), 1)


# Get a palette color from its color name.
func get_palette_color(color_name: String) -> Color:
	return PALETTE.get(color_name, PALETTE.orange)


# Get a dictionary of color options.
func get_color_options() -> Dictionary:
	var color_options: Dictionary = {}
	
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
	
	for i in range(1, get_max_window_scale() + 1):
		options[tr("OPTION.DISPLAY.WINDOW_SCALE.VALUE").format({"window_scale": i})] = i
	
	return options


# Refresh the list of custom fonts.
func refresh_custom_fonts() -> void:
	_custom_fonts.clear()
	var dir: DirAccess = DirAccess.open(FONTS_DIR)
	
	if dir:
		if dir.list_dir_begin() == OK:
			var file_name: String = dir.get_next()
			
			while not file_name.is_empty():
				_load_font(FONTS_DIR.path_join(file_name))
				file_name = dir.get_next()
		
		dir.list_dir_end()
	
	var font_family: String = ConfigBus.get_string("font.family")
	
	if font_family.begins_with(FONTS_DIR) and not _custom_fonts.has(font_family):
		ConfigBus.set_string("font.family", "coldnight")


# Set the window scale.
func _set_window_scale(value: int) -> void:
	var max_window_scale: int = get_max_window_scale()
	
	if value <= 0 or value > max_window_scale:
		ConfigBus.set_int("display.window_scale", max_window_scale)
		return
	
	if get_window().mode == Window.MODE_WINDOWED:
		var old_size: Vector2i = get_window().size
		var new_size: Vector2i = _resolution * value
		get_window().size = new_size
		get_window().position -= (new_size - old_size) / 2


# Load a font file from its font key. Return `null` if the font file could not
# be loaded.
func _load_font(font_key: String) -> FontFile:
	if font_key.begins_with(FONTS_DIR):
		if _custom_fonts.has(font_key):
			return _custom_fonts[font_key]
		
		var font: FontFile = FontFile.new()
		
		if font.load_dynamic_font(font_key) == OK or font.load_bitmap_font(font_key) == OK:
			_custom_fonts[font_key] = font
			return font
	else:
		for extension in ["otf", "ttf"]:
			var path: String = "res://resources/fonts/%s.%s" % [font_key, extension]
			
			if ResourceLoader.exists(path, "FontFile"):
				return load(path)
	
	return null


# Run when the font family changes in the configuration bus. Change the font
# family.
func _on_font_family_changed(value: String) -> void:
	var font: FontFile = _load_font(value)
	
	if not font:
		ConfigBus.set_string("font.family", "coldnight")
		return
	
	for theme in _text_themes:
		theme.default_font = font
	
	# HACK: Apply font size hack (see below.)
	_on_font_size_changed(ConfigBus.get_int("font.size"))


# Run when the font size changes in the configuration bus. Change the font size.
func _on_font_size_changed(value: int) -> void:
	if value < 15:
		ConfigBus.set_int("font.size", 15)
		return
	elif value > 25:
		ConfigBus.set_int("font.size", 25)
		return
	
	# HACK: Coldnight font is improperly sized. This workaround scales down the
	# actual font size to give it roughly the same apparent size as other fonts.
	# A more correct solution would be to change font itself.
	if ConfigBus.get_string("font.family") == "coldnight":
		value = roundi(value * 16 / 20.0)
	
	for theme in _text_themes:
		theme.default_font_size = value


# Run when the fullscreen state changes in the configuration bus. Set whether
# the window is fullscreen.
func _on_fullscreen_changed(value: bool) -> void:
	if value:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
		_set_window_scale(ConfigBus.get_int("display.window_scale"))


# Run when the vsync state changes in the configuration bus. Set whether vsync
# is enabled.
func _on_vsync_changed(value: bool) -> void:
	if value:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


# Run when the pixel snap state changes in the configuration bus. Set whether
# pixel snapping is enabled.
func _on_pixel_snap_changed(value: bool) -> void:
	if value:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	else:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
