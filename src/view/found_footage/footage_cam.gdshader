// The camcorder's eye over the whole screen. Standby: the picture as it is,
// grainy and vignetted. Recording: green night vision - luminance lifted and
// tinted - with scanlines and heavier, crawling noise.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float recording = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float lum = dot(c, vec3(0.3, 0.59, 0.11));
	vec3 night = vec3(0.35, 1.0, 0.4) * (pow(lum, 0.7) * 1.6 + 0.05);
	vec3 col = mix(c * 1.6, night, recording);
	float noise = hash(floor(FRAGCOORD.xy / 3.0) + floor(TIME * 24.0)) - 0.5;
	float scan = 1.0 - recording * 0.18 * step(0.5, fract(FRAGCOORD.y / 4.0));
	col = col * scan + noise * mix(0.04, 0.1, recording);
	vec2 d = UV - 0.5;
	col *= 1.0 - dot(d, d) * 1.4;
	COLOR = vec4(col, 1.0);
}
