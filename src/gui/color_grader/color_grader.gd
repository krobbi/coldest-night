class_name ColorGrader
extends ColorRect

# Color Grader
# A color grader is a GUI element that applies a color grading shader to all
# canvas items under it.

var grading: String = "none" setget set_grading

# Virtual _ready method. Runs when the color grader enters the scene tree.
# Connects the color grader to the configuration bus:
func _ready() -> void:
	Global.config.connect_string("accessibility.color_grading", self, "set_grading")


# Virtual _exit_tree method. Runs when the color grader exits the scene tree.
# Disconnects the color grader from the configuration bus:
func _exit_tree() -> void:
	Global.config.disconnect_value("accessibility.color_grading", self, "set_grading")


# Sets the color grader's grading:
func set_grading(value: String) -> void:
	if grading == value:
		return
	
	var path: String = "res://assets/shaders/post/%s.gdshader" % value
	
	if value == "none" or not ResourceLoader.exists(path, "Shader"):
		grading = "none"
		hide()
		material.shader = null
		return
	
	grading = value
	material.shader = load(path)
	show()


# Gets a dictionary of color grading options:
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
