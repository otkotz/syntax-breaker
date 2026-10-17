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
		if reward.artifact_ids.is_empty(): saw_no_drop = true
		else: seen[reward.artifact_ids[0]] = true
	check(saw_no_drop, "Chance table has an explicit no-drop outcome")
	check(seen.has("fractured_prism") and seen.has("echoing_hourglass"), "Equal-weight entries are both reachable")
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
