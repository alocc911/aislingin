extends RefCounted
## Shared alpha-visible bounds for imported sprite textures.
## Unlike Image.load_from_file(path), Texture2D.get_image() works with
## Godot's resource-imported textures inside the browser export.
static var _visible_rect_by_texture_rid: Dictionary = {}


static func visible_region(texture: Texture2D) -> Rect2:
	if texture == null:
		return Rect2()
	var fallback := Rect2(Vector2.ZERO, texture.get_size())
	var key: RID = texture.get_rid()
	if _visible_rect_by_texture_rid.has(key):
		return _visible_rect_by_texture_rid[key]
	var region: Rect2 = fallback
	var image: Image = texture.get_image()
	if image != null and not image.is_empty():
		if image.is_compressed():
			if image.decompress() != OK:
				_visible_rect_by_texture_rid[key] = region
				return region
		var used_rect: Rect2i = image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			region = Rect2(used_rect.position, used_rect.size)
	_visible_rect_by_texture_rid[key] = region
	return region
