extends Node

var failures: Array[String] = []

func _ready() -> void:
	_check(Spawner.next_pulse_delay(0) <= 0.4, "empty arena refills in under 0.4 seconds")
	_check(is_equal_approx(Spawner.next_pulse_delay(2), Spawner.MIN_PULSE_COOLDOWN), "live packs preserve breathing room")
	_check(Spawner.should_force_finale_pulse(1, 8, false), "last budget becomes a designed finale pulse")
	_check(not Spawner.should_recall_straggler(2.9, 1, false, false, 0), "straggler gets a fair chase window")
	_check(Spawner.should_recall_straggler(3.1, 1, false, false, 0), "lone trash is recalled after three seconds")
	_check(not Spawner.should_recall_straggler(4.0, 1, true, false, 0), "active spawning never recalls enemies")
	_check(not Spawner.should_recall_straggler(4.0, 1, false, true, 0), "boss is never recalled")
	RunManager.start_run()
	_check(Shop.can_buy_stat_upgrade("damage", false), "fresh run can buy a stat upgrade")
	RunManager.shop_upgrade_counts["damage"] = 3
	_check(not Shop.can_buy_stat_upgrade("damage", false), "run cap blocks a fourth identical upgrade")
	RunManager.shop_upgrade_counts["damage"] = 0
	_check(not Shop.can_buy_stat_upgrade("damage", true), "visit cap blocks a second stat upgrade")
	RunManager.shop_upgrade_counts = {"damage": 3}
	var available: Array[Dictionary] = Shop.available_stat_upgrades(Shop.STAT_UPGRADES, false)
	_check(available.size() == 2, "capped upgrades do not hide other legal shop choices")
	_check(available.all(func(entry: Dictionary) -> bool: return entry.key != "damage"), "capped upgrade is filtered before rolling")
	RunManager.restore_from_save({"shop_bonuses": {"damage": 7.5}, "shop_upgrade_counts": {"damage": 3}})
	_check(int(RunManager.shop_upgrade_counts.get("damage", 0)) == 3, "shop upgrade run caps survive save restore")
	var renderer := SkillVisualRenderer.new()
	add_child(renderer)
	renderer.configure(load("res://resources/skill_visuals/fireball.tres"), [], 1)
	_check(renderer.punch_remaining > 0.0 and renderer.scale.x < 1.0, "skill cast starts a short visual impulse")
	_check(renderer.punch_duration <= 0.12, "skill impulse stays within mobile budget")
	renderer.queue_free()
	var previous_reduced_motion := QualitySettings.reduced_motion
	QualitySettings.reduced_motion = true
	var reduced_renderer := SkillVisualRenderer.new()
	add_child(reduced_renderer)
	reduced_renderer.configure(load("res://resources/skill_visuals/fireball.tres"), [], 1)
	_check(is_zero_approx(reduced_renderer.punch_remaining) and reduced_renderer.scale == Vector2.ONE, "reduced motion suppresses the skill impulse")
	reduced_renderer.queue_free()
	QualitySettings.reduced_motion = previous_reduced_motion
	if failures.is_empty(): print("momentum_patch_native: PASS")
	else:
		for failure in failures: push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
