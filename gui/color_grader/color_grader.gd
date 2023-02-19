class_name ColorGrader
extends ColorRect

# Color Grader
# A color grader is a GUI element that applies a color grading shader to all
# canvas items under it.

# Run when the color grader enters the scene tree. Subscribe the color grader to
# the configuration bus.
func _ready() -> void:
	ConfigBus.subscribe_node_string(
			"accessibility.color_grading", self, "_on_color_grading_changed")


# Run when the color grading changes.
func _on_color_grading_changed(value: String) -> void:
	if value == "none":
		hide()
		material.shader = null
		return
	
	var path: String = "res://resources/shaders/gui/color_grader/%s.gdshader" % value
	
	if not ResourceLoader.exists(path, "Shader"):
		ConfigBus.set_string("accessibility.color_grading", "none")
		return
	
	material.shader = load(path)
	show()


# Get a dictionary of color grading options.
static func get_grading_options() -> Dictionary:
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
