class_name RadioDialogOption
extends Label

# Radio Dialog Option Display

export(Color) var color_normal: Color;
export(Color) var color_hover: Color;

onready var _selection_rect: ColorRect = $SelectionRect;

func configure(message: String, count: int, index: int) -> void:
	set_text(message);
	
	var list_height: float = 30.0 * float(count);
	var item_offset: float = float(index) * 30.0;
	
	rect_position.y = -128.0 - list_height + item_offset;


func select() -> void:
	_selection_rect.set_visible(true);
	set_uppercase(true);
	set("custom_colors/font_color", color_hover);

func deselect() -> void:
	_selection_rect.set_visible(false);
	set_uppercase(false);
	set("custom_colors/font_color", color_normal);
