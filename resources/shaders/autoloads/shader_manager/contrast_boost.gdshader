shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float magnitude = 1.0;

void fragment(){
	vec4 texel = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = mix(vec4(0.5, 0.5, 0.5, texel.a), texel, magnitude);
}
