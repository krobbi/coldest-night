extends StaticBody2D

# Serial Test
# A serial test is an entity used to test serialization and deserialization. A
# serial test can be interacted with to switch between 3 states.

onready var _sprite: Sprite = $Sprite

# Serialize the serial test to a JSON object.
func serialize() -> Dictionary:
	return {"state": _sprite.frame}


# Run when the serial test's interactable is interacted with. Toggle the serial
# test's state.
func _on_interactable_interacted() -> void:
	_sprite.frame = (_sprite.frame + 1) % _sprite.hframes
