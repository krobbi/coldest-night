shader_type canvas_item;

void fragment(){
	vec4 texel = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = mix(vec4(0.5, 0.5, 0.5, texel.a), texel, 1.5);
}
