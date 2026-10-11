extends Node

const ThreatProtocolsData = preload("res://scripts/util/threat_protocols.gd")

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	MetaProgression.save_path = "res://.godot/threat_protocol_rules_meta.json"
	RunManager.save_path = "res://.godot/threat_protocol_rules_run.json"
	RunTelemetry.enabled = false
	_check_definitions()
	_check_legacy_bands()
	_check_migration_and_persistence()
	_check_regional_progression()
	if failures.is_empty():
		print("PASS: Threat Protocol definitions, legacy migration, persistence and regional progression")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_definitions() -> void:
	var expected := [
		["normal", "NORMAL", 1.0, 1.0, 1.0, 1.0, 0.0, 1.0],
		["overclocked", "OVERCLOCKED", 1.15, 1.08, 1.03, 1.12, 5.0, 1.08],
		["corrupted", "CORRUPTED", 1.30, 1.18, 1.06, 1.25, 10.0, 1.18],
		["system_failure", "SYSTEM FAILURE", 1.55, 1.32, 1.10, 1.40, 18.0, 1.32],
		["no_warranty", "NO WARRANTY", 1.85, 1.50, 1.15, 1.60, 28.0, 1.50],
	]
	for level in expected.size():
		var definition := ThreatProtocolsData.definition(level)
		var scaling := ThreatProtocolsData.scaling(level)
		check(definition.id == expected[level][0] and definition.name == expected[level][1], "Protocol %d has stable identity" % level)
		for pair in [["hp_mult", 2], ["damage_mult", 3], ["speed_mult", 4], ["count_mult", 5], ["luck_bonus", 6], ["gold_mult", 7]]:
			check(is_equal_approx(float(scaling[pair[0]]), float(expected[level][pair[1]])), "Protocol %d has exact %s" % [level, pair[0]])
	check(ThreatProtocolsData.definition(-5).id == "normal", "Negative protocol clamps to NORMAL")
	check(ThreatProtocolsData.definition(99).id == "no_warranty", "Oversized protocol clamps to NO WARRANTY")
	check(ThreatProtocolsData.special_modifiers(4, 1).is_empty(), "Depth one is exempt from protocol reinforcements")
	check(ThreatProtocolsData.special_modifiers(4, 2) == ["elite_patrol", "denial_reinforcement", "shield_reinforcement"], "NO WARRANTY exposes all later-depth rules")

func _check_legacy_bands() -> void:
	var cases := {0: 0, 4: 1, 5: 2, 10: 3, 15: 4, 20: 4, 99: 4, -5: 0}
	for legacy: int in cases:
		check(ThreatProtocolsData.from_legacy_ascension(legacy) == cases[legacy], "Legacy Ascension %d maps to protocol %d" % [legacy, cases[legacy]])

func _check_migration_and_persistence() -> void:
	var legacy := {
		"ascension_level": 10,
		"highest_ascension_unlocked": {
			"zero": 0, "one": 4, "two": 5, "three": 10, "four": 15, "capped": 20,
		},
	}
	var file := FileAccess.open(MetaProgression.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	MetaProgression.threat_protocol_level = 0
	MetaProgression.highest_threat_protocol_unlocked = {}
	MetaProgression.load_progress()
	check(MetaProgression.threat_protocol_level == 3, "Selected legacy Ascension migrates")
	for pair in [["zero", 0], ["one", 1], ["two", 2], ["three", 3], ["four", 4], ["capped", 4]]:
		check(MetaProgression.get_max_threat_protocol(pair[0]) == pair[1], "Regional legacy maximum migrates for %s" % pair[0])
	MetaProgression.threat_protocol_level = 1
	MetaProgression.highest_threat_protocol_unlocked["three"] = 4
	MetaProgression.save_progress()
	MetaProgression.load_progress()
	check(MetaProgression.threat_protocol_level == 1 and MetaProgression.get_max_threat_protocol("three") == 4, "New protocol keys make migration idempotent")

func _check_regional_progression() -> void:
	MetaProgression.highest_threat_protocol_unlocked = {"burning_grounds": 2, "storm_spire": 0}
	MetaProgression.set_threat_protocol(99, "burning_grounds")
	check(MetaProgression.threat_protocol_level == 2, "Selection clamps to regional unlock")
	MetaProgression.record_victory("burning_grounds", 2)
	check(MetaProgression.get_max_threat_protocol("burning_grounds") == 3, "Victory unlocks exactly the next protocol")
	MetaProgression.record_victory("burning_grounds", 0)
	check(MetaProgression.get_max_threat_protocol("burning_grounds") == 3, "Lower-protocol victory does not skip progression")
	check(MetaProgression.get_max_threat_protocol("storm_spire") == 0, "Regional progress remains independent")
	RunManager.start_run("burning_grounds", 99)
	check(RunManager.threat_protocol_level == 3, "Active run snapshots the clamped selected protocol")
