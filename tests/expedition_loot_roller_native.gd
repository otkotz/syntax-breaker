extends Node

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var elite := ExpeditionLootCatalog.get_table("burning_elite")
	var first := ExpeditionLootRoller.roll(elite, 42, "session:elite", "elite", 1, {})
	var second := ExpeditionLootRoller.roll(elite, 42, "session:elite", "elite", 1, {})
	check(first == second, "Same input produces identical loot")
	seed(991)
	var expected_global := randf()
	seed(991)
	ExpeditionLootRoller.roll(elite, 9, "rng-isolation", "elite", 1, {})
	check(is_equal_approx(randf(), expected_global), "Loot rolling does not mutate global RNG")
	check(ExpeditionLootRoller.roll(elite, 1, "wrong-source", "boss", 1, {}).artifact_ids.is_empty(),
		"Wrong source produces explicit no-drop")
	check(ExpeditionLootRoller.roll(elite, 1, "wrong-difficulty", "elite", 0, {}).artifact_ids.is_empty(),
		"Too-low difficulty produces explicit no-drop")
	var seen: Dictionary = {}
	var saw_no_drop := false
	for value in 1000:
		var reward := ExpeditionLootRoller.roll(elite, value, "elite-%d" % value, "elite", 1, {})
		if reward.artifact_ids.is_empty():
			saw_no_drop = true
			check(reward.shard_amount == 2, "Elite no-drop always grants two consolation shards")
		else: seen[reward.artifact_ids[0]] = true
	check(saw_no_drop, "Chance table has an explicit no-drop outcome")
	check(seen.has("fractured_prism") and seen.has("echoing_hourglass"), "Equal-weight entries are both reachable")
	var treasure := ExpeditionLootCatalog.get_table("burning_treasure")
	for value in 1000:
		var treasure_reward := ExpeditionLootRoller.roll(treasure, value, "treasure-%d" % value, "treasure", 1, {})
		if treasure_reward.artifact_ids.is_empty():
			check(treasure_reward.shard_amount == 4, "Treasure no-drop always grants four consolation shards")
			break
	var artifact_hits := 0
	var prism_hits := 0
	var natural_chase_hits := 0
	for value in 10000:
		var simulated := ExpeditionLootRoller.roll(elite, value, "frequency-%d" % value, "elite", 1, {})
		if not simulated.artifact_ids.is_empty():
			artifact_hits += 1
			if simulated.artifact_ids[0] == "fractured_prism": prism_hits += 1
		if ExpeditionLootRoller.roll_chase(value, "frequency-chase-%d" % value, 1, {}).chase_awarded:
			natural_chase_hits += 1
	check(artifact_hits >= 3300 and artifact_hits <= 3700, "10,000-run elite artifact frequency remains near 35 percent")
	check(prism_hits >= 1550 and prism_hits <= 1950, "10,000-run equal-weight Prism frequency remains stable")
	check(natural_chase_hits >= 1350 and natural_chase_hits <= 1650, "10,000-run natural chase frequency remains near 15 percent")
	var boss_set := ExpeditionLootCatalog.get_table("burning_boss_set")
	var partial_owned: Array[String] = ["furnace_heart", "ashen_needle"]
	var protected_first := ExpeditionLootRoller.roll(boss_set, 77, "protected", "boss_set", 1, {}, partial_owned)
	var protected_second := ExpeditionLootRoller.roll(boss_set, 77, "protected", "boss_set", 1, {}, partial_owned)
	check(protected_first == protected_second, "Protected set roll remains deterministic for identical ownership")
	seed(177)
	var protected_global := randf()
	seed(177)
	ExpeditionLootRoller.roll(boss_set, 77, "protected-rng", "boss_set", 1, {}, partial_owned)
	check(is_equal_approx(randf(), protected_global), "Protected weighting does not mutate global RNG")
	var partial_counts := {"furnace_heart": 0, "ashen_needle": 0, "cinder_crown": 0}
	var complete_counts := {"furnace_heart": 0, "ashen_needle": 0, "cinder_crown": 0}
	var complete_owned: Array[String] = ["furnace_heart", "ashen_needle", "cinder_crown"]
	for value in 10000:
		var partial := ExpeditionLootRoller.roll(boss_set, value, "partial-%d" % value, "boss_set", 1, {}, partial_owned)
		var complete := ExpeditionLootRoller.roll(boss_set, value, "complete-%d" % value, "boss_set", 1, {}, complete_owned)
		partial_counts[partial.artifact_ids[0]] += 1
		complete_counts[complete.artifact_ids[0]] += 1
	check(partial_counts.cinder_crown >= 6200 and partial_counts.cinder_crown <= 7100, "Missing Covenant piece receives the expected 4:1 weighting")
	check(partial_counts.furnace_heart > 0 and partial_counts.ashen_needle > 0, "Protection favors but never guarantees the missing piece")
	for artifact_id in complete_counts:
		check(complete_counts[artifact_id] >= 3000 and complete_counts[artifact_id] <= 3700, "Completed Covenant returns %s to equal weight" % artifact_id)
	var treasure_choice := ExpeditionLootRoller.roll(treasure, 101, "forge:treasure", "treasure", 1, {}, [], {"treasure_choice": true})
	var treasure_choice_repeat := ExpeditionLootRoller.roll(treasure, 101, "forge:treasure", "treasure", 1, {}, [], {"treasure_choice": true})
	check(treasure_choice == treasure_choice_repeat and treasure_choice.get("forge_commitment_id") == "treasure_choice", "Treasure Choice alternative is stable across resume")
	check(treasure_choice.get("alternative_reward_id") == "forge:treasure:forge_alternative", "Treasure Choice derives its alternative from a stable suffix")
	check(not treasure_choice.get("alternative_artifact_ids", []).is_empty() and treasure_choice.get("alternative_artifact_ids") != treasure_choice.artifact_ids, "Treasure Choice always adds a distinct usable alternative")
	var ward := ExpeditionLootRoller.roll(treasure, 102, "forge:ward", "treasure", 1, {}, ["fractured_prism"], {"discovery_ward": true})
	check(ward.artifact_ids.is_empty() or ward.artifact_ids[0] != "fractured_prism", "Discovery Ward excludes owned entries once")
	var mark := ExpeditionLootRoller.roll(boss_set, 103, "forge:mark", "boss_set", 1, {}, partial_owned, {"covenant_mark": true})
	check(mark.artifact_ids == ["cinder_crown"] and mark.get("forge_commitment_id") == "covenant_mark", "Covenant Mark deterministically selects a missing piece")
	var guaranteed := ExpeditionLootRoller.roll_chase(1, "boss-guarantee", 1, {"burning_boss_sigil": 4})
	check(guaranteed.artifact_ids == ["bloodwritten_sigil"] and guaranteed.chase_awarded,
		"Fifth eligible victory guarantees the chase item")
	var natural_chase_seen := false
	for value in 1000:
		if ExpeditionLootRoller.roll_chase(value, "boss-%d" % value, 1, {}).chase_awarded:
			natural_chase_seen = true
			break
	check(natural_chase_seen, "The 15 percent natural chase outcome is reachable")
	for sequence in 10000:
		var pity := 0
		var acquired := false
		for victory in 5:
			var reward := ExpeditionLootRoller.roll_chase(sequence, "sim-%d-%d" % [sequence, victory], 1,
				{"burning_boss_sigil": pity})
			if reward.chase_awarded:
				acquired = true
				break
			pity += 1
		if not acquired:
			failures.append("Chase exceeded five victories at sequence %d" % sequence)
			break
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
