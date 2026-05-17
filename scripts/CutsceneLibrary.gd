extends RefCounted

static func get_cutscene_definition(cutscene_id: String) -> Dictionary:
	match cutscene_id:
		"post_tutorial_intro":
			return {
				"id": "post_tutorial_intro",
				"background": "res://assets/boss/boss_head_face.jpg",
				"player_sprite": "res://assets/ui/icons/icon_seed.png",
				"other_sprite": "res://assets/ui/icons/icon_gold.png",
				"dialogue": ["Test dialogue"]
			}
		_:
			return {}
