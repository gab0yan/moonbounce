// Written with AI assistance (Claude).
// The star frames have a dark blue background. This makes that colour see-through,
// so star strips can overlap without drawing boxes over each other.
shader_type canvas_item;

uniform vec3 key_color = vec3(0.0, 0.0627, 0.1255);
uniform float tolerance = 0.03;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (distance(c.rgb, key_color) < tolerance) {
		discard;
	}
	COLOR = c;
}
