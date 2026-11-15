extends RefCounted
# Fast, two-stage approximation of a real single-shot engagement.
# Reuses the real deterministic formation generator, but NEVER instances a
# scene or runs physics. Probabilities are starting assumptions, not fitted data.
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const RNGScript = preload("res://scripts/RNG.gd")

var _generator = LevelGeneratorScript.new()

func simulate(encounter_seed: int, level: int, actual_troops: int, phase: String, map_type: String, upgrades: Dictionary, skill: float, rng: RandomNumberGenerator) -> Dictionary:
	var n: int = mini(maxi(0, actual_troops), LevelConfig.PROVINCE_PHYSICAL_PIN_LIMIT)
	if n <= 0:
		return {"physical_total": 0, "physical_downed": 0, "strategic_downed": 0, "full_clear": true, "difficulty": 0.0, "full_clear_chance": 1.0}
	# Match LevelGenerator.generate_into: its GEN RNG is reused for both motif
	# generation and pin placement; promotion changes enemy types above the cap.
	var layout_rng: RandomNumberGenerator = RNGScript.make_gen_rng(encounter_seed)
	var layout: Dictionary = _generator._generate_layout_defs(encounter_seed, maxi(1, level), n, layout_rng, phase, map_type)
	var pins: Array[Dictionary] = _generator._place_pins(layout, n, maxi(1, level), layout_rng, phase)
	if actual_troops > pins.size():
		_generator._promote_province_battle_pins(pins, maxi(0, actual_troops - pins.size()), layout_rng)
	n = pins.size()
	if n <= 0:
		return {"physical_total": 0, "physical_downed": 0, "strategic_downed": 0, "full_clear": false, "difficulty": 1.0, "full_clear_chance": 0.0}
	var center: Vector2 = Vector2.ZERO
	var difficult: int = 0
	for p in pins:
		center += Vector2(p.get("pos", Vector2.ZERO))
		if String(p.get("type", LevelConfig.ENEMY_PIN)) != LevelConfig.ENEMY_PIN:
			difficult += 1
	center /= float(n)
	var spread_sq: float = 0.0
	var isolated: int = 0
	for i in range(n):
		var pos: Vector2 = pins[i].get("pos", Vector2.ZERO)
		spread_sq += pos.distance_squared_to(center)
		var nearest_sq: float = INF
		for j in range(n):
			if i == j:
				continue
			nearest_sq = minf(nearest_sq, pos.distance_squared_to(Vector2(pins[j].get("pos", Vector2.ZERO))))
		if n > 1 and nearest_sq > 150.0 * 150.0:
			isolated += 1
	var spread: float = sqrt(spread_sq / float(n))
	var separation: float = clampf((spread - 95.0) / 400.0, 0.0, 1.0)
	var isolation: float = float(isolated) / float(n)
	var obstacle_count: int = int((layout.get("obstacles", []) as Array).size())
	var obstruction: float = clampf(float(obstacle_count) / 12.0, 0.0, 1.0)
	var toughness: float = float(difficult) / float(n)
	var crowding: float = clampf(float(n) / 90.0, 0.0, 1.0)
	# Unlike an independent per-pin roll, the first stage explicitly permits
	# all pins to fall in one cascade on a compact board.
	var difficulty: float = clampf(
		0.08 + 0.18 * crowding + 0.31 * separation + 0.21 * isolation +
		0.11 * obstruction + 0.19 * toughness,
		0.02, 0.98
	)
	var power: float = (
		0.035 * float(upgrades.get("bigger", 0)) +
		0.028 * float(upgrades.get("heavier", 0)) +
		0.028 * float(upgrades.get("forcefield", 0)) +
		0.018 * float(upgrades.get("poison", 0)) +
		0.018 * float(upgrades.get("magnet", 0))
	)
	var effective: float = clampf(difficulty - power - 0.16 * (skill - 0.5), 0.01, 0.99)
	var full_chance: float = clampf(pow(1.0 - effective, 2.6) * 1.05, 0.002, 0.96)
	var physical_downed: int = 0
	var full_clear: bool = rng.randf() < full_chance
	if full_clear:
		physical_downed = n
	else:
		# A failed cascade is still normally productive, not a symmetric
		# bell curve about 50%. Isolated misses remain rare.
		var miss_chance: float = clampf(0.01 + effective * 0.025 - skill * 0.01, 0.002, 0.05)
		if rng.randf() < miss_chance:
			physical_downed = 0
		else:
			var u: float = rng.randf()
			var v: float = rng.randf()
			var partial: float = clampf(
				0.22 + 0.56 * maxf(u, v) + 0.13 * (skill - effective) +
				power * 0.25, 0.04, 0.98
			)
			physical_downed = clampi(roundi(float(n) * partial), 1, n - 1) if n > 1 else 0
	var strategic_downed: int = clampi(roundi(float(actual_troops) * float(physical_downed) / float(n)), 0, actual_troops)
	return {
		"physical_total": n,
		"physical_downed": physical_downed,
		"strategic_downed": strategic_downed,
		"full_clear": physical_downed == n,
		"difficulty": snapped(difficulty, 0.0001),
		"full_clear_chance": snapped(full_chance, 0.0001),
		"motif": String(layout.get("motif", "generic"))
	}
