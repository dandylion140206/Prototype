shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture
	: hint_screen_texture, source_color, repeat_disable, filter_nearest;

uniform int pixel_size : hint_range(1, 32, 1) = 4;


void fragment() {
	float block_size = float(pixel_size);
	vec2 block_origin = floor(FRAGCOORD.xy / block_size) * block_size;
	vec2 pixelated_uv = (block_origin + vec2(block_size * 0.5)) * SCREEN_PIXEL_SIZE;

	COLOR = texture(screen_texture, pixelated_uv);
}
