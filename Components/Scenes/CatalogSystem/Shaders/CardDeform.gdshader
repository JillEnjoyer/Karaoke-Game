shader_type canvas_item;

uniform vec2 mouse_position;

void fragment() {
    COLOR = vec4(mouse_position, 0.0, 1.0);

    vec2 uv = UV;
    uv += (mouse_position - 0.5) * 0.1;
    COLOR = texture(TEXTURE, uv);
}
