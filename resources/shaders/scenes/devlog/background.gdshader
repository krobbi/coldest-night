shader_type canvas_item;

uniform float speed = 0.2f;
uniform float magnitude = 0.02f;
uniform float wobble = 3.0f;

void fragment(){
	COLOR = texture(TEXTURE, UV + vec2(sin(TIME * speed + UV.y * wobble) * magnitude, 0.0));
}
