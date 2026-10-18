extends Node

class FakePlayer extends Node2D:
	var current_hp := 100.0
	var max_hp := 100.0
	func try_spend_artifact_health(percent: float) -> bool:
		current_hp -= max_hp * percent
		return true

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var omen := preload("res://scripts/expedition/blood_omen.gd")
	var profile := ExpeditionProfile.fresh()
	profile.pity_counters[ExpeditionLootRoller.CHASE_PITY_KEY] = 2
	check(not omen.is_available(profile), "Blood Omen is unavailable before three eligible misses")
	var early_session := ExpeditionSession.create(80, "burning_grounds")
	check(not early_session.activate_blood_omen(profile), "Blood Omen cannot activate before first eligibility")
	profile.pity_counters[ExpeditionLootRoller.CHASE_PITY_KEY] = 3
	check(omen.is_available(profile), "Blood Omen becomes available after three misses")
	check(omen.is_available(ExpeditionProfile.from_dict(profile.to_dict())), "Blood Omen availability persists through death and profile reload")
	var session := ExpeditionSession.create(81, "burning_grounds")
	check(not session.blood_omen_active, "Blood Omen is opt-in rather than automatic")
	check(session.activate_blood_omen(profile), "Available Blood Omen can be explicitly activated")
	var omen_hub := ExpeditionHub.new()
	add_child(omen_hub)
	omen_hub.setup(profile, false)
	check(omen_hub.omen_button != null and omen_hub.omen_button.visible and omen_hub.omen_button.text.contains("OFF"), "Hub exposes visible Blood Omen opt-in before a run")
	omen_hub.omen_button.pressed.emit()
	check(omen_hub.omen_button.text.contains("ON"), "Blood Omen opt-in visibly toggles")
	omen_hub.queue_free()
	check(ExpeditionSession.from_dict(session.to_dict()).blood_omen_active, "Blood Omen survives resume and therefore death/restart boundaries")
	profile.owned_artifact_ids.append("bloodwritten_sigil")
	profile.pity_counters[ExpeditionLootRoller.CHASE_PITY_KEY] = 0
	check(not omen.is_available(profile), "Initial Sigil resets Blood Omen availability")
	var codex := ExpeditionCodexUI.new()
	add_child(codex)
	codex.setup(profile)
	check(codex.omen_label.text.contains("FRAGMENTS 0/3"), "Codex shows one clear post-Sigil fragment action")
	codex.queue_free()

	var normal_hits := 0
	var omen_hits := 0
	for value in 10000:
		if ExpeditionLootRoller.roll_chase(value, "normal-%d" % value, 1, {}, false, false).chase_awarded: normal_hits += 1
		if ExpeditionLootRoller.roll_chase(value, "omen-%d" % value, 1, {}, true, false).chase_awarded: omen_hits += 1
	check(normal_hits >= 1350 and normal_hits <= 1650, "Normal Sigil chance remains fifteen percent")
	check(omen_hits > normal_hits and omen_hits <= 3000, "Blood Omen deterministically raises chase odds without guaranteeing them")
	check(ExpeditionLootRoller.roll_chase(1, "guarantee", 1, {ExpeditionLootRoller.CHASE_PITY_KEY: 4}, false, false).chase_awarded, "Fifth-win guarantee remains unchanged")
	var guarantee_profile := ExpeditionProfile.fresh()
	guarantee_profile.pity_counters[ExpeditionLootRoller.CHASE_PITY_KEY] = 4
	var guarantee_reward := ExpeditionLootRoller.roll_chase(1, "guarantee-settle", 1, guarantee_profile.pity_counters, false, false)
	var guarantee_settled := ExpeditionRewardSettlement.apply(guarantee_profile, [guarantee_reward])
	check(guarantee_settled.owned_artifact_ids.has("bloodwritten_sigil") and not omen.is_available(guarantee_settled), "Guaranteed first Sigil resets the Omen display state")
	var pre_owned_miss := ExpeditionLootRoller.roll_chase(8, "pre-owned", 1, {}, false, false)
	var post_owned_miss := ExpeditionLootRoller.roll_chase(8, "post-owned", 1, {}, false, true)
	if pre_owned_miss.chase_awarded or post_owned_miss.chase_awarded:
		pre_owned_miss = ExpeditionLootRoller.roll_chase(999, "pre-owned-miss", 1, {}, false, false)
		post_owned_miss = ExpeditionLootRoller.roll_chase(999, "post-owned-miss", 1, {}, false, true)
	check(int(pre_owned_miss.get("bloodwritten_fragments", 0)) == 0, "No fragment drops before initial Sigil ownership")
	check(int(post_owned_miss.get("bloodwritten_fragments", 0)) == 1, "Eligible miss after ownership grants one fragment")

	ExpeditionManager.profile_path = "res://.godot/blood_omen_profile.json"
	_cleanup()
	ExpeditionManager.start_new_profile()
	ExpeditionManager.profile.owned_artifact_ids = ["bloodwritten_sigil"]
	ExpeditionManager.profile.bloodwritten_fragments = 3
	var variant_codex := ExpeditionCodexUI.new()
	add_child(variant_codex)
	variant_codex.setup(ExpeditionManager.profile)
	check(variant_codex.variant_buttons.size() == 2 and variant_codex.variant_buttons[0].text.contains("12%") and variant_codex.variant_buttons[1].text.contains("5%"), "Codex exposes both Sigil paths with visible tradeoffs")
	var selected_variants: Array[String] = []
	variant_codex.variant_selected.connect(func(id: String) -> void: selected_variants.append(id))
	variant_codex.variant_buttons[1].pressed.emit()
	check(selected_variants == ["hematic_reserve"], "Sigil path control emits an explicit selection")
	variant_codex.queue_free()
	check(ExpeditionManager.select_sigil_variant("crimson_overdrive"), "Three fragments unlock Crimson Overdrive")
	check(ExpeditionManager.profile.selected_sigil_variant == "crimson_overdrive" and ExpeditionManager.profile.bloodwritten_fragments == 0, "Variant selection spends fragments and persists one choice")
	check(not ExpeditionManager.select_sigil_variant("hematic_reserve"), "Sigil variants are mutually exclusive")

	var hooks := ArtifactCombatHooks.new()
	var runtime := ArtifactRuntime.new(ArtifactRegistry.with_defaults(), hooks)
	runtime.setup(["bloodwritten_sigil", "", "", ""], [], self, [], "crimson_overdrive")
	var player := FakePlayer.new()
	add_child(player)
	hooks.emit_event(&"skill_cast", {"player": player})
	check(is_equal_approx(player.current_hp, 88.0), "Crimson Overdrive exposes its twelve-percent health downside")
	player.current_hp = 100.0
	hooks.emit_event(&"skill_cast", {"player": player, "origin_flags": ["secondary_artifact_projectile"]})
	check(player.current_hp == 100.0, "Variant echoes never pay Sigil health twice")
	runtime.teardown()
	runtime.setup(["bloodwritten_sigil", "", "", ""], [], self, [], "hematic_reserve")
	var sigil_behavior: ArtifactBehavior = runtime.behaviors[0]
	check(is_equal_approx(float(sigil_behavior.parameters.hp_cost), 0.05) and is_equal_approx(float(sigil_behavior.parameters.damage_mult), 1.15), "Hematic Reserve has a cheaper cost and visible lower-damage downside")
	runtime.teardown()
	_cleanup()
	print(JSON.stringify({"failures": failures, "normal_hits": normal_hits, "omen_hits": omen_hits}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = ExpeditionManager.profile_path + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
