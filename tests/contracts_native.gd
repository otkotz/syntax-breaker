extends Node

class TestGame extends GameManager:
	var entered := 0
	func _enter_first_stage() -> void:
		entered += 1

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	MetaProgression.save_path = "res://.godot/contracts_meta_test.json"
	RunManager.save_path = "res://.godot/contracts_run_test.json"
	RunTelemetry.log_directory = "res://.godot/contracts_telemetry_" + Crypto.new().generate_random_bytes(6).hex_encode()
	MetaProgression.region_victories = {}
	var fire := load("res://resources/skills/fireball.tres") as SkillResource
	var blade := load("res://resources/skills/blade_spin.tres") as SkillResource
	check(StarterContracts.is_unlocked("standard") and not StarterContracts.is_unlocked("miner"), "New profile has standard only")
	RunManager.start_run()
	check(not StarterContracts.apply("miner", SkillInstance.new(fire)) and RunManager.gold == 30, "Locked contract cannot alter budget")
	MetaProgression.region_victories = {"burning_grounds": 1}
	MetaProgression.save_progress()
	MetaProgression.region_victories = {}
	MetaProgression.load_progress()
	check(StarterContracts.is_unlocked("miner") and not StarterContracts.is_unlocked("architect"), "First persistent victory unlocks Miner")
	check(not StarterContracts.rejection_reason("miner", blade).is_empty(), "Melee rejects Mine via common support validation")
	check(not StarterContracts.apply("miner", SkillInstance.new(blade)), "Incompatible contract is rejected atomically")
	MetaProgression.region_victories["storm_spire"] = 2
	MetaProgression._sync_contract_supports()
	check(StarterContracts.is_unlocked("architect"), "Three regional wins unlock Architect")
	for id in ["standard", "miner", "architect"]:
		RunManager.start_run()
		var si := SkillInstance.new(fire)
		si.set_rarity_tier("legendary")
		check(StarterContracts.apply(id, si), "Contract applies: " + id)
		check(si.rarity_tier == "common", "Every contract uses common starter")
		check(RunManager.gold + StarterContracts.cost(id) == 30, "Equal starting shop-value budget: " + id)
		check(RunManager.run_stats.gold_earned == 0 and RunManager.run_stats.gold_spent == 0, "Initial allocation is not income or purchase")
		check(not StarterContracts.apply(id, si), "Contract cannot be applied twice")
		if id != "standard":
			check(si.linked_supports.size() == 1 and si.linked_supports[0].id == StarterContracts.definition(id).support, "Support linked before combat")
		RunManager.save_run([{"skill_id": fire.id, "supports": []}])
		RunManager.restore_from_save(RunManager.load_run())
		check(RunManager.run_stats.starter_contract == id and RunManager.gold == 30 - StarterContracts.cost(id), "Contract budget persists on resume")
	RunManager.start_run()
	RunManager.advance_stage()
	check(not StarterContracts.apply("miner", SkillInstance.new(fire)), "Contract cannot be injected mid-run")
	var game := TestGame.new()
	add_child(game)
	game.start_run("burning_grounds")
	var picker := game._ui_layer.get_child(0) as SkillPicker
	picker.selected_contract = "miner"
	picker._populate()
	picker.contract_changed.emit()
	check(picker.offered_skills.all(func(offer): return offer.id != "blade_spin"), "UI does not offer incompatible starter as available")
	picker.skill_chosen.emit(fire, "rare")
	check(game.entered == 1 and game.get_skill_instances()[0].computed_stats.is_mine > 0, "GameManager enters first stage already configured as Mine")
	check(RunManager.run_stats.non_mine_casts == 0 and RunManager.gold == 15, "Miner begins without ordinary cast or free gold")
	check(RunTelemetry.data.metadata.starter_contract == "miner", "Telemetry captures contract for balance cohorts")
	check(RunTelemetry.data.events.filter(func(event): return event.type == "starter_contract").size() == 1, "Allocation event recorded exactly once")
	picker.skill_chosen.emit(fire, "common")
	check(game.entered == 1, "Double selection cannot enter twice or allocate again")
	RunManager.save_run(game._serialize_skills())
	var saved_build := RunManager.load_run()
	RunManager.restore_from_save(saved_build)
	game._deserialize_skills(saved_build.skills)
	check(game.get_skill_instances()[0].computed_stats.is_mine > 0 and RunManager.run_stats.starter_contract == "miner", "Actual serialized starter restores linked Mine and contract")
	RunManager.record_challenge_cast(true)
	RunManager.record_combat_damage(fire, 1.0, false, "direct")
	check(ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("mine_only"), "Mine-only evidence can begin at first combat with this contract")
	RunTelemetry.finish("abandoned", [])
	game.queue_free()
	await get_tree().process_frame
	var real_game := GameManager.new()
	add_child(real_game)
	real_game.start_run("burning_grounds")
	var real_picker := real_game._ui_layer.get_child(0) as SkillPicker
	real_picker.selected_contract = "miner"
	real_picker._populate()
	real_picker.contract_changed.emit()
	real_picker.skill_chosen.emit(fire, "common")
	var caster := real_game._arena.player.get_node("SkillCaster") as SkillCaster
	caster.set_physics_process(false)
	caster._physics_process(0.01)
	check(RunManager.run_stats.mine_casts == 1 and RunManager.run_stats.non_mine_casts == 0, "Actual first arena starts by placing Mine, not ordinary projectiles")
	var placed_mine: WeakRef = weakref(caster._active_mines[0])
	check(caster._active_mines[0].get_parent() == real_game._arena, "Mine is stage-owned, not carried into later arenas")
	RunTelemetry.finish("abandoned", [])
	real_game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	check(placed_mine.get_ref() == null, "Closing arena removes the Mine")
	if failures.is_empty():
		print("PASS: contract unlocks, equal budget, common rarity, compatibility, idempotence, resume and first-stage Mine integration")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
