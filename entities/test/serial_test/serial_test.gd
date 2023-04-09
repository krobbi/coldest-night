extends StaticBody2D

# Serial Test
# A serial test is an entity used to test serialization and deserialization. A
# serial test can be interacted with to switch between 3 states.

@onready var _sprite: Sprite2D = $Sprite2D

# Serialize the serial test to a JSON object.
func serialize() -> Dictionary:
	return {"state": _sprite.frame}


# Deserialize the serial test from a JSON object.
func deserialize(data: Dictionary) -> void:
	_sprite.frame = int(data.get("state", 0))


# Run when the serial test's interactable is interacted with. Toggle the serial
# test's state.
func _on_interactable_interacted() -> void:
	_sprite.frame = (_sprite.frame + 1) % _sprite.hframes
