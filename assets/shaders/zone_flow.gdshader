shader_type canvas_item;

uniform vec2 flow_dir = vec2(0.0, -1.0);
uniform vec2 px_size = vec2(32.0, 96.0);
uniform vec4 tint : source_color = vec4(0.55, 0.8, 1.0, 1.0);
uniform float speed = 22.0;
uniform float chevron_gap = 14.0;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 p = floor(UV * px_size);
	vec2 d = normalize(flow_dir);
	vec2 n = vec2(-d.y, d.x);
	float along = dot(p, d);
	float across = dot(p, n);

	float v = along + abs(mod(across, 16.0) - 8.0);
	float arrow = step(mod(v - TIME * speed, chevron_gap), 1.0);

	float lane = floor(across / 4.0);
	float r = hash(lane);
	float dash = step(mod(along - TIME * speed * (1.6 + r) + r * 97.0, 46.0), 5.0);
	float thin = step(mod(across, 4.0), 0.5);          // only 1 px wide
	float streak = step(0.55, r) * dash * thin;

	vec2 edge = min(UV, 1.0 - UV) * px_size;
	float fade = clamp(min(edge.x, edge.y) / 4.0, 0.0, 1.0);

	float a = (0.08 + arrow * 0.30 + streak * 0.35) * fade;
	COLOR = vec4(tint.rgb, a * tint.a);
}
