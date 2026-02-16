shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount = 4.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * blur_amount;
    vec4 col = vec4(0.0);

    col += texture(screen_tex, SCREEN_UV + vec2(-size.x, -size.y));
    col += texture(screen_tex, SCREEN_UV + vec2( size.x, -size.y));
    col += texture(screen_tex, SCREEN_UV + vec2(-size.x,  size.y));
    col += texture(screen_tex, SCREEN_UV + vec2( size.x,  size.y));

    COLOR = col * 0.25;
}
