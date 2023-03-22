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
	say("What is your favorite fruit?")
	
	option("Apple", "end", ["crunchy"])
	option("Orange", "end", ["juicy"])
	option("Other", "end", ["mysterious"])
	menu()


# End the devlog cutscene.
func end(fruit_description: String) -> void:
	say("Ah,{p=0.25} so %s!" % fruit_description)
	say("An excellent choice.")
	hide()
	sleep(1.0)
	
	show()
	speaker()
	say("(You feel satisfied with your choice.)")
	hide()
	
	sleep(1.0)
	then("change_scene", [_end_scene_path], SceneManager)
