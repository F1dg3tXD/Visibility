shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D reveal_texture : source_color;
uniform vec4 modulate_color : source_color = vec4(1.0);

void fragment() {
    vec4 tex = texture(reveal_texture, UV);
    ALBEDO = tex.rgb * modulate_color.rgb;
    ALPHA = tex.a * modulate_color.a;
    EMISSION = ALBEDO;
}