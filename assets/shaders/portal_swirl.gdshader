// Written with AI assistance (Claude).
// Pixel-art portal: a bright oval rim with a swirling inside.
// spin = 1 turns one way (entry), -1 the other way (exit).
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.76, 0.37, 0.7, 1.0);
uniform vec2 px_size = vec2(16.0, 32.0);
uniform float spin = 1.0;

void fragment() {
	vec2 cell = (floor(UV * px_size) + 0.5) / px_size;   // snap to whole pixels
	vec2 p = cell * 2.0 - 1.0;                           // -1..1 across the portal
	float r = length(p);
	float ang = atan(p.y, p.x);

	float rim = step(0.72, r) * step(r, 0.98);
	float swirl = 0.5 + 0.5 * sin(ang * 3.0 + r * 7.0 - TIME * 5.0 * spin);
	float inside = step(r, 0.72) * (0.25 + 0.55 * swirl * (1.0 - r * 0.6));

	float a = max(rim * (0.75 + 0.25 * sin(TIME * 4.0)), inside);
	a = floor(a * 5.0) / 5.0;                             // few alpha steps = pixel look
	vec3 col = mix(tint.rgb, vec3(1.0), rim * 0.45 + swirl * inside * 0.3);
	COLOR = vec4(col, a);
}
