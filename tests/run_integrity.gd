extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	# Test saves stay in the project cache, never in the player's profile.
	RunManager.save_path = "res://.godot/run_integrity_test.json"
	MetaProgression.save_path = "res://.godot/meta_integrity_test.json"
	MetaProgression.highest_ascension_unlocked = {}
	MetaProgression.region_victories = {}
	MetaProgression.ascension_level = 0
	RunManager.start_run()
	check(RunManager.spend_gold(15) and RunManager.refund_gold(15), "Canceled purchase returns payment")
	check(RunManager.gold == 30 and RunManager.run_stats.gold_earned == 0.0 and RunManager.run_stats.gold_spent == 0, "Refund is not new income or a completed expense")
	check(not RunManager.refund_gold(15), "Refund cannot mint money without a prior expense")
	var cost_shop := Shop.new()
	for upgrade: Dictionary in Shop.STAT_UPGRADES:
		check(upgrade.base_cost >= 30 and upgrade.base_cost <= 45, "First upgrade competes with two to three median-priced ordinary items")
		RunManager.shop_bonuses[upgrade.key] = 0.0
		for purchase in 50:
			var offer := cost_shop._make_stat_upgrade(upgrade)
			check(offer.cost == upgrade.base_cost + purchase * upgrade.cost_step, "Upgrade cost follows purchase count despite float accumulation")
			RunManager.shop_bonuses[upgrade.key] += upgrade.amount
	RunManager.shop_bonuses.clear()
	cost_shop.free()
	var shop_ui := preload("res://scenes/ui/shop.tscn").instantiate() as Shop
	add_child(shop_ui)
	var shop_skills: Array[SkillInstance] = [SkillInstance.new(load("res://resources/skills/fireball.tres"))]
	shop_ui._skill_instances = shop_skills
	var canceled := {"type": "skill", "resource": load("res://resources/skills/lightning_bolt.tres"), "cost": 15, "tier": "common"}
	shop_ui._offerings.append(canceled)
	shop_ui._on_buy(canceled)
	check(RunManager.gold == 15 and shop_ui._pending_skill_instance != null, "Full-slot purchase waits for swap decision")
	var cancel_button := shop_ui.link_container.get_child(shop_ui.link_container.get_child_count() - 1) as Button
	cancel_button.pressed.emit()
	cancel_button.pressed.emit()
	check(RunManager.gold == 30 and RunManager.run_stats.gold_earned == 0.0 and RunManager.run_stats.gold_spent == 0, "Actual cancel UI refunds once without inflating earned/spent")
	check(shop_skills.size() == 1 and shop_skills[0].base.id == "fireball", "Cancel preserves equipped skill")
	shop_ui.queue_free()
	for i in 100:
		RunManager.add_gold(0.49)
	check(RunManager.gold == 79, "Fractional rewards must sum to 49 gold")
	check(RunManager.spend_gold(15), "Purchase should succeed")
	check(RunManager.run_stats.gold_spent == 15, "Spending counter")
	for i in 7:
		RunManager.advance_stage()
	check(RunManager.skill_slots_unlocked == 4, "Fourth slot at depth 7")
	RunManager.sync_health(42.0, 100.0)
	var potion := load("res://resources/consumables/damage_flask.tres") as ConsumableResource
	RunManager.add_consumable(potion)
	RunManager.add_consumable(potion)
	var manager := ConsumableManager.new()
	add_child(manager)
	manager.setup(RunManager.get_consumable_data())
	check(manager.use_consumable(0), "Use first flask")
	check(RunManager.owned_consumables[0].charges == 1, "Persist flask use")
	var skill := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	check(skill.link_support(load("res://resources/supports/mine.tres")), "Link mine")
	check(not skill.link_support(load("res://resources/supports/spell_echo.tres")), "Reject conflicting echo")
	var skill_data: Array[Dictionary] = [{"skill_id": "fireball", "supports": ["mine"], "mutations": [], "tier": "common"}]
	for cycle in 100:
		RunManager.save_run(skill_data)
		var saved := RunManager.load_run()
		RunManager.restore_from_save(saved)
		check(RunManager.current_hp == 42.0 and RunManager.max_hp == 100.0, "Health roundtrip %d" % cycle)
		check(RunManager.gold == 64 and RunManager.gold_fraction < 0.00001, "Gold roundtrip %d" % cycle)
		check(RunManager.owned_consumables.size() == 1 and RunManager.owned_consumables[0].charges == 1, "Consumable roundtrip %d" % cycle)
		check(saved.skills[0].supports == ["mine"], "Build roundtrip %d" % cycle)
	manager.setup(RunManager.get_consumable_data())
	check(manager.use_consumable(0), "Use final flask")
	check(RunManager.owned_consumables.is_empty() and manager.slots.is_empty(), "Empty inventory synchronized")
	RunManager.save_run(skill_data)
	RunManager.restore_from_save(RunManager.load_run())
	check(RunManager.owned_consumables.is_empty(), "Consumed item stays consumed after load")
	var player := preload("res://scenes/player/player.tscn").instantiate() as Player
	add_child(player)
	check(player.current_hp == 42.0, "New arena player retains HP")
	player.set_max_hp(150.0)
	check(player.current_hp == 63.0 and RunManager.current_hp == 63.0, "Max HP preserves health percentage")
	player.queue_free()
	MetaProgression.set_ascension(20, "storm_spire")
	check(MetaProgression.ascension_level == 0, "New region starts at Ascension zero")
	MetaProgression.record_victory("storm_spire", 0)
	MetaProgression.set_ascension(20, "storm_spire")
	check(MetaProgression.ascension_level == 1, "Victory unlocks only next level")
	check(MetaProgression.get_max_ascension("toxic_depths") == 0, "Regional progression independent")
	RunManager.clear_saved_run()
	DirAccess.remove_absolute(MetaProgression.save_path)
	print(JSON.stringify({"save_cycles": 100, "failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
