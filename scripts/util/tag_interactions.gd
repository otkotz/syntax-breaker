class_name TagInteractions
extends RefCounted

static func process_hit(target: Node2D, damage: float, tags: Array, source: Node2D) -> void:
	if not target.has_method("take_damage"):
		return

	# Fire + Poison = Ignite: converts poison DoT to burst damage
	if tags.has("fire") and target.has_method("apply_dot"):
		var dots: Dictionary = target.get("_dots")
		if dots and dots.has("poison"):
			var remaining: float = dots["poison"]["remaining"]
			var tick_dmg: float = dots["poison"]["damage"]
			var burst := tick_dmg * remaining * 2.0
			dots.erase("poison")
			target.take_damage(burst)
			CombatLog.interaction("Ignite", target.name, "burst %.1f from consumed poison" % burst)

	# Lightning + hit on enemy near others = arc to 1 nearby
	if tags.has("lightning"):
		var enemies := Targeting.find_enemies_in_range(target.global_position, 100.0, 5)
		for enemy: Node2D in enemies:
			if enemy == target or enemy == source:
				continue
			if not enemy.has_method("take_damage"):
				continue
			enemy.take_damage(damage * 0.3)
			CombatLog.interaction("Lightning Arc", target.name, "arced %.1f to %s" % [damage * 0.3, enemy.name])
			break

	# Poison skill hits burning enemy = toxic cloud (AoE poison)
	if tags.has("poison") and target.has_method("apply_dot"):
		var dots: Dictionary = target.get("_dots")
		if dots and dots.has("burn"):
			var nearby := Targeting.find_enemies_in_range(target.global_position, 80.0, 8)
			var spread_count := 0
			for enemy: Node2D in nearby:
				if enemy == target:
					continue
				if enemy.has_method("apply_dot"):
					enemy.apply_dot("poison", damage * 0.2, 2.0, 0.5)
					spread_count += 1
			if spread_count > 0:
				CombatLog.interaction("Toxic Cloud", target.name, "spread poison to %d nearby" % spread_count)

	# Cross-element synergies
	SynergyTracker.record_and_check(target, tags, damage)
