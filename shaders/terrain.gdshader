shader_type spatial;

// Terrain-Splat: 5 PBR-Schichten, geblendet ueber Vertex-Farben
// (R = Erde/Plateau, G = Gras/Wald, B = Fels, A = Sand) + Noise-Variation.

uniform sampler2D dirt_albedo: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_normal: hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_albedo: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal: hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_albedo: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_normal: hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_albedo: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_normal: hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_albedo: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_normal: hint_normal, filter_linear_mipmap, repeat_enable;

uniform float uv_scale = 0.16;

varying vec3 world_pos;
varying vec4 blend_weights;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	blend_weights = COLOR;
}

void fragment() {
	vec2 uv = world_pos.xz * uv_scale;
	vec4 w = blend_weights;
	w /= max(w.r + w.g + w.b + w.a, 0.001);

	// Gras-Schicht: organischer Wechsel zwischen Wiese und Waldboden
	float forest_mix = smoothstep(0.35, 0.65, value_noise(world_pos.xz * 0.025));
	vec3 grass_layer = mix(texture(grass_albedo, uv).rgb, texture(forest_albedo, uv).rgb, forest_mix);
	vec3 grass_layer_normal = mix(texture(grass_normal, uv).rgb, texture(forest_normal, uv).rgb, forest_mix);

	// Erde warm toenen (hartgestampfter Arenaboden)
	vec3 albedo = texture(dirt_albedo, uv).rgb * vec3(1.2, 1.02, 0.82) * w.r
		+ grass_layer * w.g
		+ texture(rock_albedo, uv).rgb * w.b
		+ texture(sand_albedo, uv).rgb * w.a;

	vec3 normal_map = texture(dirt_normal, uv).rgb * w.r
		+ grass_layer_normal * w.g
		+ texture(rock_normal, uv).rgb * w.b
		+ texture(sand_normal, uv).rgb * w.a;

	// Grossflaechige Helligkeitsvariation gegen sichtbares Kacheln
	float variation = value_noise(world_pos.xz * 0.012) * 0.25 + 0.875;

	ALBEDO = albedo * variation;
	NORMAL_MAP = normal_map;
	NORMAL_MAP_DEPTH = 0.8;
	ROUGHNESS = 0.9 * w.r + 0.95 * w.g + 0.8 * w.b + 0.85 * w.a;
	SPECULAR = 0.2;
}
