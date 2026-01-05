shader_type canvas_item;

uniform float blur_amount = 0.0;
uniform vec2 resolution = vec2(1024.0, 1024.0);
uniform float transparency : hint_range(0.0, 1.0) = 0.5;
uniform float scale : hint_range(1.0, 2.0) = 1.8;
uniform float blur_radius : hint_range(0.0, 0.5) = 0.0;

void fragment() {
    // Centring UV relative to the center of the screen and applying scaling
    vec2 uv = (FRAGCOORD.xy / resolution - 1.9) / scale + 0.7;

    vec4 color = vec4(0.0);
    float total = 0.0;

    // length from the center of the screen
    vec2 center = vec2(0.5, 0.5);
    float dist_from_center = distance(uv, center);

    // Reducing bluring strenght based on distance from center
    float current_blur = blur_amount * smoothstep(blur_radius, 0.0, dist_from_center);

    for (float x = -current_blur; x <= current_blur; x++) {
        for (float y = -current_blur; y <= current_blur; y++) {
            vec2 offset = vec2(x, y) / resolution;
            color += texture(TEXTURE, uv + offset);
            total += 1.0;
        }
    }

    color /= total;
    color.a *= transparency;
    COLOR = color;
}
