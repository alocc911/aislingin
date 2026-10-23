shader_type canvas_item;
render_mode unshaded;

// Per-province uniform retains the original colored foreground + black outline.
uniform vec4 ink_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// QuadMesh UVs are vertically reversed for MultiMeshInstance2D.
	vec4 mask = texture(TEXTURE, vec2(UV.x, 1.0 - UV.y));
	COLOR = vec4(ink_color.rgb * mask.r, ink_color.a * mask.a);
}
