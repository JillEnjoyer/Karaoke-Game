shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;
uniform float blur_radius : hint_range(0.0, 64.0) = 28.0;
uniform float blur_strength : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness : hint_range(0.001, 0.3) = 0.15;
uniform float noise_strength : hint_range(0.0, 2.0) = 1.0;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);
    float radius = blur_amount * 0.75;
    float mask = smoothstep(radius, radius - edge_softness, dist);

    vec2 px = TEXTURE_PIXEL_SIZE * blur_radius;
    vec4 blur = vec4(0.0);

    // stochastic dissociation
    for (int i = 0; i < 24; i++) {
        float angle = rand(uv + float(i)) * 6.283;
        float r = rand(uv * float(i + 3));
        vec2 dir = vec2(cos(angle), sin(angle));
        vec2 jitter = dir * px * (r * blur_strength);
        blur += texture(TEXTURE, uv + jitter);
    }

    blur /= 24.0;

    vec4 original = texture(TEXTURE, uv);

    vec4 mixed = mix(original, blur, blur_strength);

    COLOR = mix(original, mixed, mask);
}
