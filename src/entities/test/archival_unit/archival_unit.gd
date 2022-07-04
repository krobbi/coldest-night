extends Area2D

# Archival Unit
# An archival unit is a collectable test entity that is used to provide a win
# condition for the minimum viable product demo.

export(String) var archival_unit_key: String

var _is_collectable: bool = false

# Virtual _ready method. Runs when the archival unit finishes entering the scene
# tree. Frees the archival unit or plays the archival unit's animation:
func _ready() -> void:
	if Global.save.get_working_data().get_flag("test_archival_unit", archival_unit_key):
		_display_collected()
	else:
		$AnimatedSprite.play()
		_is_collectable = true


# Displays the archival unit as collected:
func _display_collected() -> void:
	$TriggerShape.set_deferred("disabled", true)
	$AnimatedSprite.stop()
	$AnimatedSprite.frame = 0
	modulate = Color("#60ad1818")


# Signal callback for area_entered on the archival unit. Runs when a player's
# triggering enters the archival unit's trigger area. Collects the archival
# unit:
func _on_area_entered(_area: Area2D) -> void:
	if not _is_collectable:
		return
	
	_is_collectable = false
	
	if not archival_unit_key.empty():
		var save_data: SaveData = Global.save.get_working_data()
		save_data.set_flag("test_archival_unit", archival_unit_key, 1)
		save_data.set_flag(
				"test", "archival_unit_count", save_data.get_flag("test", "archival_unit_count") + 1
		)
	
	Global.events.emit_signal(
			"floating_text_display_request", "FLOATING_TEXT.TEST.ARCHIVAL_UNIT", position
	)
	_display_collected()
