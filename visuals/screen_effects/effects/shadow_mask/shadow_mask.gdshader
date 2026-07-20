shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture
	: hint_screen_texture, source_color, repeat_disable, filter_nearest;

uniform int mask_type
	: hint_enum("Dot Aligned", "Dot Staggered", "Slot Aligned", "Slot Staggered (Columns)") = 1;
uniform int mask_scale : hint_range(1, 32, 1) = 2;
uniform float mask_strength : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float mask_brightness : hint_range(0.0, 3.0, 0.05) = 1.0;

uniform float dot_size : hint_range(0.1, 1.0, 0.05) = 0.75;

const float SLOT_WIDTH = 0.75;
const float SLOT_HEIGHT = 2.4;
const float SLOT_GAP_X = 0.25;
const float SLOT_GAP_Y = 0.3;
const float SLOT_CORNER_RADIUS = 0.25;
const float SLOT_EDGE_SOFTNESS = 1.0;


vec3 get_phosphor_color(float index) {
	if (index < 0.5) {
		return vec3(1.0, 0.0, 0.0);
	}

	if (index < 1.5) {
		return vec3(0.0, 1.0, 0.0);
	}

	return vec3(0.0, 0.0, 1.0);
}


float get_rgb_index(float column) {
	return mod(mod(column, 3.0) + 3.0, 3.0);
}


vec3 get_dot_mask(vec2 position, float scale) {
	float row = floor(position.y / scale);
	float is_staggered_row = mask_type == 1 && mod(row, 2.0) > 0.5 ? 1.0 : 0.0;
	float row_offset = is_staggered_row * scale * 0.5;
	float column = floor((position.x - row_offset) / scale);
	float color_column = column - is_staggered_row;
	vec2 local_position = vec2(
		mod(position.x - row_offset, scale),
		mod(position.y, scale)
	);
	vec2 centered_position = local_position / scale - vec2(0.5);
	float radius = dot_size * 0.5;
	float is_lit = step(length(centered_position), radius);

	return get_phosphor_color(get_rgb_index(color_column)) * is_lit;
}


float rounded_box_distance(vec2 position, vec2 half_size, float corner_radius) {
	vec2 distance_to_corner = abs(position) - half_size + corner_radius;

	return (
		length(max(distance_to_corner, vec2(0.0)))
		+ min(max(distance_to_corner.x, distance_to_corner.y), 0.0)
		- corner_radius
	);
}


vec3 get_slot_mask(vec2 position, float scale) {
	float width = SLOT_WIDTH * scale;
	float height = SLOT_HEIGHT * scale;
	float pitch_x = (SLOT_WIDTH + SLOT_GAP_X) * scale;
	float pitch_y = (SLOT_HEIGHT + SLOT_GAP_Y) * scale;
	float triad_width = pitch_x * 3.0;
	float triad = floor(position.x / triad_width);
	float column = floor(position.x / pitch_x);
	float column_offset = (
		mask_type == 3 && mod(triad, 2.0) > 0.5
		? pitch_y * 0.5
		: 0.0
	);

	vec2 local_position = vec2(
		mod(position.x, pitch_x) - width * 0.5,
		mod(position.y - column_offset, pitch_y) - height * 0.5
	);
	float corner_radius = min(width, height) * SLOT_CORNER_RADIUS;
	float distance = rounded_box_distance(
		local_position,
		vec2(width, height) * 0.5,
		corner_radius
	);
	float is_lit = 1.0 - smoothstep(0.0, SLOT_EDGE_SOFTNESS, distance);

	return get_phosphor_color(get_rgb_index(column)) * is_lit;
}


void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	float scale = float(max(mask_scale, 1));
	vec2 pixel_position = floor(FRAGCOORD.xy) + vec2(0.5);
	vec3 mask = mask_type <= 1
		? get_dot_mask(pixel_position, scale)
		: get_slot_mask(pixel_position, scale);
	vec3 masked_color = screen_color.rgb * mask * mask_brightness;

	COLOR = vec4(
		mix(screen_color.rgb, masked_color, mask_strength),
		screen_color.a
	);
}
