shader_type canvas_item;

uniform sampler2D mask;
uniform bool use_mask = true;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if (use_mask) {
		float mask_val = texture(mask, UV).a;
		if (mask_val < 0.5) {
			discard;
		}
	}
	COLOR = tex_color;
}
