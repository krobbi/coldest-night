extends Cutscene

# Devlog Cutscene
# The devlog cutscene is the cutscene that runs the devlog.

export(String, FILE, "*.tscn") var _exit_scene_path: String
export(AudioStream) var _music: AudioStream
export(NodePath) var _background_path: NodePath
export(NodePath) var _silhouette_path: NodePath

onready var _background: TextureRect = get_node(_background_path)
onready var _silhouette: TextureRect = get_node(_silhouette_path)

# Run the devlog cutscene.
func run() -> void:
	AudioManager.play_music(_music)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		_background.material = null
	
	show()
	say("It's getting dark.{p=0.5} Do you want to leave?")
	
	option("Yes", "option_leave")
	option("No", "option_no_leave")
	menu()


# Run the leave option.
func option_leave() -> void:
	say("It's getting cold too.{p=0.5} You best be going.")
	then("change_scene", [_exit_scene_path], SceneManager)


# Run the no leave option.
func option_no_leave() -> void:
	var tween: SceneTreeTween = create_tween().set_trans(Tween.TRANS_CUBIC)
	# warning-ignore: RETURN_VALUE_DISCARDED
	tween.tween_property(_silhouette, "rect_position:x", 400.0, 3.0)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		tween.custom_step(3.0) # warning-ignore: RETURN_VALUE_DISCARDED
	
	say("You relax,{p=0.25} but suddenly a figure appears,{p=0.25} half-materialized.")
	say("Although this seems very unusual,{p=0.25} it doesn't shock you.")
	
	speaker("'The Developer'")
	say("Hey.{p=0.5} I'm back again.")
	say("I know you're not here for my ramblings,{p=0.25} so I'll just get on with it.")
	
	say("I haven't written a devlog yet.{p=0.5} You'll need to wait for the update to release.")
	say(
			"I'm aiming to tidy up my code and scale back my premature "
			+ "optimization,{p=0.25} particularly in the build process.")
	say("I can give you more details soon.")
	
	say("That's all for now.{p=0.5} I hope to see you again soon.")
	say("Goodbye,{p=0.25} and thanks for playing!")
	then("change_scene", [_exit_scene_path], SceneManager)
