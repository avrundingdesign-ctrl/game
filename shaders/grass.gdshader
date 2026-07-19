shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

// Grasbueschel: Wind-Schwanken oben, unten verankert; leichte Farbvariation.

uniform sampler2D blade_texture: source_color, filter_linear_mipmap;
uniform sampler2D opacity_texture: hint_default_white, filter_linear_mipmap;
uniform vec3 base_color: source_color = vec3(0.5, 0.68, 0.4);
uniform vec3 tip_color: source_color = vec3(0.95, 1.0, 0.75);
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
	vec3 blade = texture(blade_texture, UV).rgb;
	ALBEDO = blade * mix(base_color, tip_color, height_factor);
	ALPHA = texture(opacity_texture, UV).r;
	ALPHA_SCISSOR_THRESHOLD = 0.3;
	ROUGHNESS = 0.95;
}
