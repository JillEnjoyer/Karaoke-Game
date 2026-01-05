shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 1.0) = 0.6;
uniform float blur_radius : hint_range(0.0, 64.0) = 28.0;
uniform float blur_strength : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness : hint_range(0.001, 0.3) = 0.15;
uniform float wave_strength : hint_range(0.0, 0.2) = 0.05; // wave amplitude
uniform float wave_frequency : hint_range(0.0, 10.0) = 6.0; // wave frequency
uniform float time : hint_range(0.0, 1000.0) = 0.0;

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);
    vec2 dir = uv - center;
    float dist = length(dir);

    // wave mask
    float wave = sin(dist * wave_frequency * 6.283 + time) * wave_strength;
    float radius = blur_amount * 0.75 + wave;

    float mask = smoothstep(radius, radius - edge_softness, dist);

    vec2 px = TEXTURE_PIXEL_SIZE * blur_radius;
    vec4 blur = texture(TEXTURE, uv) * 0.2;
    blur += texture(TEXTURE, uv + px * vec2( 1.0,  0.0)) * 0.12;
    blur += texture(TEXTURE, uv + px * vec2(-1.0,  0.0)) * 0.12;
    blur += texture(TEXTURE, uv + px * vec2( 0.0,  1.0)) * 0.12;
    blur += texture(TEXTURE, uv + px * vec2( 0.0, -1.0)) * 0.12;
    blur += texture(TEXTURE, uv + px * vec2( 1.0,  1.0)) * 0.08;
    blur += texture(TEXTURE, uv + px * vec2(-1.0,  1.0)) * 0.08;
    blur += texture(TEXTURE, uv + px * vec2( 1.0, -1.0)) * 0.08;
    blur += texture(TEXTURE, uv + px * vec2(-1.0, -1.0)) * 0.08;
    blur += texture(TEXTURE, uv + px * vec2( 2.0,  0.0)) * 0.04;
    blur += texture(TEXTURE, uv + px * vec2(-2.0,  0.0)) * 0.04;
    blur += texture(TEXTURE, uv + px * vec2( 0.0,  2.0)) * 0.04;
    blur += texture(TEXTURE, uv + px * vec2( 0.0, -2.0)) * 0.04;

    vec4 original = texture(TEXTURE, uv);
    vec4 mixed = mix(original, blur, blur_strength);

    COLOR = mix(original, mixed, mask);
}
