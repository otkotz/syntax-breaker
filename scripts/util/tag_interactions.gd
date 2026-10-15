class_name TagInteractions
extends RefCounted

static func process_hit(target: Node2D, damage: float, tags: Array, source: Node2D, skill: SkillResource = null) -> void:
	if not target.has_method("take_damage"):
		return

	# Fire + Poison = Ignite: converts poison DoT to burst damage
	if tags.has("fire") and target.has_method("apply_dot"):
		var poison_stacks: Array = target.get_dot_stacks("poison") if target.has_method("get_dot_stacks") else []
		if not poison_stacks.is_empty():
			var burst := 0.0
			for dot: Dictionary in poison_stacks: burst += float(dot.damage) * float(dot.remaining) * 3.0
			target.consume_dot_stacks("poison", poison_stacks.size())
			target.take_damage(burst, false, skill, "proc")
			CombatLog.interaction("Ignite", target.name, "burst %.1f from consumed poison" % burst)

	# Lightning + hit on enemy near others = arc to 2 nearby
	if tags.has("lightning"):
		var enemies := Targeting.find_enemies_in_range(target.global_position, 120.0, 6)
		var arcs := 0
		for enemy: Node2D in enemies:
			if enemy == target or enemy == source:
				continue
			if not enemy.has_method("take_damage"):
				continue
			enemy.take_damage(damage * 0.3, false, skill, "proc")
			CombatLog.interaction("Lightning Arc", target.name, "arced %.1f to %s" % [damage * 0.3, enemy.name])
			arcs += 1
			if arcs >= 2:
				break

	# Poison skill hits burning enemy = toxic cloud (AoE poison spread)
	if tags.has("poison") and target.has_method("apply_dot"):
		if target.has_method("get_dot_stacks") and not target.get_dot_stacks("burn").is_empty():
			var nearby := Targeting.find_enemies_in_range(target.global_position, 120.0, 10)
			var spread_count := 0
			for enemy: Node2D in nearby:
				if enemy == target:
					continue
				if enemy.has_method("apply_dot"):
					enemy.apply_dot("poison", damage * 0.3, 3.0, 0.5, skill)
					spread_count += 1
			if spread_count > 0:
				CombatLog.interaction("Toxic Cloud", target.name, "spread poison to %d nearby" % spread_count)

	# Physical + bleeding enemy hit by fire = Cauterize (burst from consumed bleed)
	if tags.has("fire") and target.has_method("apply_dot"):
		var bleed_stacks: Array = target.get_dot_stacks("bleed") if target.has_method("get_dot_stacks") else []
		if not bleed_stacks.is_empty():
			var burst := 0.0
			for dot: Dictionary in bleed_stacks: burst += float(dot.damage) * float(dot.remaining) * 3.5
			target.consume_dot_stacks("bleed", bleed_stacks.size())
			target.take_damage(burst, false, skill, "proc")
			CombatLog.interaction("Cauterize", target.name, "burst %.1f from consumed bleed" % burst)

	# Cross-element synergies
	SynergyTracker.record_and_check(target, tags, damage, skill)
