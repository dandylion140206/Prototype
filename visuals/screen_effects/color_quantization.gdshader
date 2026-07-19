shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture
	: hint_screen_texture, repeat_disable, filter_nearest;

uniform int color_levels : hint_range(2, 32, 1) = 8;
uniform bool dither_enabled = true;
uniform float dither_strength : hint_range(0.0, 1.0, 0.05) = 1.0;


float get_bayer_4x4(vec2 pixel_position) {
	int x = int(mod(pixel_position.x, 4.0));
	int y = int(mod(pixel_position.y, 4.0));
	vec4 row;

	if (y == 0) {
		row = vec4(0.0, 8.0, 2.0, 10.0);
	} else if (y == 1) {
		row = vec4(12.0, 4.0, 14.0, 6.0);
	} else if (y == 2) {
		row = vec4(3.0, 11.0, 1.0, 9.0);
	} else {
		row = vec4(15.0, 7.0, 13.0, 5.0);
	}

	return (row[x] + 0.5) / 16.0;
}


void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	float divisions = float(max(color_levels - 1, 1));
	float dither_offset = 0.0;

	if (dither_enabled) {
		float threshold = get_bayer_4x4(FRAGCOORD.xy);
		dither_offset = (threshold - 0.5) * dither_strength;
	}

	screen_color.rgb = floor(
		screen_color.rgb * divisions + 0.5 + dither_offset
	) / divisions;

	COLOR = screen_color;
}
