extends MenuCard

# Advanced Menu Card
# The advanced menu card is a scroll menu card that contains advanced settings.

# Run when the flush NightScript cache button is pressed. Emit the
# `nightscript_flush_cache_request` event.
func _on_flush_nightscript_cache_button_pressed() -> void:
	EventBus.emit_nightscript_flush_cache_request()
