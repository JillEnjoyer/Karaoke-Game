shader_type canvas_item;

uniform vec2 mouse_position;

void fragment() {
    // Дебаг: Установка цвета на основе mouse_position
    COLOR = vec4(mouse_position, 0.0, 1.0); // Выводим координаты мыши

    // Получаем UV-координаты текстуры
    vec2 uv = UV;
    // Пример деформации, используя mouse_position
    uv += (mouse_position - 0.5) * 0.1; // Смещение UV на основе положения мыши
    COLOR = texture(TEXTURE, uv);
}
