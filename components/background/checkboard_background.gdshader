shader_type canvas_item;

uniform vec4 dark_color : source_color = vec4(
	0.0627,
	0.0627,
	0.0627,
	1.0
);

uniform vec4 light_color : source_color = vec4(
	0.0941,
	0.0941,
	0.0941,
	1.0
);

uniform float cell_size
	: hint_range(1.0, 512.0, 1.0) = 84.0;

uniform float edge_softness
	: hint_range(0.1, 32.0, 0.1) = 5.0;

uniform vec2 pattern_center = vec2(0.0);

varying vec2 world_position;


void vertex() {
	world_position = (
		MODEL_MATRIX
		* vec4(VERTEX, 0.0, 1.0)
	).xy;
}


void fragment() {
	vec2 pattern_position = (
		world_position
		- pattern_center
	);

	vec2 cell_position = floor(
		pattern_position / cell_size
	);

	float checker = mod(
		cell_position.x + cell_position.y,
		2.0
	);

	vec2 position_in_cell = mod(
		pattern_position,
		cell_size
	);

	vec2 distance_to_edge = min(
		position_in_cell,
		vec2(cell_size) - position_in_cell
	);

	float minimum_edge_distance = min(
		distance_to_edge.x,
		distance_to_edge.y
	);

	float effective_softness = min(
		edge_softness,
		cell_size * 0.5
	);

	float edge_blend = smoothstep(
		0.0,
		effective_softness,
		minimum_edge_distance
	);

	float checker_value = mix(
		0.5,
		checker,
		edge_blend
	);

	COLOR = mix(
		dark_color,
		light_color,
		checker_value
	);
}
