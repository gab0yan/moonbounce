shader_type canvas_item;

const int MAX_LIGHTS = 24;
uniform vec3 lights[24];
uniform int light_count = 1;
uniform vec2 screen_size = vec2(320.0, 180.0);
uniform vec4 dark_color : source_color = vec4(0.0, 0.0, 0.02, 1.0);

void fragment() {
	vec2 px = floor(UV * screen_size) + 0.5;
	float lit = 0.0;
	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= light_count) {
			break;
		}
		float d = distance(px, lights[i].xy);
		float r = lights[i].z; 
		float l = 1.0 - clamp((d - r * 0.6) / (r * 0.4), 0.0, 1.0);
		lit = max(lit, floor(l * 4.0) / 4.0);
	}
	COLOR = vec4(dark_color.rgb, dark_color.a * (1.0 - lit));
}
