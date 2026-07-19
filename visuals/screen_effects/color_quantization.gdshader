shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture
	: hint_screen_texture, repeat_disable, filter_nearest;

uniform int color_levels : hint_range(2, 32, 1) = 8;


void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);

	float divisions = float(max(color_levels - 1, 1));

	screen_color.rgb =
		floor(screen_color.rgb * divisions + 0.5) / divisions;

	COLOR = screen_color;
}
