extends Area2D

# Archival Unit
# An archival unit is a collectable test entity that is used to provide a win
# condition for the minimum viable product demo.

const FLAG: String = "test/area_bx/archival_unit_count"

var _is_collected: bool = false

# Run when the archival unit finishes entering the scene tree. Play the archival
# unit's animation.
func _ready() -> void:
	$AnimatedSprite2D.play()


# Run when a player's triggering area enters the archival unit's trigger area.
# Collect the archival unit.
func _on_area_entered(_area: Area2D) -> void:
	if _is_collected:
		return
	
	_is_collected = true
	var save_data: SaveData = SaveManager.get_working_data()
	save_data.set_flag(FLAG, save_data.get_flag(FLAG) + 1)
	EventBus.floating_text_display_request.emit("FLOATING_TEXT.TEST.ARCHIVAL_UNIT", position)
	queue_free()
