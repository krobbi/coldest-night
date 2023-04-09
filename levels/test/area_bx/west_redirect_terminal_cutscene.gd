extends Cutscene

# West Redirect Terminal Cutscene
# The west redirect terminal cutscene is the cutscene that runs when interacting
# with the west redirect terminal.

const FLAG: String = "test/area_bx/west/barrier_state"

# Run the west redirect terminal cutscene.
func run() -> void:
	freeze()
	show()
	say("Redirect barriers?")
	
	option("Redirect barriers", redirect_option)
	option("Cancel", cancel_option)
	menu()


# Run the redirect option.
func redirect_option() -> void:
	set_flag(FLAG, int(get_flag(FLAG) == 0))
	say("Barriers redirected!")
	hide()
	unfreeze()


# Run the cancel option.
func cancel_option() -> void:
	hide()
	unfreeze()
