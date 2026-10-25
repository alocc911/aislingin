extends SceneTree
const InvasionTest = preload("res://scripts/InvasionRulesSelfTest.gd")

func _initialize() -> void:
	var result: Dictionary = InvasionTest.run()
	print("Invasion rules tests: ", JSON.stringify(result))
	quit(0 if bool(result.get("ok", false)) else 1)
