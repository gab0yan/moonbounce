shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float aberration = 0.0;
uniform float flash = 0.0;
uniform float vignette = 0.32;
uniform float iris = 1.0;
uniform vec2 iris_center = vec2(0.5, 0.5);
uniform float aspect = 1.7778;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - vec2(0.5);
	vec3 col;
	col.r = texture(screen_tex, uv + d * aberration).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - d * aberration).b;
	float edge = length(d * vec2(1.0, 0.8));
	col *= 1.0 - vignette * smoothstep(0.28, 0.75, edge);
	col = mix(col, vec3(1.0), flash);
	vec2 ic = (uv - iris_center) * vec2(aspect, 1.0);
	float r = iris * 2.2;
	float mask = step(length(ic), r);
	COLOR = vec4(col * mask, 1.0);
}
