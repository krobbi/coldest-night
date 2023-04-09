extends Cutscene

# New Game Cutscene
# The new game cutscene is the cutscene that runs when a new game is started.

@export var _music: AudioStream

# Run the new game cutscene.
func run() -> void:
	show()
	speaker("'The Developer'")
	say(
			"Much of the dialog has been cut for brevity,{p=0.25} "
			+ "or because I wasn't too happy with it.")
	say("I hope you enjoy the demo!")
	hide()
	
	sleep(1.0)
	then(AudioManager.play_music.bind(_music))
	
	show()
	speaker()
	say("{s=0.1}...")
	
	speaker("???")
	say("-So yeah,{p=0.25} that's basically all we need to do.")
	say(
			"Recover some data from these 'archival units'.{p=0.5} "
			+ "I think you'll know when you see one.")
	say("And then we just need to get out of there,{p=0.25} without getting caught of course.")
	say("Are you sure you can handle this?")
	
	speaker()
	say("{s=0.1}...")
	hide()
