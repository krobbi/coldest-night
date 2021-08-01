class_name GlobalSaveManager
extends Object

# Global Save Manager
# The global save manager is a manager that handles a save slot. The global save
# manager can be accessed from any script by using the identifier 'Global.save'.

var _active_slot: SaveSlot = SaveSlot.new(0);

# Gets the currently selected save slot:
func get_active_slot() -> SaveSlot:
	return _active_slot;
