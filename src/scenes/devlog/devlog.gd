extends Control

# Devlog Scene
# The devlog scene is a scene that runs the devlog dialog.

# Virtual _ready method. Runs when the dialog scene is entered. Plays background
# music, connects to the devlog scene to the event bus, and runs the devlog
# dialog:
func _ready() -> void:
	Global.audio.play_music("devlog")
	Global.events.safe_connect(
			"dialog_option_pressed", self, "_on_dialog_option_pressed", [], CONNECT_ONESHOT)
	Global.events.safe_connect(
			"nightscript_thread_finished", self,
			"_on_nightscript_thread_finished", [], CONNECT_ONESHOT)
	Global.events.emit_signal("nightscript_run_program_request", "dialog.devlog")


# Virtual _input method. Runs when an input is received. Triggers the secret
# meow mode:
func _input(_event: InputEvent) -> void:
	if(
			Input.is_key_pressed(KEY_M) and Input.is_key_pressed(KEY_E)
			and Input.is_key_pressed(KEY_O) and Input.is_key_pressed(KEY_W)):
		$SilhouetteRect.texture = load("res://assets/images/scenes/devlog/silhouette_cat.png")


# Signal callback for pressing a dialog option. Runs when a dialog option is
# pressed. Detects when the user chooses 'Yes' in the dialog and shows the
# silhouette:
func _on_dialog_option_pressed(index: int) -> void:
	if index != 0:
		return
	
	var tween: SceneTreeTween = create_tween().set_trans(Tween.TRANS_CUBIC)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property($SilhouetteRect, "rect_position:x", 400.0, 3.0)


# Signal callback for a finished NightScript thread. Runs when the devlog dialog
# finishes. Returns to the menu scene:
func _on_nightscript_thread_finished() -> void:
	Global.change_scene("menu")
