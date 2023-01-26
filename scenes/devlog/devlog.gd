extends Control

# Devlog Scene
# The devlog scene is a scene that runs the devlog dialog.

var _has_shown_silhouette: bool = false

# Run when the dialog scene is entered. Play background music, subscribe the
# devlog scene to the event bus, and run the devlog dialog.
func _ready() -> void:
	Global.audio.play_music("devlog")
	EventBus.subscribe_node(
			"dialog_option_pressed", self, "_on_dialog_option_pressed", [], CONNECT_ONESHOT)
	EventBus.emit_nightscript_run_program_request("dialog/devlog")
	
	if Global.config.get_bool("accessibility.reduced_motion"):
		$BackgroundRect.material = null


# Run when a dialog option is pressed. Show the silhouette if the user has
# pressed `No`.
func _on_dialog_option_pressed(index: int) -> void:
	if _has_shown_silhouette or index != 1:
		return
	
	_has_shown_silhouette = true
	var tween: SceneTreeTween = create_tween().set_trans(Tween.TRANS_CUBIC)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property($SilhouetteRect, "rect_position:x", 400.0, 3.0)


# Run when the devlog dialog finishes. Return to the menu scene.
func _on_nightscript_thread_joined() -> void:
	Global.change_scene("menu")
