shader_type canvas_item;
render_mode unshaded;

// 色
uniform vec4 center_color : source_color = vec4(0.05, 0.32, 0.55, 0.92);
uniform vec4 edge_color : source_color = vec4(0.05, 0.75, 1.0, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.35, 0.95, 1.0, 1.0);

// 形状
uniform float base_radius : hint_range(0.20, 0.90, 0.001) = 0.68;
uniform float wobble_amount : hint_range(0.0, 0.20, 0.001) = 0.055;
uniform float wobble_speed : hint_range(0.0, 30.0, 0.1) = 1.0;
uniform float rim_width : hint_range(0.001, 0.20, 0.001) = 0.045;

// 立体感
uniform float center_gradient : hint_range(0.05, 1.0, 0.01) = 0.80;
uniform float rim_strength : hint_range(0.0, 1.0, 0.01) = 0.75;
uniform float highlight_size : hint_range(0.05, 1.20, 0.01) = 0.55;
uniform float highlight_strength : hint_range(0.0, 1.0, 0.01) = 0.22;

float get_wobble(float angle, float time) {
	float wave = 0.0;
	wave += sin(angle * 3.0 + time * 0.73);
	wave += sin(angle * 5.0 - time * 1.07 + 1.8) * 0.55;
	wave += sin(angle * 8.0 + time * 1.37 + 0.4) * 0.25;
	return wave / 1.8;
}

void fragment() {
	vec2 position = (UV - vec2(0.5)) * 2.0;
	float distance_from_center = length(position);
	float angle = atan(position.y, position.x);
	float time = TIME * wobble_speed;

	// 方向ごとに半径を変化させる
	float radius_offset = get_wobble(angle, time) * wobble_amount;
	float distorted_radius = base_radius + radius_offset;
	float signed_distance = distance_from_center - distorted_radius;

	// 輪郭のアンチエイリアス
	float antialias_width = max(fwidth(signed_distance) * 1.5, 0.001);
	float body_mask = 1.0 - smoothstep(-antialias_width, antialias_width, signed_distance);

	// 縁から中心に向かって色を変化させる
	float depth = clamp((distorted_radius - distance_from_center) / distorted_radius, 0.0, 1.0);
	float center_mix = smoothstep(0.0, center_gradient, depth);
	vec3 final_color = mix(edge_color.rgb, center_color.rgb, center_mix);

	// 左上のハイライト
	vec2 highlight_position = vec2(-0.22, -0.25);
	float highlight_distance = length(position - highlight_position);
	float highlight = 1.0 - smoothstep(0.0, highlight_size, highlight_distance);
	final_color += highlight_color.rgb * highlight * highlight_strength;

	// 輪郭付近の発光
	float rim = 1.0 - smoothstep(0.0, rim_width, abs(signed_distance));
	final_color = mix(final_color, edge_color.rgb, rim * rim_strength);

	COLOR = vec4(final_color, body_mask * center_color.a);
}
