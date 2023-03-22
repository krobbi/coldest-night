extends Cutscene

# Devlog Cutscene
# The devlog cutscene is the cutscene that runs the devlog.

export(String, FILE, "*.tscn") var _end_scene_path: String

# Run the devlog cutscene.
func run() -> void:
	sleep(1.0)
	
	show()
	say("Sphinx of black quartz,{p=0.25} judge my vow!")
	say("{s=0.1}...")
	hide()
	
	sleep(2.0)
	
	show()
	speaker("Sphinx")
	say("The quick,{p=0.25} brown fox jumps over the lazy dog.")
	hide()
	
	sleep(1.0)
	
	show()
	speaker()
	say("Fascinating advice{s=0.1}...")
	hide()
	
	sleep(1.0)


# Run when the devlog cutscene ends. Exit the devlog scene.
func end() -> void:
	SceneManager.change_scene(_end_scene_path)
