class_name GlobalDisplayManager
extends Object

# Global Display Manager
# The global display manager is a manager that handles applying and storing the
# game's display settings, and controlling the behavior of the display. It
# behaves as a proxy to the global preferences manager to ensure that the game's
# applied display settings are synchronized with the user's stored display
# preferences. The global display manager can be accessed from any script by
# using the identifier 'Global.display'.

enum ScaleMode {
	STRETCH, # The viewport fills the entire display.
	ASPECT, # The viewport maintains its aspect ratio.
	PIXEL, # 'Pixel-perfect' - The viewport's pixels maintain an integral scale.
};

var window_scale: int = 1 setget set_window_scale;
var scale_mode: int = ScaleMode.STRETCH setget set_scale_mode;
var fullscreen: bool = ProjectSettings.get_setting(
		"display/window/size/fullscreen"
) setget set_fullscreen;

var _resolution: Vector2 = Vector2(
		max(1.0, float(ProjectSettings.get_setting("display/window/size/width"))),
		max(1.0, float(ProjectSettings.get_setting("display/window/size/height")))
);
var _max_window_scale: int = _get_max_window_scale(0.0);
var _default_window_scale: int = _get_max_window_scale(64.0);
var _scene_tree: SceneTree;
var _viewport: Viewport;
var _handling_resize: bool = false;
var _should_apply_window_scale: bool = false;

# Constructor. Passes the scene tree to the global display manager:
func _init(scene_tree_ref: SceneTree) -> void:
	_scene_tree = scene_tree_ref;
	_viewport = _scene_tree.get_root();


# Sets the window scale of the display:
func set_window_scale(value: int) -> void:
	if value < 1:
		value = _default_window_scale;
	elif value > _max_window_scale:
		value = _max_window_scale;
	
	window_scale = value;
	
	if window_scale == _default_window_scale:
		Global.prefs.set_pref("display", "window_scale", "auto");
	elif window_scale == _max_window_scale:
		Global.prefs.set_pref("display", "window_scale", "max");
	else:
		Global.prefs.set_pref("display", "window_scale", window_scale);
	
	if fullscreen:
		_should_apply_window_scale = true;
	else:
		_apply_window_scale();


# Sets the scale mode of the display:
func set_scale_mode(value: int) -> void:
	if scale_mode == value:
		return;
	
	match value:
		ScaleMode.STRETCH:
			scale_mode = ScaleMode.STRETCH;
			Global.prefs.set_pref("display", "scale_mode", "stretch");
			
			_set_handling_resize(false);
		ScaleMode.PIXEL:
			scale_mode = ScaleMode.PIXEL;
			Global.prefs.set_pref("display", "scale_mode", "pixel");
			
			_set_handling_resize(not fullscreen);
		ScaleMode.ASPECT, _:
			scale_mode = ScaleMode.ASPECT;
			Global.prefs.set_pref("display", "scale_mode", "aspect");
			
			_set_handling_resize(not fullscreen);
	
	_apply_scale_mode();


# Sets whether the display is fullscreen:
func set_fullscreen(value: bool) -> void:
	if fullscreen == value:
		return;
	
	# Workaround to fix an unstable fullscreen function. Changing to fullscreen
	# mode sometimes causes a black screen:
	if value:
		fullscreen = true;
		Global.prefs.set_pref("display", "display_mode", "fullscreen");
		
		OS.set_borderless_window(true);
		yield(_scene_tree, "idle_frame");
		OS.set_window_fullscreen(false);
		yield(_scene_tree, "idle_frame");
		OS.set_window_fullscreen(true);
		yield(_scene_tree, "idle_frame");
		
		_set_handling_resize(false);
	else:
		fullscreen = false;
		Global.prefs.set_pref("display", "display_mode", "windowed");
		
		yield(_scene_tree, "idle_frame");
		OS.set_window_fullscreen(true);
		yield(_scene_tree, "idle_frame");
		OS.set_window_fullscreen(false);
		OS.set_borderless_window(false);
		
		if _should_apply_window_scale:
			_apply_window_scale();
		
		_set_handling_resize(scale_mode != ScaleMode.STRETCH);
	
	_apply_scale_mode();


# Decreases the window scale of the display if it is greater than the minimum:
func decrease_window_scale() -> void:
	if window_scale > 1:
		set_window_scale(window_scale - 1);


# Increases the window scale of the display if it is less than the maximum:
func increase_window_scale() -> void:
	if window_scale < _max_window_scale:
		set_window_scale(window_scale + 1);


# Toggles the scale mode of the display:
func toggle_scale_mode() -> void:
	match scale_mode:
		ScaleMode.STRETCH:
			set_scale_mode(ScaleMode.ASPECT);
		ScaleMode.PIXEL:
			set_scale_mode(ScaleMode.STRETCH);
		ScaleMode.ASPECT, _:
			set_scale_mode(ScaleMode.PIXEL);


# Toggles whether the display is fullscreen:
func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen);


# Applies the user's display preferences to the game's display settings:
func apply_prefs() -> void:
	match Global.prefs.get_pref("display", "scale_mode", "aspect"):
		"stretch":
			set_scale_mode(ScaleMode.STRETCH);
		"pixel":
			set_scale_mode(ScaleMode.PIXEL);
		"aspect", _:
			set_scale_mode(ScaleMode.ASPECT);
	
	var window_scale_pref = Global.prefs.get_pref("display", "window_scale", _default_window_scale);
	
	match typeof(window_scale_pref):
		TYPE_INT:
			set_window_scale(window_scale_pref);
		TYPE_REAL:
			if window_scale_pref == INF or window_scale_pref <= 0.0 or is_nan(window_scale_pref):
				set_window_scale(_default_window_scale);
			else:
				set_window_scale(int(max(1.0, round(window_scale_pref))));
		TYPE_STRING:
			match window_scale_pref:
				"auto":
					set_window_scale(_default_window_scale);
				"max":
					set_window_scale(_max_window_scale);
				_:
					set_window_scale(int(window_scale_pref));
		_:
			set_window_scale(_default_window_scale);
	
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
# screen with a given margin on each axis in pixels:
func _get_max_window_scale(margin: float) -> int:
	var max_scale: Vector2 = (OS.get_screen_size() - Vector2(margin, margin)) / _resolution;
	return int(max(1.0, floor(min(max_scale.x, max_scale.y))));


# Applies the current window scale to the display:
func _apply_window_scale() -> void:
	_should_apply_window_scale = false;
	OS.set_window_size(_resolution * float(window_scale));
	OS.center_window();


# Applies the current scale mode to the display:
func _apply_scale_mode() -> void:
	var window_size: Vector2 = OS.get_window_size();
	
	if scale_mode == ScaleMode.STRETCH:
		_viewport.set_attach_to_screen_rect(Rect2(Vector2.ZERO, window_size));
		VisualServer.black_bars_set_margins(0, 0, 0, 0);
		return;
	
	var scale: float = min(window_size.x / _resolution.x, window_size.y / _resolution.y);
	
	if scale_mode == ScaleMode.PIXEL:
		scale = max(1.0, floor(scale));
	
	var size: Vector2 = (_resolution * scale).floor();
	var offset: Vector2 = ((window_size - size) * 0.5).floor();
	_viewport.set_attach_to_screen_rect(Rect2(offset, size));
	
	var margin_l: int = int(max(0.0, offset.x));
	var margin_t: int = int(max(0.0, offset.y));
	var margin_r: int = int(window_size.x - size.x) - margin_l;
	var margin_b: int = int(window_size.y - size.y) - margin_t;
	VisualServer.black_bars_set_margins(margin_l, margin_t, margin_r, margin_b);
