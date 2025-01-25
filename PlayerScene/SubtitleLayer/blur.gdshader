shader_type canvas_item;

uniform int blur_size : hint_range(0.0, 20.0);  // Размер размытия

void fragment() {
    vec4 color = vec4(0.0);
    float total = 0.0;

    // Применяем размытие, выбирая соседние пиксели
    for (int x = -blur_size; x <= blur_size; x++) {
        for (int y = -blur_size; y <= blur_size; y++) {
            vec2 offset = vec2(float(x), float(y)) / vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
            color += texture(TEXTURE, SCREEN_UV + offset);
            total += 1.0;
        }
    }

    color /= total;  // Усредняем цвет

    COLOR = color;
}
