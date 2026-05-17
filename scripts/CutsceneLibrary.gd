extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")

static func get_cutscene_definition(cutscene_id: String) -> Dictionary:
	var dialogue_map: Dictionary = _build_dialogue_map()
	if not dialogue_map.has(cutscene_id):
		return {}
	var entry: Dictionary = dialogue_map[cutscene_id]
	return {
		"id": cutscene_id,
		"background": LevelConfig.RESORT_SAND_TILE_TEXTURE_PATH,
		"player_sprite": "res://assets/ui/icons/icon_seed.png",
		"other_sprite": "res://assets/ui/icons/icon_gold.png",
		"player_dialogue": String(entry.get("player", "")),
		"other_dialogue": String(entry.get("other", ""))
	}

static func _build_dialogue_map() -> Dictionary:
	return {
		"trigger_1": {"other": "[blank]", "player": "There might not be much snow here, but I am ready to slide."},
		"trigger_2": {"other": "I will guide you as I can.", "player": "You are from my homeland and will show me where my wife has been taken."},
		"trigger_3": {"other": "We will find her soon, I promise.", "player": "Where is this you are taking me?"},
		"trigger_4": {"other": "We must find the children and of course, your father.", "player": "I have found you at last."},
		"trigger_5": {"other": "It is good to stay strong.", "player": "I hope we are finding them."},
		"trigger_6": {"other": "They have escaped with our children.", "player": "We have smashed their lair."},
		"trigger_7": {"other": "Hope is most important now.", "player": "We will find them soon."},
		"trigger_8": {"other": "We now have the children.", "player": "We have smashed their lair again."},
		"trigger_9": {"other": "Your father will be appearing soon.", "player": "We are moving forward."},
		"trigger_10": {"other": "Me and the children will go to safety.", "player": "You are not safe here."},
		"trigger_11": {"other": "We must crush the enemy.", "player": "I have found you father."},
		"trigger_12": {"other": "We will return to our homeland.", "player": "We have crushed the invaders."},
		"trigger_13": {"other": "[blank]", "player": "You may have died father, but many others died too."},
		"trigger_14": {"other": "You are here to learn.", "player": "Am I here to crush you?"},
		"trigger_15": {"other": "You have crushed me.", "player": "I need to get on to my journey."},
		"trigger_16": {"other": "Even here you have lost.", "player": "What has happened?"},
		"trigger_17": {"other": "We seek not expansion, but destruction above all!", "player": "Your ambitions have gone too far."},
		"trigger_18": {"other": "Thank you! You have freed us from these slavemasters!", "player": "Your forces are dead."},
		"trigger_19": {"other": "You cannot kill us all.", "player": "How'd you like that?"},
		"trigger_20": {"other": "We laugh at you invaders.", "player": "This is a strategic defeat."},
		"trigger_21": {"other": "Thank you! You have freed us from these slavemasters!", "player": "Your forces are dead."},
		"trigger_22": {"other": "Our armies will roll you over.", "player": "You have been defeated."},
		"trigger_23": {"other": "Watch now as our armies march.", "player": "I will avenge this."},
		"trigger_24": {"other": "Thank you! You have freed us from these slavemasters!", "player": "Your forces are dead."},
		"trigger_25": {"other": "[Boss name] will destroy you!", "player": "I have won."},
		"trigger_26": {"other": "The day of [Boss name] has come!", "player": "I have been crushed."},
		"trigger_27": {"other": "Thank you! You have freed us from these slavemasters!", "player": "Your forces are dead."},
		"trigger_28": {"other": "[Boss Name] isn't scared.", "player": "I am victorious."},
		"trigger_29": {"other": "Weep at the strength of [Boss Name]", "player": "You have withstood me."},
		"trigger_30": {"other": "I must do this.", "player": "Do not die in battle."},
		"trigger_31": {"other": "You are stronger than before.", "player": "We must crush these enemies."},
		"trigger_32": {"other": "[blank]", "player": "My father died heroically."},
	}
