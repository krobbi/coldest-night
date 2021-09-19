class_name CallRadioInteractable
extends Interactable

# Call Radio Interactable
# A call radio interactable is an interactable that starts a radio call when
# interacted with.

export(String) var key: String;

# Virtual _interact method. Runs when the call radio interactable is interacted
# with. Starts a radio call from the dialog key defined in exported variables:
func _interact() -> void:
	var radio: RadioDialog = Global.provider.get_radio();
	
	if radio == null:
		print("Call radio interactable failed as the radio dialog could not be provided!");
		return;
	
	radio.open(key);
