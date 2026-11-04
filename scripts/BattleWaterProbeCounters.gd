extends RefCounted
## Research-only nested inclusive timing and invocation counters.
## Never used by production enemy scripts; consumed only by benchmark subclasses.
static var enabled: bool = false
static var calls: Dictionary = {}
static var inclusive_usec: Dictionary = {}

static func begin() -> void:
	calls.clear()
	inclusive_usec.clear()
	enabled = true

static func finish() -> Dictionary:
	enabled = false
	var times: Dictionary = {}
	for key in inclusive_usec.keys():
		times[key] = snappedf(float(inclusive_usec[key]) / 1000.0, 0.001)
	return {"calls": calls.duplicate(true), "inclusive_ms": times}

static func record(key: String, started_usec: int) -> void:
	calls[key] = int(calls.get(key, 0)) + 1
	inclusive_usec[key] = int(inclusive_usec.get(key, 0)) + Time.get_ticks_usec() - started_usec
