extends RefCounted
class_name RNG
"""
Deterministic RNG helper for reproducible level generation.

All RNG streams are derived from the map seed to ensure the same layout is generated
every time for a given seed and level index. Only the GEN stream is used by
LevelGenerator.
"""

static func make_gen_rng(candidate_seed: int) -> RandomNumberGenerator:
	return _make_rng(_mix_seed(candidate_seed, "GEN"))

static func _mix_seed(base_seed: int, tag: String) -> int:
	var h := int(hash("%d|%s" % [base_seed, tag]))
	h = h & 0x7fffffff
	return h if h != 0 else 1

static func _make_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed_value) & 0x7fffffff
	return rng

# ==================== CONVENIENCE HELPERS ====================

static func randi_range(rng: RandomNumberGenerator, a: int, b: int) -> int:
	return rng.randi_range(a, b)

static func randf_range(rng: RandomNumberGenerator, a: float, b: float) -> float:
	return rng.randf_range(a, b)

static func rand_unit_vec2(rng: RandomNumberGenerator) -> Vector2:
	var t := rng.randf() * TAU
	return Vector2(cos(t), sin(t))
