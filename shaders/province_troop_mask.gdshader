shader_type canvas_item;
render_mode unshaded;

// Per-province uniform retains the original colored foreground + black outline.
uniform vec4 ink_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 mask = texture(TEXTURE, UV);
	COLOR = vec4(ink_color.rgb * mask.r, ink_color.a * mask.a);
}
