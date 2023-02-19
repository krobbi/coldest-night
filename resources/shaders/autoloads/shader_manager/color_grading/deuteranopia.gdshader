shader_type canvas_item;

// Based on https://godotshaders.com/shader/colorblindness-correction-shader/

void fragment(){
	vec4 texel = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	// Convert RGB to long and short cones.
	float l = (17.8824f * texel.r) + (43.5161f * texel.g) + (4.11935f * texel.b);
	//float m = (3.45565f * texel.r) + (27.1554f * texel.g) + (3.86714f * texel.b);
	float s = (0.0299566f * texel.r) + (0.184309f * texel.g) + (1.46709f * texel.b);
	
	// Calculate medium cones (deuteranopia).
	//float l = 2.02344f * m + -2.52581f * s;
	float m = 0.494207f * l + 1.24827f * s;
	//float s = -0.395913f * l + 0.801109f * m;
	
	// Find difference from expected RGB.
	vec4 difference = texel - vec4(
		(0.0809444479f * l) + (-0.130504409f * m) + (0.116721066f * s),
		(-0.0102485335f * l) + (0.0540193266f * m) + (-0.113614708f * s),
		(-0.000365296938f * l) + (-0.00412161469f * m) + (0.693511405f * s),
		0.0f
	);
	
	// Apply color correction.
	COLOR = texel + vec4(
		0.0f,
		(difference.r * 0.7f) + (difference.g * 1.0f),
		(difference.r * 0.7f) + (difference.b * 1.0f),
		0.0f
	);
}
