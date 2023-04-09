extends Cutscene

# West Unlock Terminal Cutscene
# The west unlock terminal cutscene is a cutscene that runs when interacting
# with the west unlock terminal.

const FLAG: String = "test/area_bx/west/is_annex_unlocked"

# Run the west unlock terminal cutscene.
func run() -> void:
	freeze()
	show()
	
	if get_flag(FLAG) != 0:
		say("West annex is unlocked.{p=0.5}\nLock annex?")
		option("Lock annex", lock_option)
	else:
		say("West annex is locked.{p=0.5}\nUnlock annex?")
		option("Unlock annex", unlock_option)
	
	option("Cancel", cancel_option)
	menu()


# Run the lock option.
func lock_option() -> void:
	set_flag(FLAG, 0)
	say("Annex locked!")
	hide()
	unfreeze()


# Run the unlock option.
func unlock_option() -> void:
	set_flag(FLAG, 1)
	say("Annex unlocked!")
	hide()
	unfreeze()


# Run the cancel option.
func cancel_option() -> void:
	hide()
	unfreeze()
