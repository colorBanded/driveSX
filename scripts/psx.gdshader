shader_type spatial;
render_mode unshaded, shadows_disabled, depth_draw_never;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform int color_depth : hint_range(1, 8) = 5;
uniform bool dithering = true;
uniform int resolution_scale = 4;

// Function to get dithering pattern value
int dithering_pattern(vec2 fragcoord) {
	// Convert to integer coordinates
	int x = int(mod(fragcoord.x, 4.0));
	int y = int(mod(fragcoord.y, 4.0));

	// Manual lookup since we can't use arrays in GLES2
	if (y == 0) {
		if (x == 0) return -4;
		else if (x == 1) return 0;
		else if (x == 2) return -3;
		else return 1;
	}
	else if (y == 1) {
		if (x == 0) return 2;
		else if (x == 1) return -2;
		else if (x == 2) return 3;
		else return -1;
	}
	else if (y == 2) {
		if (x == 0) return -3;
		else if (x == 1) return 1;
		else if (x == 2) return -4;
		else return 0;
	}
	else { // y == 3
		if (x == 0) return 3;
		else if (x == 1) return -1;
		else if (x == 2) return 2;
		else return -2;
	}
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec2 uv = FRAGCOORD.xy / float(resolution_scale);
	vec3 color = texture(SCREEN_TEXTURE, uv * float(resolution_scale) / VIEWPORT_SIZE).rgb;

	// Convert from [0.0, 1.0] range to [0, 255] range
	vec3 c = round(color * 255.0);

	// Apply the dithering pattern
	if (dithering) {
		float dither_value = float(dithering_pattern(uv));
		c += vec3(dither_value);
	}

	// Truncate from 8 bits to color_depth bits
	// Using bit operations equivalent for GLES2
	float divisor = pow(2.0, float(8 - color_depth));
	c = floor(c / divisor);

	// Convert back to [0.0, 1.0] range
	float max_value = pow(2.0, float(color_depth)) - 1.0;
	ALBEDO = c / max_value;
}