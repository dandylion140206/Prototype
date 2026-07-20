shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture
	: hint_screen_texture, repeat_disable, filter_linear;

uniform float threshold : hint_range(0.0, 1.0, 0.01) = 0.75;
uniform float strength : hint_range(0.0, 2.0, 0.05) = 0.5;
uniform float radius : hint_range(0.0, 16.0, 0.5) = 4.0;


vec3 get_highlight_color(vec2 uv) {
	vec3 color = texture(screen_texture, clamp(uv, vec2(0.0), vec2(1.0))).rgb;
	float brightness = max(color.r, max(color.g, color.b));
	float highlight = smoothstep(threshold, 1.0, brightness);

	return color * highlight;
}


void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec2 offset = SCREEN_PIXEL_SIZE * radius;
	vec3 glow_color = get_highlight_color(SCREEN_UV) * 0.25;

	glow_color += get_highlight_color(SCREEN_UV + vec2(offset.x, 0.0)) * 0.125;
	glow_color += get_highlight_color(SCREEN_UV - vec2(offset.x, 0.0)) * 0.125;
	glow_color += get_highlight_color(SCREEN_UV + vec2(0.0, offset.y)) * 0.125;
	glow_color += get_highlight_color(SCREEN_UV - vec2(0.0, offset.y)) * 0.125;

	glow_color += get_highlight_color(SCREEN_UV + offset) * 0.0625;
	glow_color += get_highlight_color(SCREEN_UV + vec2(offset.x, -offset.y)) * 0.0625;
	glow_color += get_highlight_color(SCREEN_UV + vec2(-offset.x, offset.y)) * 0.0625;
	glow_color += get_highlight_color(SCREEN_UV - offset) * 0.0625;

	COLOR = vec4(screen_color.rgb + glow_color * strength, screen_color.a);
}
