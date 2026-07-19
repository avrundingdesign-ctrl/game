shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;

// Wasser: sanfte Wellen (Vertex), Tiefenfarbe + Fresnel + Glanz (Fragment)

uniform vec3 shallow_color: source_color = vec3(0.18, 0.42, 0.52);
uniform vec3 deep_color: source_color = vec3(0.05, 0.18, 0.3);
uniform float wave_height = 0.12;
uniform float wave_speed = 1.1;

varying float wave;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wave = sin(world_pos.x * 0.8 + TIME * wave_speed)
		 * cos(world_pos.z * 0.7 + TIME * wave_speed * 0.8);
	VERTEX.y += wave * wave_height;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 color = mix(deep_color, shallow_color, wave * 0.5 + 0.5);
	ALBEDO = mix(color, vec3(0.6, 0.7, 0.75), fresnel * 0.5);
	ROUGHNESS = 0.08;
	METALLIC = 0.1;
	SPECULAR = 0.6;
	ALPHA = clamp(0.75 + fresnel * 0.2, 0.0, 0.92);
	NORMAL = normalize(NORMAL + vec3(wave * 0.08, 0.0, wave * 0.06));
}
