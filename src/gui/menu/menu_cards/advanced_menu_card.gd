class_name AdvancedMenuCard
extends MenuCard

# Advanced Menu Card
# The advanced menu card is a scroll menu card that contains advanced settings.

# Signal callback for pressed on the flush NightScript cache button. Runs when
# the flush NightScript cache button is pressed. Flushes the NightScript program
# cache:
func _on_flush_nightscript_cache_button_pressed() -> void:
	Global.events.emit_signal("nightscript_flush_cache_request")
