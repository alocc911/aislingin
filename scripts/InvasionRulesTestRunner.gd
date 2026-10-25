extends SceneTree
const InvasionTest = preload("res://scripts/InvasionRulesSelfTest.gd")

func _initialize() -> void:
	var result: Dictionary = InvasionTest.run_phantom_pressure_regression()
	print("Phantom invasion regression: ", JSON.stringify(result))
	quit(0 if bool(result.get("ok", false)) else 1)
