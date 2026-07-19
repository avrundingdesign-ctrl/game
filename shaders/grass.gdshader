shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

// Grasbueschel: Wind-Schwanken oben, unten verankert; leichte Farbvariation.

uniform vec3 base_color: source_color = vec3(0.2, 0.34, 0.12);
uniform vec3 tip_color: source_color = vec3(0.42, 0.52, 0.2);
uniform float sway_strength = 0.25;
uniform float sway_speed = 1.6;

varying float height_factor;

void vertex() {
	height_factor = clamp(VERTEX.y / 0.6, 0.0, 1.0);
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sway = sin(TIME * sway_speed + world_pos.x * 0.35 + world_pos.z * 0.4);
	VERTEX.x += sway * sway_strength * height_factor;
	VERTEX.z += sway * sway_strength * 0.6 * height_factor;
}

void fragment() {
	ALBEDO = mix(base_color, tip_color, height_factor);
	ROUGHNESS = 0.9;
}
