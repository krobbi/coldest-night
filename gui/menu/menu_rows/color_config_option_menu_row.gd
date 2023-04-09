extends ConfigOptionMenuRow

# Color Configuraton Option Menu Row
# A color configuration option menu row is a configuration option menu row that
# configures a color configuration value and displays the configured color.

@onready var _left_color_rect: ColorRect = $LeftColorRect
@onready var _right_color_rect: ColorRect = $RightColorRect

# Run when the color configuration option menu row finishes entering the scene
# tree. Subscribe the color configuration option menu row to the configuration
# bus.
func _ready() -> void:
	super()
	ConfigBus.subscribe_node_string(_config, _on_config_changed)


# Run when the selected option's configuration changes. Update the displayed
# color.
func _on_config_changed(value: String) -> void:
	var color: Color = DisplayManager.get_palette_color(value)
	_left_color_rect.color = color
	_right_color_rect.color = color
