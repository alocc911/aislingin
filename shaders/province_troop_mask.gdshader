shader_type canvas_item;
render_mode unshaded;

// A single cached icon mask is shared by all provinces. White foreground
// receives the node's tint; its black silhouette/outline stays black.
void fragment() {
	vec4 mask = texture(TEXTURE, UV);
	vec4 tint = COLOR;
	COLOR = vec4(tint.rgb * mask.r, tint.a * mask.a);
}
