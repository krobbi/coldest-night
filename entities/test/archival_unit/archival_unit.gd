extends Area2D

# Archival Unit
# An archival unit is a collectable test entity that is used to provide a win
# condition for the minimum viable product demo.

var _is_collected: bool = false

# Run when the archival unit finishes entering the scene tree. Play the archival
# unit's animation.
func _ready() -> void:
	$AnimatedSprite.play()


# Run when a player's triggering area enters the archival unit's trigger area.
# Collect the archival unit.
func _on_area_entered(_area: Area2D) -> void:
	if _is_collected:
		return
	
	_is_collected = true
	var save_data: SaveData = Global.save.get_working_data()
	save_data.set_flag(
			"test", "archival_unit_count", save_data.get_flag("test", "archival_unit_count") + 1)
	EventBus.emit_floating_text_display_request("FLOATING_TEXT.TEST.ARCHIVAL_UNIT", position)
	queue_free()
