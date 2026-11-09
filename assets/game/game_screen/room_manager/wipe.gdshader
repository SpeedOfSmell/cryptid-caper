shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool reverse = false;

void fragment() {
    float x = reverse ? 1.0 - UV.x : UV.x;
    COLOR = x < progress ? fade_color : vec4(0.0);
}