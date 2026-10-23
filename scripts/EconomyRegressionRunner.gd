extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var report: Dictionary = ProvinceOverhaulSelfTest.run()
	print("ECONOMY REGRESSION: ", JSON.stringify(report))
	quit(0 if bool(report.get("ok", false)) else 1)
