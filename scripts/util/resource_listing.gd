class_name ResourceListing

# DirAccess can't enumerate files inside packed PCK on Android exports.
# Fall back to a known list so load() (which does work with PCK) can find them.

const _REGISTRY := {
	"res://resources/skills/": [
		"blade_spin", "fireball", "flame_wave", "frost_nova",
		"lightning_bolt", "poison_dart", "static_field",
	],
	"res://resources/supports/": [
		"cast_on_kill", "chain", "crit_explosion", "elemental_proliferation",
		"faster_casting", "glass_cannon", "hypothermia", "increased_area", "mine",
		"overcharge", "pierce", "poison_on_hit", "shotgun",
		"spell_echo", "split", "totem", "void_rift",
	],
	"res://resources/passives/": [
		"chain_reaction", "deep_freeze", "executioner", "extra_shot", "fire_mastery",
		"glass_body", "heavy_hitter", "iron_will", "no_crit_juggernaut",
		"overflowing_power", "projectile_expert", "rapid_fire", "ring_of_fire",
		"sharp_eyes", "storm_conduit", "swift_feet", "thick_skin",
		"toxic_resilience", "trigger_on_death", "wide_impact",
	],
	"res://resources/unlocks/": [
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
