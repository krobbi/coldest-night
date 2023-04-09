extends Cutscene

# Hub Enter Cutscene
# The hub enter cutscene is the cutscene that runs when entering the hub level.

const COUNT_FLAG: String = "test/area_bx/archival_unit_count"
const TERMINAL_FLAG: String = "test/area_bx/hub/has_seen_terminal"
const NORTH_ALMOST_FLAG: String = "test/area_bx/hub/has_seen_north_almost"
const NORTH_COMPLETE_FLAG: String = "test/area_bx/hub/has_seen_north_complete"
const WEST_ALMOST_FLAG: String = "test/area_bx/hub/has_seen_west_almost"
const WEST_COMPLETE_FLAG: String = "test/area_bx/hub/has_seen_west_complete"

const NORTH_TOTAL: int = 10
const WEST_TOTAL: int = NORTH_TOTAL + 6 + 1

@export var _terminal_point_path: NodePath

@onready var _terminal_point: Marker2D = get_node(_terminal_point_path)

# Run the hub enter cutscene.
func run() -> void:
	if has_dialog(TERMINAL_FLAG, get_flag(COUNT_FLAG)):
		freeze()
		
		show()
		speaker("???")
		say(
				"This seems to be some kind of hub area,{p=0.25} "
				+ "but things are much quieter than I thought.")
		say("Anyway,{p=0.25} there should be a save terminal here,{p=0.25} next to the elevator.")
		hide()
		
		path("player", _terminal_point.global_position)
		face("player", -90.0)
		sleep(1.0)
		
		show()
		speaker("???")
		say("Be sure to use it,{p=0.25} you don't want to get caught out!")
		hide()
		
		unfreeze()
	elif has_dialog(NORTH_ALMOST_FLAG, NORTH_TOTAL - 1):
		freeze()
		show()
		
		speaker("???")
		say("It looks like you'll have to go back into the storage area.")
		say("I think you've missed an archival unit.")
		
		hide()
		unfreeze()
	elif has_dialog(NORTH_COMPLETE_FLAG, NORTH_TOTAL):
		freeze()
		show()
		
		speaker("???")
		say("That's all the archival units in storage.")
		say(
				"I've managed to open up the west wing,{p=0.25} "
				+ "there should be a robotics lab in there.")
		
		hide()
		unfreeze()
	elif has_dialog(WEST_ALMOST_FLAG, WEST_TOTAL - 1):
		freeze()
		show()
		
		speaker("???")
		say("There's one more archival unit in the robotics lab.")
		say(
				"It might be in a small annex just past the end of the room,{p=0.25} "
				+ "which you'll need to unlock.")
		say("Otherwise,{p=0.25} you'll just have to look again,{p=0.25} carefully.")
		
		hide()
		unfreeze()
	elif has_dialog(WEST_COMPLETE_FLAG, WEST_TOTAL):
		freeze()
		show()
		
		speaker("???")
		say(
				"That's all the data we needed!{p=0.5} "
				+ "You can make your way out now,{p=0.25} start heading south.")
		say("There's a security checkpoint to the east,{p=0.25} but I can't get that open.")
		say("The elevator's stuck and it's been pretty light on guards too.")
		say("Clearly there's something more going on here.")
		say("I think you should get out quickly,{p=0.25} before everyone comes back.")
		
		hide()
		unfreeze()


# Get whether the hub enter cutscene has a dialog.
func has_dialog(flag: String, count: int) -> bool:
	if get_flag(flag) == 0 and get_flag(COUNT_FLAG) == count:
		set_flag(flag, 1)
		return true
	else:
		return false
