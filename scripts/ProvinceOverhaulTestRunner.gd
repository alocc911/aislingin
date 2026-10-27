extends SceneTree
const ProvinceOverhaulSelfTest = preload("res://scripts/ProvinceOverhaulSelfTest.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var result: Dictionary = ProvinceOverhaulSelfTest.run()
	print("PROVINCE_OVERHAUL_TEST: ", JSON.stringify(result))
	quit(0 if bool(result.get("ok", false)) else 1)
