extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

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
		for tier in range(1, 4):
			var behavior := EvolutionData.create_behavior(data.id, tier)
			check(behavior != null and behavior.tier == tier,
				"%s creates a configured tier %d behavior" % [data.id, tier])

	if failures.is_empty():
		print("PASS: all seven evolutions expose three bounded runtime tiers")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
