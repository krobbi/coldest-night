extends Area2D

# Archival Unit
# An archival unit is a collectable test entity that is used to provide a win
# condition for the minimum viable product demo.

export(String) var archival_unit_key: String

var _is_collectable: bool = false

onready var _animated_sprite: AnimatedSprite = $AnimatedSprite

# Run when the archival unit finishes entering the scene tree. Display the
# archival unit as collected or play the archival unit's animation.
func _ready() -> void:
	if Global.save.get_working_data().get_flag("test_archival_unit", archival_unit_key):
		_display_collected()
	else:
		_animated_sprite.play()
		_is_collectable = true


# Display the archival unit as collected.
func _display_collected() -> void:
	$TriggerShape.set_deferred("disabled", true)
	_animated_sprite.stop()
	_animated_sprite.frame = 0
	_animated_sprite.offset.y = -8.0
	$Shadow.hide()
	modulate = Color("#60ad1818")


# Run when a player's triggering area enters the archival unit's trigger area.
# Collect the archival unit.
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
	
	EventBus.emit_floating_text_display_request("FLOATING_TEXT.TEST.ARCHIVAL_UNIT", position)
	_display_collected()
