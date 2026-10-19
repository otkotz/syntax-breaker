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
	var registry := preload("res://scripts/expedition/artifacts/artifact_synergy_registry.gd")
	check(registry.get_active_pairs(["fractured_prism", "ashen_needle"]) == [&"prism_needle_crossfire"], "Prism and Needle activate only Crossfire")
	check(registry.get_active_pairs(["ashen_needle", "fractured_prism", "fractured_prism"]) == [&"prism_needle_crossfire"], "Pair activation is order-independent and ignores duplicates")
	check(registry.get_active_pairs(["echoing_hourglass", "bloodwritten_sigil"]) == [&"hourglass_sigil_blood_echo"], "Hourglass and Sigil activate Blood Echo")
	check(registry.get_active_pairs(["cinder_crown", "fractured_prism"]) == [&"crown_prism_split_transfer"], "Crown and Prism activate Split Transfer")
	check(registry.get_active_pairs(["fractured_prism", "ashen_needle", "cinder_crown", "unknown"]).size() == 2, "Three artifacts activate explicit pairs without an implicit three-way synergy")

	var hooks := ArtifactCombatHooks.new()
	var runtime := ArtifactRuntime.new(ArtifactRegistry.with_defaults(), hooks)
	var triggered: Array[StringName] = []
	runtime.synergy_triggered.connect(func(id: StringName, _pos: Vector2): triggered.append(id))
	runtime.setup(["fractured_prism", "ashen_needle", "", ""], [], self)
	var fragments: Array[Dictionary] = []
	var projectile := ProjectileBase.new()
	add_child(projectile)
	hooks.emit_event(&"projectile_hit", {"projectile": projectile, "damage": 100.0, "pre_hit_burn_count": 1, "generation": 0, "spawn_fragment": func(data): fragments.append(data)})
	check(fragments.size() == 3, "Crossfire adds exactly one bounded fragment")
	check(fragments[2].origin_flags.has("prism_needle_crossfire") and fragments[2].generation == 1 and is_equal_approx(fragments[2].damage, 35.0), "Crossfire carries its origin flag, one-generation cap, and 35 percent damage")
	check(triggered == [&"prism_needle_crossfire"], "A synergy is reported only when its bounded effect actually triggers")
	var secondary_target := EnemyBase.new()
	add_child(secondary_target)
	secondary_target.apply_dot_stack("burn", 1.0, 1.0, 0.5)
	var secondary_projectile := ProjectileBase.new()
	add_child(secondary_projectile)
	hooks.emit_event(&"projectile_hit", {"target": secondary_target, "projectile": secondary_projectile, "damage": 100.0, "pre_hit_burn_count": 1, "generation": 1, "origin_flags": ["prism_needle_crossfire", "secondary_artifact_projectile"], "spawn_fragment": func(data): fragments.append(data)})
	check(fragments.size() == 3, "Crossfire cannot recurse from itself")
	check(secondary_projectile.pierce_remaining == 0, "Crossfire fragment cannot trigger Needle a second time")
	runtime.teardown()
	Targeting.unregister(secondary_target)
	secondary_target.free()
	secondary_projectile.free()

	hooks = ArtifactCombatHooks.new()
	runtime = ArtifactRuntime.new(ArtifactRegistry.with_defaults(), hooks)
	runtime.setup(["echoing_hourglass", "bloodwritten_sigil", "", ""], [], self)
	var player := FakePlayer.new()
	add_child(player)
	var echoes := [0]
	hooks.emit_event(&"skill_cast", {"player": player, "spawn_echo": func(): echoes[0] += 1})
	check(player.current_hp == 92.0 and echoes[0] == 1, "Blood Echo pays Sigil health once and emits one immediate echo")
	hooks.emit_event(&"skill_cast", {"player": player, "origin_flags": ["hourglass_sigil_blood_echo", "secondary_artifact_projectile"], "spawn_echo": func(): echoes[0] += 1})
	check(player.current_hp == 92.0 and echoes[0] == 1, "Blood Echo neither repays health nor recursively echoes")
	runtime.teardown()

	hooks = ArtifactCombatHooks.new()
	runtime = ArtifactRuntime.new(ArtifactRegistry.with_defaults(), hooks)
	runtime.setup(["cinder_crown", "fractured_prism", "", ""], [], self)
	var dead := EnemyBase.new()
	dead.global_position = Vector2.ZERO
	dead.apply_dot_stack("burn", 10.0, 2.0, 0.5, null, "pair-burn", 5)
	var first_target := EnemyBase.new()
	var split_target := EnemyBase.new()
	for entry: Array in [[first_target, Vector2(20, 0)], [split_target, Vector2(40, 0)]]:
		var enemy := entry[0] as EnemyBase
		add_child(enemy)
		enemy.global_position = entry[1]
		enemy.add_to_group("enemies")
		enemy.current_hp = 100.0
		enemy.max_hp = 100.0
		Targeting.update_position(enemy)
	GameBus.enemy_killed.emit(dead, null)
	check(not first_target.get_dot_stacks("burn").is_empty(), "Crown keeps its normal first transfer")
	check(not split_target.get_dot_stacks("burn").is_empty() and is_equal_approx(float(split_target.get_dot_stacks("burn")[0].damage), 5.0), "Split Transfer reaches only the second target at half burn strength")
	var split_count := split_target.get_dot_stacks("burn").size()
	dead.set_meta("artifact_kill_generation", 1)
	GameBus.enemy_killed.emit(dead, null)
	check(split_target.get_dot_stacks("burn").size() == split_count, "Split Transfer stops after one generation")
	var third_target := EnemyBase.new()
	add_child(third_target)
	third_target.global_position = Vector2(60, 0)
	third_target.add_to_group("enemies")
	Targeting.update_position(third_target)
	GameBus.enemy_killed.emit(split_target, null)
	check(third_target.get_dot_stacks("burn").is_empty(), "Split Transfer burn cannot trigger normal Crown transfer")
	runtime.teardown()
	for enemy in [first_target, split_target, third_target]:
		Targeting.unregister(enemy)
		enemy.queue_free()
	dead.free()

	ExpeditionManager.profile_path = "res://.godot/synergy_profile.json"
	_cleanup()
	ExpeditionManager.start_new_profile()
	check(ExpeditionManager.discover_synergy("prism_needle_crossfire"), "Triggered synergy saves discovery")
	check(ExpeditionManager.profile.discovered_synergy_ids == ["prism_needle_crossfire"], "Discovery enters the profile once")
	var before := ExpeditionManager.profile.to_dict().duplicate(true)
	ExpeditionManager.profile_path = "res://missing_directory/synergy.json"
	check(not ExpeditionManager.discover_synergy("hourglass_sigil_blood_echo") and ExpeditionManager.profile.to_dict() == before, "Failed save does not reveal a synergy")
	var vfx_parent := Node2D.new()
	add_child(vfx_parent)
	var vfx_radii: Array[float] = []
	for id in ["prism_needle_crossfire", "hourglass_sigil_blood_echo", "crown_prism_split_transfer"]:
		var effect := ArtifactVFX.spawn(vfx_parent, id, Vector2.ZERO)
		vfx_radii.append(effect.radius)
		ArtifactVFX.release_all(vfx_parent)
	check(vfx_radii == [22.0, 34.0, 46.0], "Each curated pair has one distinct bounded VFX signature")
	vfx_parent.queue_free()
	_cleanup()
	projectile.queue_free()
	player.queue_free()
	print(JSON.stringify({"failures": failures, "triggered": triggered}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = ExpeditionManager.profile_path + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
