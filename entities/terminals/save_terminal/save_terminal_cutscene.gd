extends Cutscene

# Save Terminal Cutscene
# The save terminal cutscene is the cutscene runs when interacting with a save
# terminal.

const FLAG: String = "has_seen_save_terminal"

# Run the save terminal cutscene.
func run() -> void:
	freeze()
	show()
	
	if get_flag(FLAG) != 0:
		say("Do you want to save your progress?")
	else:
		say("It's a save terminal.{p=0.5} Do you want to save your progress?")
	
	set_flag(FLAG, 1)
	
	option("Yes", save_option)
	option("No", no_save_option)
	menu()


# Run the save option.
func save_option() -> void:
	SaveManager.save_game()
	say("Your progress has been saved!")
	hide()
	unfreeze()


# Run the no save option.
func no_save_option() -> void:
	hide()
	unfreeze()
