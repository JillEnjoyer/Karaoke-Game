shader_type canvas_item;

// progress = 0.0 (оригинал), progress = 1.0 (полное матовое марево)
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Размер пиксельного блока для имитации 144p (12.0 - 16.0 — идеально)
uniform float max_pixel_block : hint_range(1.0, 32.0) = 14.0;

// Финальное приглушение яркости
uniform float target_brightness : hint_range(0.0, 1.0) = 0.65;

// Простая функция генерации псевдослучайного шума
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    float dist = distance(UV, vec2(0.5));
    
    // Мягкая маска наплыва круга
    float mask = smoothstep(1.0 - progress, 0.2 - progress, dist);
    
    float block_size = mix(1.0, max_pixel_block, mask);
    
    // 1. ШАГ ПИКСЕЛИЗАЦИИ
    vec2 block_uv = UV;
    if (block_size > 1.05) {
        block_uv = floor(UV / (TEXTURE_PIXEL_SIZE * block_size)) * (TEXTURE_PIXEL_SIZE * block_size);
    }
    
    if (mask <= 0.0001) {
        COLOR = texture(TEXTURE, UV);
    } else {
        // Базовый радиус размытия
        float radius = TEXTURE_PIXEL_SIZE.x * block_size * mask * 2.5;
        
        // Добавляем случайный сдвиг (дизеринг) на основе координат пикселя,
        // чтобы полностью уничтожить геометрическую рябь и "лесенки"
        float noise = rand(UV) * 6.28318; // Случайный угол в радианах
        
        vec4 acc = vec4(0.0);
        
        // 16 умных выборок по спирали с подмешиванием шума.
        // Цвета закручиваются и растворяются в глубокий бесшовный градиент.
        for (int i = 0; i < 16; i++) {
            float angle = float(i) * 2.39996 + noise; // Золотое сечение + шум
            float r = sqrt(float(i) / 16.0) * radius;
            
            vec2 offset = vec2(cos(angle), sin(angle)) * r;
            acc += texture(TEXTURE, block_uv + offset);
        }
        
        vec4 final_color = acc / 16.0;
        
        // 3. ШАГ ЗАТЕМНЕНИЯ
        float current_brightness = mix(1.0, target_brightness, mask);
        final_color.rgb *= current_brightness;
        
        COLOR = final_color;
    }
}