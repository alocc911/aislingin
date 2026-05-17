extends RefCounted

static func get_cutscene_definition(cutscene_id: String) -> Dictionary:
	match cutscene_id:
		"post_tutorial_intro":
			return {
				"id": "post_tutorial_intro",
				"background": LevelConfig.RESORT_SAND_TILE_TEXTURE_PATH,
				"player_sprite": "res://assets/ui/icons/icon_seed.png",
				"other_sprite": "res://assets/ui/icons/icon_gold.png",
				"player_dialogue": "Player dialogue",
				"other_dialogue": "Other dialogue"
			}
		_:
			return {}
