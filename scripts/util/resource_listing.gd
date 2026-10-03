class_name ResourceListing

# DirAccess can't enumerate files inside packed PCK on Android exports.
# Fall back to a known list so load() (which does work with PCK) can find them.

const _REGISTRY := {
	"res://resources/skills/": [
		"blade_spin", "fireball", "flame_wave", "frost_nova",
		"lightning_bolt", "poison_dart", "static_field",
	],
	"res://resources/supports/": [
		"arc_burst", "cast_on_kill", "chain", "corpse_bloom", "crit_cascade",
		"crit_explosion", "echo_trigger", "elemental_proliferation", "faster_casting",
		"glass_cannon", "hypothermia", "increased_area", "mine", "overcharge",
		"pierce", "plague_carrier", "poison_on_hit", "returning",
		"ricochet_amplifier", "shotgun", "spell_echo", "split", "totem",
		"toxic_burst", "void_rift",
	],
	"res://resources/passives/": [
		"arc_burst_mastery", "arcane_tempo", "blast_radius", "brutal_precision",
		"cast_on_kill_mastery", "chain_mastery", "chain_reaction", "conduction",
		"corpse_bloom_mastery", "crit_cascade_mastery", "crit_explosion_mastery",
		"deep_freeze", "detonation_expert", "echo_trigger_mastery",
		"elemental_proliferation_mastery", "executioner", "extra_shot",
		"faster_casting_mastery", "fire_mastery", "fortune", "glass_body",
		"glass_cannon_mastery", "heavy_hitter", "increased_area_mastery",
		"iron_will", "lightning_rod", "mine_mastery", "no_crit_juggernaut",
		"overcharge_mastery", "overclocked", "overflowing_power", "patient_hunter",
		"pierce_mastery", "plague_carrier_mastery", "poison_on_hit_mastery",
		"projectile_expert", "rapid_fire", "returning_mastery",
		"ricochet_amplifier_mastery", "ring_of_fire", "sharpened_edge",
		"sharp_eyes", "shotgun_mastery", "spell_echo_mastery", "split_mastery",
		"storm_conduit", "swift_feet", "thick_skin", "totem_mastery",
		"toxic_burst_mastery", "toxic_resilience", "trigger_on_death",
		"virulence", "void_rift_mastery", "wide_impact",
	],
	"res://resources/unlocks/": [
		"unlock_arc_burst", "unlock_arcane_tempo", "unlock_blast_radius",
		"unlock_brutal_precision", "unlock_conduction", "unlock_corpse_bloom",
		"unlock_crit_cascade", "unlock_detonation_expert", "unlock_echo_trigger",
		"unlock_glass_cannon", "unlock_lightning_rod", "unlock_overcharge",
		"unlock_overclocked", "unlock_patient_hunter", "unlock_plague_carrier",
		"unlock_ricochet_amplifier", "unlock_sharpened_edge", "unlock_shotgun",
		"unlock_toxic_burst", "unlock_virulence",
		"unlock_chain", "unlock_chain_reaction", "unlock_crit_explosion",
		"unlock_elemental_proliferation", "unlock_executioner", "unlock_fire_mastery",
		"unlock_flame_wave", "unlock_frost_nova", "unlock_glass_body", "unlock_increased_area",
		"unlock_no_crit_juggernaut", "unlock_overflowing_power", "unlock_poison_dart",
		"unlock_projectile_expert", "unlock_ring_of_fire", "unlock_split",
		"unlock_static_field", "unlock_storm_conduit", "unlock_toxic_resilience",
		"unlock_trigger_on_death",
	],
	"res://resources/regions/": [
		"burning_grounds", "storm_spire", "toxic_depths",
	],
	"res://resources/consumables/": [
		"aoe_bomb", "auto_revive", "berserker_potion", "cooldown_flask",
		"damage_flask", "gold_magnet", "health_potion", "time_slow",
	],
}


static func get_resource_files(dir_path: String) -> PackedStringArray:
	var dir := DirAccess.open(dir_path)
	if dir:
		var files: PackedStringArray = []
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".tres") or f.ends_with(".res"):
				files.append(f)
			f = dir.get_next()
		if files.size() > 0:
			return files

	if dir_path in _REGISTRY:
		var files: PackedStringArray = []
		for base_name: String in _REGISTRY[dir_path]:
			var path := dir_path + base_name + ".tres"
			if ResourceLoader.exists(path):
				files.append(base_name + ".tres")
		return files

	return PackedStringArray()
