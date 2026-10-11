extends Node

class RuntimeTarget extends Node2D:
	var damage_received := 0.0
	var dots := 0
	func take_damage(amount: float, _crit: bool = false, _source: Resource = null, _kind: String = "") -> void:
		damage_received += amount
	func apply_dot(_kind: String, _damage: float, _duration: float, _tick: float, _source: Resource = null) -> void:
		dots += 1
	func is_alive() -> bool:
		return true

class AttackDummy extends Node2D:
	var attack_context: AttackContext
	var direction := Vector2.RIGHT

var failures: Array[String] = []
var recasts: Array[AttackContext] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func capture_recast(_direction: Vector2, context: AttackContext, _metadata: Dictionary) -> void:
	recasts.append(context)

func _ready() -> void:
	check(SolarFlareEvolution.simulate(1).suns == 1, "Solar I creates one sun")
	check(SolarFlareEvolution.simulate(2).sun_shots > 0, "Solar II fires from the sun")
	check(SolarFlareEvolution.simulate(3).supernovas == 1, "Solar III expires in one supernova")
	check(FirewallBreachEvolution.simulate(3).crossing_walls >= 2,
		"Firewall III crosses the arena")
	check(AbsoluteZeroEvolution.simulate(3).max_generation <= AttackContext.MAX_GENERATION,
		"Absolute Zero propagation is bounded")
	check(CloudOutageEvolution.simulate(3).network_pulses == 1,
		"Cloud III pulses the rod network once")
	check(not RansomwareEvolution.can_hijack("boss"), "Ransomware never hijacks bosses")
	check(RansomwareEvolution.hijack_duration("elite", 3) > 0.0,
		"Ransomware III hijacks eligible elites")
	check(DaemonProcessEvolution.simulate(3).child_fields <= DaemonProcessEvolution.FIELD_CAP,
		"Daemon children respect the configured cap")
	check(RecursiveRollbackEvolution.simulate(3).child_boomerangs == 2,
		"Rollback III launches two children")

	for skill_id: String in EvolutionData.BY_SKILL:
		var data := EvolutionData.get_for_skill(skill_id)
		var descriptions := EvolutionData.all_tier_descriptions(skill_id)
		check(descriptions.size() == 3 and descriptions.duplicate().all(func(text): return descriptions.count(text) == 1), "%s exposes three unique tier descriptions" % data.id)
		for tier in range(1, 4):
			var description := EvolutionData.tier_description(data.id, tier)
			check(description.length() >= 20 and not description.to_lower().contains("stronger effect"), "%s tier %d describes observable behavior" % [data.id, tier])
			var behavior := EvolutionData.create_behavior(data.id, tier)
			check(behavior != null and behavior.tier == tier,
				"%s creates a configured tier %d behavior" % [data.id, tier])

	var fireball := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	var target := RuntimeTarget.new()
	target.add_to_group("enemies")
	add_child(target)
	var attack := AttackDummy.new()
	attack.attack_context = AttackContext.root("fireball", 100)
	add_child(attack)
	var solar := SolarFlareEvolution.new()
	solar.configure(3)
	solar.on_hit(fireball, target, attack)
	await get_tree().process_frame
	var suns := get_tree().get_nodes_in_group("evolution_sun")
	check(suns.size() == 1, "Solar Flare creates a real bounded sun node on impact")
	if not suns.is_empty():
		suns[0]._pulse()
	check(target.damage_received > 0.0, "Solar Flare sun deals production damage to nearby enemies")

	var lightning := SkillInstance.new(load("res://resources/skills/lightning_bolt.tres"))
	attack.attack_context = AttackContext.root("lightning_bolt", 101)
	var cloud := CloudOutageEvolution.new()
	cloud.configure(2)
	cloud.on_hit(lightning, target, attack)
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group("evolution_lightning_rod").size() == 1,
		"Cloud Outage tiers I-II create a real lightning rod")

	var poison := SkillInstance.new(load("res://resources/skills/poison_dart.tres"))
	poison.request_recast = capture_recast
	attack.attack_context = AttackContext.root("poison_dart", 102)
	var ransomware := RansomwareEvolution.new()
	ransomware.configure(2)
	ransomware.on_hit(poison, target, attack)
	ransomware.on_kill(poison, target, attack)
	await get_tree().process_frame
	check(target.get_meta("ransomware_carrier", false) and target.dots > 0,
		"Ransomware I marks a visible carrier and applies spreading poison")
	check(recasts.size() > 0 and recasts[0].has_flag("ransomware_death_dart"),
		"Ransomware II fires bounded derived darts on carrier death")

	var frost := SkillInstance.new(load("res://resources/skills/frost_nova.tres"))
	var shatter_target := RuntimeTarget.new()
	shatter_target.add_to_group("enemies")
	shatter_target.global_position = Vector2(12, 0)
	add_child(shatter_target)
	attack.attack_context = AttackContext.root("frost_nova", 103)
	var zero := AbsoluteZeroEvolution.new()
	zero.configure(3)
	zero.on_kill(frost, target, attack)
	check(shatter_target.damage_received > 0.0,
		"Absolute Zero shatters killed enemies into bounded damaging shards")

	var hijacked := EnemyBase.new()
	var former_ally := EnemyBase.new()
	add_child(hijacked)
	add_child(former_ally)
	hijacked.initialize(null)
	former_ally.global_position = Vector2(20, 0)
	hijacked.apply_hijack(1.0)
	var hijack_target := hijacked.get_effective_target()
	check(hijacked.is_hijacked() and hijack_target != null and hijack_target != hijacked
		and hijack_target.is_in_group("enemies"),
		"Ransomware III makes an eligible enemy target another enemy")

	var rollback_skill := SkillInstance.new(load("res://resources/skills/blade_spin.tres"))
	var rollback := Rollback.new()
	rollback.context = AttackContext.root("blade_spin", 104)
	var recursive := RecursiveRollbackEvolution.new()
	recursive.configure(2)
	recursive.on_spawn(rollback_skill, rollback)
	check(rollback.get_meta("recursive_return_mult", 1.0) > 1.0,
		"Recursive Rollback I increases return damage")
	check(rollback.get_meta("recursive_replay_hits", false),
		"Recursive Rollback II enables reverse hit replay")
	for hazard: Node in get_tree().get_nodes_in_group("evolution_hazards"):
		hazard.queue_free()
	for node: Node in [target, shatter_target, hijacked, former_ally, attack]:
		node.queue_free()
	rollback.free()
	await get_tree().process_frame

	if failures.is_empty():
		print("PASS: all seven evolutions expose three bounded runtime tiers")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
