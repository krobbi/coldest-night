extends CanvasLayer

# Shader Manager
# The shader manager is an autoload scene that handles applying post processing
# shader settings. It can be accessed from any script by using `ShaderManager`.

onready var _color_grading_rect: ColorRect = $ColorGradingRect

# Run when the shader manager finishes entering the scene tree. Subscribe the
# shader manager to the configuration bus.
func _ready() -> void:
	ConfigBus.subscribe_node_string(
			"accessibility.color_grading", self, "_on_color_grading_changed")


# Get a dictionary of color grading options.
func get_color_grading_options() -> Dictionary:
	return {
		"OPTION.ACCESSIBILITY.COLOR_GRADING.NONE": "none",
		"OPTION.ACCESSIBILITY.COLOR_GRADING.HIGH_CONTRAST": "high_contrast",
		"OPTION.ACCESSIBILITY.COLOR_GRADING.PROTANOPIA": "protanopia",
		"OPTION.ACCESSIBILITY.COLOR_GRADING.DEUTERANOPIA": "deuteranopia",
		"OPTION.ACCESSIBILITY.COLOR_GRADING.TRITANOPIA": "tritanopia",
		"OPTION.ACCESSIBILITY.COLOR_GRADING.SWAP_RGB_GBR": "swap_rgb_gbr",
		"OPTION.ACCESSIBILITY.COLOR_GRADING.SWAP_RGB_BRG": "swap_rgb_brg",
		"OPTION.ACCESSIBILITY.COLOR_GRADING.SWAP_RGB_BGR": "swap_rgb_bgr",
	}


# Run when the color grading changes.
func _on_color_grading_changed(value: String) -> void:
	if value == "none":
		_color_grading_rect.hide()
		_color_grading_rect.material.shader = null
		return
	
	var path: String = (
			"res://resources/shaders/autoloads/shader_manager/color_grading/%s.gdshader" % value)
	
	if not ResourceLoader.exists(path, "Shader"):
		ConfigBus.set_string("accessibility.color_grading", "none")
		return
	
	_color_grading_rect.material.shader = load(path)
	_color_grading_rect.show()
