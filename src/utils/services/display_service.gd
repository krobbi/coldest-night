class_name DisplayService
extends Object

# Display Service
# The display service is a service object that manages applying and storing the
# game's display settings, and controlling the behavior of the display. The
# display service behaves as a proxy to the global preferences service, ensuring
# that the game's applied display settings are synchronized with the user's
# stored display preferences. A global instance of the display service can be
# accessed from any script by using the identifier 'Global.display'.

enum ScaleMode {
	STRETCH, # The viewport fills the entire display.
	ASPECT, # The viewport maintains its aspect ratio.
	PIXEL, # The viewport's pixels maintain an integral scale.
};

var scale_mode: int = ScaleMode.STRETCH setget set_scale_mode;
var window_scale: int = 1 setget set_window_scale;
var fullscreen: bool = ProjectSettings.get_setting(
		"display/window/size/fullscreen"
) setget set_fullscreen;
var resolution: Vector2 = Vector2(
		max(1.0, float(ProjectSettings.get_setting("display/window/size/width"))),
		max(1.0, float(ProjectSettings.get_setting("display/window/size/height")))
);

var _scene_tree: SceneTree;
var _viewport: Viewport;
var _handling_resize: bool = false setget _set_handling_resize;
var _max_window_scale: int = _get_max_window_scale(0.0);
var _default_window_scale: int = _get_max_window_scale(64.0);
var _should_rescale_window: bool = false;

# Constructor. Passes the scene tree to the display service:
func _init(scene_tree_ref: SceneTree) -> void:
	_scene_tree = scene_tree_ref;
	_viewport = _scene_tree.get_root();


# Sets the scale mode of the display:
func set_scale_mode(value: int) -> void:
	if scale_mode == value:
		return;
	
	match value:
		ScaleMode.STRETCH:
			scale_mode = ScaleMode.STRETCH;
			Global.prefs.set_pref("display", "scale_mode", "stretch");
		ScaleMode.PIXEL:
			scale_mode = ScaleMode.PIXEL;
			Global.prefs.set_pref("display", "scale_mode", "pixel");
		ScaleMode.ASPECT, _:
			scale_mode = ScaleMode.ASPECT;
			Global.prefs.set_pref("display", "scale_mode", "aspect");
	
	_update_handling_resize();


# Sets the window scale of the display:
func set_window_scale(value: int) -> void:
	if value < 1:
		value = _default_window_scale;
	elif value > _max_window_scale:
		value = _max_window_scale;
	
	window_scale = value;
	Global.prefs.set_pref("display", "window_scale", window_scale);
	
	if fullscreen:
		_should_rescale_window = true;
	else:
		_should_rescale_window = false;
		OS.set_window_size(resolution * float(window_scale));
		OS.center_window();


# Sets whether the display is fullscreen:
func set_fullscreen(value: bool) -> void:
	if fullscreen == value:
		return;
	
	if value:
		OS.set_borderless_window(true);
		yield(_scene_tree, "idle_frame");
		OS.set_window_fullscreen(false);
		yield(_scene_tree, "idle_frame");
		OS.set_window_fullscreen(true);
		yield(_scene_tree, "idle_frame");
		fullscreen = true;
		Global.prefs.set_pref("display", "display_mode", "fullscreen");
	else:
		yield(_scene_tree, "idle_frame");
		OS.set_window_fullscreen(true);
		yield(_scene_tree, "idle_frame");
		OS.set_window_fullscreen(false);
		OS.set_borderless_window(false);
		fullscreen = false;
		Global.prefs.set_pref("display", "display_mode", "windowed");
		
		if _should_rescale_window:
			_should_rescale_window = false;
			OS.set_window_size(resolution * float(window_scale));
			OS.center_window();
	
	_update_handling_resize();


# Cycles the scale mode of the display:
func cycle_scale_mode() -> void:
	match scale_mode:
		ScaleMode.STRETCH:
			set_scale_mode(ScaleMode.ASPECT);
		ScaleMode.PIXEL:
			set_scale_mode(ScaleMode.STRETCH);
		ScaleMode.ASPECT, _:
			set_scale_mode(ScaleMode.PIXEL);


# Decreases the window scale of the display:
func decrease_window_scale() -> void:
	if window_scale > 1:
		set_window_scale(window_scale - 1);


# Increases the window scale of the display:
func increase_window_scale() -> void:
	if window_scale < _max_window_scale:
		set_window_scale(window_scale + 1);


# Toggles whether the display is fullscreen:
func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen);


# Applies the global preferences to the display service:
func apply_prefs() -> void:
	match Global.prefs.get_pref("display", "scale_mode", "aspect"):
		"stretch":
			set_scale_mode(ScaleMode.STRETCH);
		"pixel":
			set_scale_mode(ScaleMode.PIXEL);
		"aspect", _:
			set_scale_mode(ScaleMode.ASPECT);
	
	set_window_scale(Global.prefs.get_pref("display", "window_scale", 0));
	
	match Global.prefs.get_pref("display", "display_mode", "windowed"):
		"fullscreen":
			set_fullscreen(true);
		"windowed", _:
			set_fullscreen(false);


# Destructor. Stops handling resizing the display:
func destruct() -> void:
	_set_handling_resize(false);


# Sets whether resizing the display is being handled:
func _set_handling_resize(value: bool) -> void:
	if _handling_resize == value:
		return;
	
	if value:
		var error: int = _scene_tree.connect("screen_resized", self, "_apply_scale_mode");
		
		if error == OK:
			_handling_resize = true;
		else:
			print("Failed to handle resizing the display! Error: %d" % error);
	else:
		if _scene_tree.is_connected("screen_resized", self, "_apply_scale_mode"):
			_scene_tree.disconnect("screen_resized", self, "_apply_scale_mode");
		
		_handling_resize = false;


# Gets the maximum integral window scale of the display that can fit on the
# screen, with a given margin on each axis in pixels:
func _get_max_window_scale(margin: float) -> int:
	var max_scale: Vector2 = (OS.get_screen_size() - Vector2(margin, margin)) / resolution;
	return int(max(1.0, floor(min(max_scale.x, max_scale.y))));


# Updates whether resizing the display is being handled based on whether the
# display is fullscreen, and the scale mode of the display:
func _update_handling_resize() -> void:
	_set_handling_resize(not fullscreen and scale_mode != ScaleMode.STRETCH);
	_apply_scale_mode();


# Applies the current scale mode to the display:
func _apply_scale_mode() -> void:
	var window_size: Vector2 = OS.get_window_size();
	
	if scale_mode == ScaleMode.STRETCH:
		_viewport.set_attach_to_screen_rect(Rect2(Vector2.ZERO, window_size));
		VisualServer.black_bars_set_margins(0, 0, 0, 0);
		return;
	
	var scale: float = min(window_size.x / resolution.x, window_size.y / resolution.y);
	
	if scale_mode == ScaleMode.PIXEL:
		scale = max(1.0, floor(scale));
	
	var size: Vector2 = resolution * scale;
	var offset: Vector2 = ((window_size - size) * 0.5).floor();
	_viewport.set_attach_to_screen_rect(Rect2(offset, size));
	
	var margin_l: int = int(max(0.0, offset.x));
	var margin_t: int = int(max(0.0, offset.y));
	var margin_r: int = int(round(window_size.x - size.x - offset.x));
	var margin_b: int = int(round(window_size.y - size.y - offset.y));
	VisualServer.black_bars_set_margins(margin_l, margin_t, margin_r, margin_b);
