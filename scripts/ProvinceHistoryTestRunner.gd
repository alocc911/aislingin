extends SceneTree
const HistoryTest = preload("res://scripts/ProvinceHistorySelfTest.gd")

func _initialize() -> void:
	var result: Dictionary = HistoryTest.run()
	print("Province history tests: ", JSON.stringify(result))
	quit(0 if bool(result.get("ok", false)) else 1)
