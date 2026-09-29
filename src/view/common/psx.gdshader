// PS1-style surface: vertices snap to a coarse screen grid (the wobble), and
// a hash of the world position breaks flat colour into grimy blocks, so the
// low-poly geometry needs no textures at all.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float snap = 90.0;
uniform float grime = 0.18;
uniform float emission = 0.0;

varying vec3 world_pos;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 snapped = floor(clip.xy / clip.w * snap) / snap;
	POSITION = vec4(snapped * clip.w, clip.zw);
}

void fragment() {
	float n = hash(floor(world_pos * 5.0));
	vec3 base = albedo.rgb * COLOR.rgb * (1.0 - grime + grime * n);
	ALBEDO = base;
	EMISSION = base * emission;
}
