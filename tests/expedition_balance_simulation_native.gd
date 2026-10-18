extends Node

const RUNS := 400
const WINS := 8
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var metrics := {"rooms": 0, "empty_rooms": 0, "new_by_win_5": 0, "new_by_win_8": 0,
		"set_complete": 0, "first_sigil_total": 0, "first_sigil_samples": 0, "shards_earned": 0,
		"shards_spent": 0, "choices": {"echo": 0, "temper": 0, "shatter": 0}, "forge": {"treasure_choice": 0, "discovery_ward": 0, "covenant_mark": 0}}
	for cohort in RUNS:
		_simulate_cohort(cohort, metrics)
	var empty_rate := float(metrics.empty_rooms) / maxf(1.0, float(metrics.rooms))
	var discovery_5_rate := float(metrics.new_by_win_5) / RUNS
	var discovery_8_rate := float(metrics.new_by_win_8) / RUNS
	var set_rate := float(metrics.set_complete) / RUNS
	var first_sigil := float(metrics.first_sigil_total) / maxf(1.0, float(metrics.first_sigil_samples))
	var forge_total := 0
	for count: int in metrics.forge.values(): forge_total += count
	var forge_dominance := 0.0
	for count: int in metrics.forge.values(): forge_dominance = maxf(forge_dominance, float(count) / maxf(1.0, float(forge_total)))
	check(empty_rate == 0.0, "Elite and treasure rooms always produce artifact or shard progress")
	check(discovery_5_rate >= 2.0 and discovery_8_rate >= 3.0, "The first 5-8 victories regularly reveal multiple new artifacts")
	check(set_rate >= 0.80, "Covenant set regularly completes within eight victories")
	check(first_sigil <= 5.0, "First Sigil respects the fifth-victory guarantee")
	check(metrics.choices.echo > 0 and metrics.choices.temper > 0 and metrics.choices.shatter > 0, "Synthetic policies exercise Echo, Temper and Shatter")
	check(metrics.shards_earned > 0 and metrics.shards_spent > 0, "Simulation tracks real shard income and Forge spend")
	check(forge_dominance <= 0.60, "No Forge choice dominates more than sixty percent")
	print(JSON.stringify({"failures": failures, "runs": RUNS, "wins": WINS, "empty_room_rate": empty_rate,
		"new_by_win_5_rate": discovery_5_rate, "new_by_win_8_rate": discovery_8_rate,
		"set_complete_rate": set_rate, "mean_first_sigil_win": first_sigil,
		"choice_counts": metrics.choices, "shards_earned": metrics.shards_earned, "shards_spent": metrics.shards_spent,
		"forge_counts": metrics.forge, "forge_dominance": forge_dominance}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _simulate_cohort(cohort: int, metrics: Dictionary) -> void:
	var profile := ExpeditionProfile.fresh()
	var discoveries_first_5 := 0
	var discoveries_first_8 := 0
	var first_sigil_win := 0
	for win in range(1, WINS + 1):
		_buy_policy_commitment(profile, cohort, metrics)
		var owned_before := profile.owned_artifact_ids.size()
		var rewards: Array[Dictionary] = []
		for source: String in ["elite", "treasure"]:
			var reward := ExpeditionLootRoller.roll(ExpeditionLootCatalog.get_table("burning_" + source), cohort * 100 + win,
				"%d:%d:%s" % [cohort, win, source], source, 1, profile.pity_counters, profile.owned_artifact_ids, profile.forge_commitments)
			metrics.rooms += 1
			if reward.artifact_ids.is_empty() and int(reward.shard_amount) <= 0: metrics.empty_rooms += 1
			rewards.append(reward)
		var set_reward := ExpeditionLootRoller.roll(ExpeditionLootCatalog.get_table("burning_boss_set"), cohort * 100 + win,
			"%d:%d:set" % [cohort, win], "boss_set", 1, profile.pity_counters, profile.owned_artifact_ids, profile.forge_commitments)
		rewards.append(set_reward)
		var chase := ExpeditionLootRoller.roll_chase(cohort * 100 + win, "%d:%d:chase" % [cohort, win], 1,
			profile.pity_counters, false, profile.owned_artifact_ids.has(ExpeditionLootRoller.CHASE_ID))
		rewards.append(chase)
		if bool(chase.chase_awarded) and first_sigil_win == 0: first_sigil_win = win
		var session := ExpeditionSession.create(cohort * 100 + win, "burning_grounds", profile.owned_artifact_ids.slice(0, 4))
		for reward: Dictionary in rewards:
			var artifact_ids: Array = reward.get("artifact_ids", [])
			reward["is_duplicate"] = not artifact_ids.is_empty() and profile.owned_artifact_ids.has(str(artifact_ids[0]))
			session.record_reward(reward)
			for value: Variant in reward.get("forge_commitment_ids", []): profile.forge_commitments.erase(str(value))
			profile.forge_commitments.erase(str(reward.get("forge_commitment_id", "")))
		while not session.unresolved_reward_id.is_empty():
			var pending := session.get_reward(session.unresolved_reward_id)
			if pending.has("alternative_artifact_ids") and not bool(pending.get("choice_selected", false)):
				var alternatives: Array = pending.get("alternative_artifact_ids", [])
				session.resolve_reward(session.unresolved_reward_id, "choose_alternative" if not alternatives.is_empty() and not profile.owned_artifact_ids.has(str(alternatives[0])) else "choose_original")
				continue
			var action := "echo"
			var pending_ids: Array = pending.get("artifact_ids", [])
			var pending_id := str(pending_ids[0]) if not pending_ids.is_empty() else ""
			if bool(pending.get("is_duplicate", false)):
				action = "temper" if session.effective_artifact_ids().has(pending_id) and not session.tempered_artifact_ids.has(pending_id) and (cohort + win) % 2 == 0 else "shatter"
			metrics.choices[action] += 1
			check(session.resolve_reward(session.unresolved_reward_id, action, 0), "Synthetic decision must be valid")
		profile = ExpeditionRewardSettlement.apply(profile, session.pending_rewards)
		var new_count := profile.owned_artifact_ids.size() - owned_before
		if win <= 5: discoveries_first_5 += new_count
		discoveries_first_8 += new_count
	metrics.new_by_win_5 += discoveries_first_5
	metrics.new_by_win_8 += discoveries_first_8
	metrics.set_complete += int(profile.owned_artifact_ids.has("furnace_heart") and profile.owned_artifact_ids.has("ashen_needle") and profile.owned_artifact_ids.has("cinder_crown"))
	if first_sigil_win > 0:
		metrics.first_sigil_total += first_sigil_win
		metrics.first_sigil_samples += 1
	metrics.shards_earned += profile.ember_shards

func _buy_policy_commitment(profile: ExpeditionProfile, cohort: int, metrics: Dictionary) -> void:
	var missing_covenant := 0
	for id: String in ["furnace_heart", "ashen_needle", "cinder_crown"]: missing_covenant += int(not profile.owned_artifact_ids.has(id))
	var scores := {"treasure_choice": 35 + (cohort % 3) * 8,
		"discovery_ward": 55 + (ArtifactCatalog.all_ids().size() - profile.owned_artifact_ids.size()) * 8,
		"covenant_mark": 30 + missing_covenant * 24}
	var selected := ""
	var best := -1
	for id: String in EmberForge.ids():
		var definition := EmberForge.get_commitment(id)
		if profile.forge_commitments.has(id) or profile.ember_shards < int(definition.cost): continue
		if int(scores[id]) > best:
			best = int(scores[id])
			selected = id
	if selected.is_empty(): return
	var cost := int(EmberForge.get_commitment(selected).cost)
	profile.ember_shards -= cost
	profile.forge_commitments[selected] = true
	metrics.shards_spent += cost
	metrics.forge[selected] += 1
