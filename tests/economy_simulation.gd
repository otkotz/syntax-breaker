extends Node

# Economy-only experiment, not a combat bot or a win-rate estimate.
class CatalogShop extends Shop:
	var catalog: Dictionary = {}
	func _load_resources(path: String) -> Array:
		if not catalog.has(path):
			catalog[path] = super._load_resources(path)
		return catalog[path]
	func _refresh_ui() -> void:
		pass

const REGIONS := ["burning_grounds", "storm_spire", "toxic_depths"]
const ASCENSIONS := [0, 5, 10, 20]
const STARTERS := ["fireball", "lightning_bolt", "blade_spin"]
var samples: int = 10000
var experiment_seed: int = 20261003
var output_path: String = "res://.godot/economy_simulation.json"
var rows: Dictionary = {}
var offering_counts: Dictionary = {}
var offering_ids: Dictionary = {}
var offering_prices: Dictionary = {}
var gold_by_role: Dictionary = {}
var failures: Array[String] = []
var shop: CatalogShop
var prototype: Node
var spawner: Spawner

func _ready() -> void:
	call_deferred("run_experiment")

func run_experiment() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			samples = maxi(1, arg.trim_prefix("--runs=").to_int())
		elif arg.begins_with("--seed="):
			experiment_seed = arg.trim_prefix("--seed=").to_int()
		elif arg.begins_with("--output="):
			output_path = arg.trim_prefix("--output=")
	RunManager.save_path = "res://.godot/economy_run_test.json"
	MetaProgression.save_path = "res://.godot/economy_meta_test.json"
	shop = CatalogShop.new()
	# Explicit full-catalog profile; never modify the player's saved unlocks.
	for category in ["skills", "supports", "passives"]:
		MetaProgression.unlocked_items[category] = []
		for resource in shop._load_resources("res://resources/%s/" % category):
			MetaProgression.unlocked_items[category].append(resource.id)
	for region in REGIONS:
		MetaProgression.highest_ascension_unlocked[region] = 20
	prototype = preload("res://scenes/stages/arena.tscn").instantiate()
	spawner = prototype.get_node("Spawner")
	for role in Spawner.ROLE_SCALING:
		var scene := spawner._get_scene_for_role(role)
		if role == "elite":
			scene = spawner.mini_boss_scene
		if scene:
			var enemy := scene.instantiate() as EnemyBase
			gold_by_role[role] = enemy.gold_value
			enemy.free()
	var began := Time.get_ticks_msec()
	for i in samples:
		seed(experiment_seed + i)
		var region: String = REGIONS[i % 3]
		var ascension: int = ASCENSIONS[(i / 3) % 4]
		QualitySettings.entity_mult = 1.0 if (i / 12) % 2 == 0 else 0.5
		var policy := "items_first" if (i / 24) % 2 == 0 else "upgrade_first"
		_simulate_run(region, ascension, policy, i)
		if (i + 1) % 250 == 0:
			if (i + 1) % 1000 == 0:
				print("Economy progress: %d/%d" % [i + 1, samples])
			await get_tree().process_frame
	var results: Array[Dictionary] = []
	for key in rows:
		var row: Dictionary = rows[key]
		var result := {"scenario": key, "runs": row.earned.size()}
		var metrics := ["earned", "spent", "balance", "purchases", "upgrades", "rerolls", "shops"]
		for act in [1, 2, 3]:
			for suffix in ["earned", "spent", "purchases", "upgrades", "rerolls", "balance"]:
				metrics.append("act%d_%s" % [act, suffix])
		for metric in metrics:
			var values: Array = row[metric]
			values.sort()
			result[metric] = {"p10": values[int((values.size() - 1) * 0.1)], "median": values[values.size() / 2], "p90": values[int((values.size() - 1) * 0.9)]}
		result["runs_with_upgrade_pct"] = 100.0 * row.upgrade_runs / row.earned.size()
		result["shops_with_affordable_item_pct"] = 100.0 * row.affordable_visits / maxf(1.0, row.shop_visits)
		result["shops_with_affordable_upgrade_pct"] = 100.0 * row.upgrade_affordable_visits / maxf(1.0, row.shop_visits)
		results.append(result)
	var report := {
		"model_revision": "ascension_opening_roles_v1",
		"runs": samples, "seed": experiment_seed,
		"seconds": (Time.get_ticks_msec() - began) / 1000.0,
		"assumptions": ["Fully unlocked catalog; three common starters", "Uniform random legal route", "Instant clear of every pulse until budget/time expires", "Splitter offspring killed before next pulse; no toxic-boss adds or consumable income", "Actual StageTree, Shop offers/prices, RewardRoller, role selection and gold multipliers", "Treasure chooses 35 gold; boss 5 grants mutation/legendary plus normal boss reward then shop; final boss has no shop", "At most two compatible normal purchases and one upgrade per shop; one reroll only when no normal purchase", "No deaths, damage, healing decisions or win-rate prediction"],
		"stat_upgrade_prices": Shop.STAT_UPGRADES,
		"offering_counts": offering_counts, "offering_ids": offering_ids, "offering_prices": offering_prices, "scenarios": results, "failures": failures,
	}
	var regular_prices: Array[int] = []
	for type in offering_prices:
		if type == "stat_upgrade":
			continue
		for price in offering_prices[type]:
			for occurrence in int(offering_prices[type][price]):
				regular_prices.append(int(price))
	regular_prices.sort()
	if not regular_prices.is_empty():
		var median_price: int = regular_prices[regular_prices.size() / 2]
		report["median_ordinary_offer_price"] = median_price
		report["first_upgrade_item_equivalents"] = {}
		for upgrade in Shop.STAT_UPGRADES:
			report.first_upgrade_item_equivalents[upgrade.key] = float(upgrade.base_cost) / median_price
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	else:
		failures.append("Could not write economy report")
	shop.catalog.clear()
	shop.free()
	prototype.free()
	print("Economy complete: %d runs, %.1fs, %d failures; %s" % [samples, report.seconds, failures.size(), output_path])
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func _simulate_run(region_id: String, ascension: int, policy: String, index: int) -> void:
	RunManager.start_run(region_id, ascension)
	var skills: Array[SkillInstance] = [SkillInstance.new(load("res://resources/skills/%s.tres" % STARTERS[(index / 48) % 3]))]
	var region := load("res://resources/regions/%s.tres" % region_id) as RegionResource
	var tree := StageGenerator.generate_tree(region)
	var key := "%s/A%d/Q%.1f/%s" % [region_id, ascension, QualitySettings.entity_mult, policy]
	if not rows.has(key):
		rows[key] = {"earned": [], "spent": [], "balance": [], "purchases": [], "upgrades": [], "rerolls": [], "shops": [], "act1_balance": [], "act2_balance": [], "act3_balance": [], "upgrade_runs": 0, "affordable_visits": 0, "upgrade_affordable_visits": 0, "shop_visits": 0}
		for act in [1, 2, 3]:
			for suffix in ["earned", "spent", "purchases", "upgrades", "rerolls"]:
				rows[key]["act%d_%s" % [act, suffix]] = []
	var row: Dictionary = rows[key]
	var purchases := 0
	var upgrades := 0
	var shops := 0
	var previous := {"earned": 0.0, "spent": 0, "purchases": 0, "upgrades": 0, "rerolls": 0}
	for depth in StageGenerator.MAX_DEPTH:
		var available := tree.get_available_nodes()
		var stage := tree.visit(available[randi() % available.size()])
		RunManager.advance_stage()
		RunManager.current_stage_data = stage
		if stage.type in [StageData.Type.COMBAT, StageData.Type.ELITE, StageData.Type.BOSS]:
			RunManager.add_gold(_stage_revenue(stage))
			if stage.depth < 10:
				if stage.type == StageData.Type.BOSS:
					var excluded: Array = []
					for instance in skills:
						for mutation in instance.mutations:
							excluded.append(mutation.id)
					var mutations := MutationData.roll_mutations(3, excluded, skills)
					if not mutations.is_empty():
						skills[0].add_mutation(mutations[0])
					var legendaries: Array = []
					for resource in shop._load_resources("res://resources/passives/"):
						if resource.rarity == "legendary" and not RunManager.owned_passives.has(resource) and BuildOptions.can_offer_passive(resource, skills):
							legendaries.append(resource)
					if not legendaries.is_empty():
						RunManager.owned_passives.append(legendaries[randi() % legendaries.size()])
				var rewards := RewardRoller.roll(skills, stage.type in [StageData.Type.ELITE, StageData.Type.BOSS])
				_apply_offer(rewards[randi() % rewards.size()], skills)
		elif stage.type == StageData.Type.TREASURE:
			RunManager.add_gold(35.0)
		if stage.type == StageData.Type.SHOP or (stage.type == StageData.Type.BOSS and stage.depth == 5):
			var bought := _shop_visit(skills, policy, row)
			purchases += bought.x
			upgrades += bought.y
			shops += 1
		if stage.depth in [3, 7, 10]:
			var act := 1 if stage.depth == 3 else (2 if stage.depth == 7 else 3)
			row["act%d_balance" % act].append(RunManager.gold + RunManager.gold_fraction)
			var cumulative := {"earned": RunManager.run_stats.gold_earned, "spent": RunManager.run_stats.gold_spent, "purchases": purchases, "upgrades": upgrades, "rerolls": RunManager.run_stats.rerolls}
			for metric in previous:
				row["act%d_%s" % [act, metric]].append(cumulative[metric] - previous[metric])
			previous = cumulative
	var earned: float = RunManager.run_stats.gold_earned
	var spent: int = RunManager.run_stats.gold_spent
	var balance := RunManager.gold + RunManager.gold_fraction
	if not is_equal_approx(30.0 + earned, spent + balance):
		failures.append("Gold conservation failed for run %d" % index)
	row.earned.append(earned)
	row.spent.append(spent)
	row.balance.append(balance)
	row.purchases.append(purchases)
	row.upgrades.append(upgrades)
	row.rerolls.append(RunManager.run_stats.rerolls)
	row.shops.append(shops)
	if upgrades > 0:
		row.upgrade_runs += 1

func _stage_revenue(stage: StageData) -> float:
	spawner._apply_stage_data(stage)
	var revenue := 0.0
	var spawned := 0
	var pulse := 0
	var mini_spawned := false
	for time_slot in ceili(spawner._stage_duration / Spawner.MIN_PULSE_COOLDOWN):
		if spawned >= spawner._total_budget:
			break
		pulse += 1
		var count := spawner._enemies_per_pulse * (2 if pulse > 1 and pulse % spawner._power_pulse_interval == 0 else 1)
		count = mini(count, spawner._total_budget - spawned)
		var active_roles: Dictionary = {}
		for j in count:
			var role := spawner._pick_role()
			if Spawner.ROLE_LIMITS.has(role) and int(active_roles.get(role, 0)) >= int(Spawner.ROLE_LIMITS[role]):
				role = "trash"
			if role in ["trash", "medium"] and randf() < spawner._ranged_ratio:
				role = "ranged"
			active_roles[role] = int(active_roles.get(role, 0)) + 1
			revenue += float(gold_by_role[role]) * float(Spawner.ROLE_SCALING[role].gold)
			if role == "splitter":
				revenue += float(gold_by_role.split_fragment) * 2.0
		spawned += count
		if spawner._phase >= 2 and not spawner._is_boss_stage and pulse % spawner._elite_interval == 0:
			revenue += float(gold_by_role.elite) * float(Spawner.ROLE_SCALING.elite.gold)
		for role in stage.get_scripted_roles(pulse):
			if role == "elite" or int(active_roles.get(role, 0)) < int(Spawner.ROLE_LIMITS.get(role, 999)):
				revenue += float(gold_by_role[role]) * float(Spawner.ROLE_SCALING[role].gold)
		if spawner._has_mini_boss and not mini_spawned and spawned >= spawner._total_budget * 0.6:
			mini_spawned = true
			revenue += float(gold_by_role.elite) * 2.0
	if spawner._is_boss_stage:
		revenue += float(gold_by_role.elite) * 3.0
	return revenue * spawner._gold_mult

func _shop_visit(skills: Array[SkillInstance], policy: String, row: Dictionary) -> Vector2i:
	shop._skill_instances = skills
	RunManager.reroll_cost = 2
	shop._generate_offerings()
	_record_offerings()
	row.shop_visits += 1
	var regular: Array[Dictionary] = []
	var upgrade: Dictionary = {}
	for offer in shop._offerings:
		if offer.type == "stat_upgrade":
			upgrade = offer
		else:
			regular.append(offer)
	if regular.any(func(offer: Dictionary): return int(offer.cost) <= RunManager.gold):
		row.affordable_visits += 1
	if not upgrade.is_empty() and int(upgrade.cost) <= RunManager.gold:
		row.upgrade_affordable_visits += 1
	var result := Vector2i.ZERO
	if policy == "upgrade_first" and not upgrade.is_empty() and RunManager.gold >= int(upgrade.cost):
		_buy_upgrade(upgrade)
		result.y += 1
	regular.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.cost) < int(b.cost))
	for offer in regular:
		if result.x >= 2:
			break
		if _can_apply(offer, skills) and RunManager.gold >= int(offer.cost):
			RunManager.spend_gold(offer.cost)
			_apply_offer(offer, skills)
			result.x += 1
	if policy == "items_first" and not upgrade.is_empty() and RunManager.gold >= int(upgrade.cost):
		_buy_upgrade(upgrade)
		result.y += 1
	if result.x == 0 and RunManager.gold >= RunManager.reroll_cost + 8:
		shop._on_reroll()
		_record_offerings()
		for offer in shop._offerings:
			if offer.type != "stat_upgrade" and _can_apply(offer, skills) and int(offer.cost) <= RunManager.gold:
				RunManager.spend_gold(offer.cost)
				_apply_offer(offer, skills)
				result.x += 1
				break
	return result

func _record_offerings() -> void:
	for offer in shop._offerings:
		offering_counts[offer.type] = int(offering_counts.get(offer.type, 0)) + 1
		var id: String = offer.upgrade.key if offer.type == "stat_upgrade" else offer.resource.id
		var key := "%s:%s" % [offer.type, id]
		offering_ids[key] = int(offering_ids.get(key, 0)) + 1
		if not offering_prices.has(offer.type):
			offering_prices[offer.type] = {}
		var prices: Dictionary = offering_prices[offer.type]
		var price := str(int(offer.cost))
		prices[price] = int(prices.get(price, 0)) + 1

func _buy_upgrade(offer: Dictionary) -> void:
	RunManager.spend_gold(offer.cost)
	var upgrade: Dictionary = offer.upgrade
	RunManager.shop_bonuses[upgrade.key] = float(RunManager.shop_bonuses.get(upgrade.key, 0.0)) + float(upgrade.amount)

func _can_apply(offer: Dictionary, skills: Array[SkillInstance]) -> bool:
	if offer.type == "skill":
		return skills.size() < RunManager.skill_slots_unlocked
	if offer.type == "support":
		return BuildOptions.can_offer_support(offer.resource, skills)
	if offer.type == "passive":
		return not RunManager.owned_passives.has(offer.resource) and BuildOptions.can_offer_passive(offer.resource, skills)
	return true

func _apply_offer(offer: Dictionary, skills: Array[SkillInstance]) -> void:
	match offer.type:
		"gold": RunManager.add_gold(offer.amount)
		"skill":
			if skills.size() < RunManager.skill_slots_unlocked:
				var instance := SkillInstance.new(offer.resource)
				instance.set_rarity_tier(offer.get("tier", "common"))
				skills.append(instance)
		"support":
			RunManager.owned_supports.append(offer.resource)
			for instance in skills:
				if instance.link_support(offer.resource):
					break
				var linked := instance.linked_supports.duplicate()
				var replaced := false
				for previous in linked:
					if instance.support_rejection_reason(offer.resource, previous).is_empty():
						instance.unlink_support(previous)
						instance.link_support(offer.resource)
						replaced = true
						break
				if replaced:
					break
		"passive": RunManager.owned_passives.append(offer.resource)
		"mutation": skills[0].add_mutation(offer.mutation)
	for instance in skills:
		instance.recompute(RunManager.owned_passives)
