shader_type canvas_item;

// Jaegerwespen-Halluzination: Bildschirm wabert, Farben verschieben sich.

uniform sampler2D screen_tex: hint_screen_texture, filter_linear;
uniform float intensity: hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv += vec2(sin(uv.y * 22.0 + TIME * 2.8), cos(uv.x * 18.0 + TIME * 2.2)) * 0.012 * intensity;
	vec4 color = texture(screen_tex, uv);
	// Farbkanaele rotieren + leichtes Pulsieren
	color.rgb = mix(color.rgb, color.gbr, 0.45 * intensity);
	color.rgb *= 1.0 + 0.08 * intensity * sin(TIME * 5.0);
	COLOR = color;
}
