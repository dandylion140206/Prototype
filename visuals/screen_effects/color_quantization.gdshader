shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture
	: hint_screen_texture, repeat_disable, filter_nearest;

uniform int quantization_mode
	: hint_enum("Shared", "Per Channel") = 0;
uniform int color_space
	: hint_enum("sRGB", "Linear") = 0;
uniform int color_levels : hint_range(2, 32, 1) = 8;
uniform int red_levels : hint_range(2, 32, 1) = 8;
uniform int green_levels : hint_range(2, 32, 1) = 8;
uniform int blue_levels : hint_range(2, 32, 1) = 8;

uniform bool dither_enabled = true;
uniform int dither_mode
	: hint_enum("Bayer 2x2", "Bayer 4x4", "Bayer 8x8", "IGN") = 1;
uniform float dither_strength : hint_range(0.0, 1.0, 0.05) = 1.0;
uniform int dither_scale : hint_range(1, 8, 1) = 1;


float bayer_2x2_value(vec2 position) {
	int x = int(mod(position.x, 2.0));
	int y = int(mod(position.y, 2.0));

	if (y == 0) {
		return x == 0 ? 0.0 : 2.0;
	}

	return x == 0 ? 3.0 : 1.0;
}


float bayer_4x4_value(vec2 position) {
	int x = int(mod(position.x, 4.0));
	int y = int(mod(position.y, 4.0));
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

	return row[x];
}


float bayer_8x8_value(vec2 position) {
	vec2 local_position = mod(position, 4.0);
	vec2 block_position = floor(mod(position, 8.0) / 4.0);

	return (
		bayer_4x4_value(local_position) * 4.0
		+ bayer_2x2_value(block_position)
	);
}


float get_dither_threshold(vec2 fragment_position) {
	vec2 position = floor(
		fragment_position / float(max(dither_scale, 1))
	);

	if (dither_mode == 0) {
		return (bayer_2x2_value(position) + 0.5) / 4.0;
	}

	if (dither_mode == 1) {
		return (bayer_4x4_value(position) + 0.5) / 16.0;
	}

	if (dither_mode == 2) {
		return (bayer_8x8_value(position) + 0.5) / 64.0;
	}

	return fract(
		52.9829189
		* fract(0.06711056 * position.x + 0.00583715 * position.y)
	);
}


float linear_to_srgb_component(float value) {
	if (value <= 0.0031308) {
		return value * 12.92;
	}

	return 1.055 * pow(value, 1.0 / 2.4) - 0.055;
}


float srgb_to_linear_component(float value) {
	if (value <= 0.04045) {
		return value / 12.92;
	}

	return pow((value + 0.055) / 1.055, 2.4);
}


vec3 linear_to_srgb_color(vec3 color) {
	return vec3(
		linear_to_srgb_component(color.r),
		linear_to_srgb_component(color.g),
		linear_to_srgb_component(color.b)
	);
}


vec3 srgb_to_linear_color(vec3 color) {
	return vec3(
		srgb_to_linear_component(color.r),
		srgb_to_linear_component(color.g),
		srgb_to_linear_component(color.b)
	);
}


void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec3 working_color = screen_color.rgb;

	if (color_space == 0) {
		working_color = linear_to_srgb_color(working_color);
	}

	working_color = clamp(working_color, vec3(0.0), vec3(1.0));

	vec3 levels;
	if (quantization_mode == 0) {
		levels = vec3(float(color_levels));
	} else {
		levels = vec3(
			float(red_levels),
			float(green_levels),
			float(blue_levels)
		);
	}

	vec3 divisions = max(levels - vec3(1.0), vec3(1.0));
	float dither_offset = 0.0;

	if (dither_enabled) {
		float threshold = get_dither_threshold(FRAGCOORD.xy);
		dither_offset = (threshold - 0.5) * dither_strength;
	}

	working_color = floor(
		working_color * divisions + vec3(0.5 + dither_offset)
	) / divisions;

	working_color = clamp(working_color, vec3(0.0), vec3(1.0));

	if (color_space == 0) {
		working_color = srgb_to_linear_color(working_color);
	}

	COLOR = vec4(working_color, screen_color.a);
}
