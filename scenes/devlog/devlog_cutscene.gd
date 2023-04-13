extends Cutscene

# Devlog Cutscene
# The devlog cutscene is the cutscene that runs the devlog.

@export_file("*.tscn") var _exit_scene_path: String
@export var _music: AudioStream
@export var _background: TextureRect
@export var _silhouette: TextureRect

# Run the devlog cutscene.
func run() -> void:
	AudioManager.play_music(_music)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		_background.material = null
	
	show()
	say("It's getting dark.{p=0.5} Do you want to leave?")
	
	option("Yes", leave_option)
	option("No", no_leave_option)
	menu()


# Run the leave option.
func leave_option() -> void:
	say("It's getting cold too.{p=0.5} You best be going.")
	then(SceneManager.change_scene_to_file.bind(_exit_scene_path))


# Run the no leave option.
func no_leave_option() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_silhouette, "position:x", 400.0, 3.0)
	
	if ConfigBus.get_bool("accessibility.reduced_motion"):
		tween.custom_step.call_deferred(3.0)
	
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
	then(SceneManager.change_scene_to_file.bind(_exit_scene_path))
