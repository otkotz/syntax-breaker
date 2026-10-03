extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

# Mock source flags exist only in memory to test selection, never in playtest logs.
func mock_run(index: int) -> Dictionary:
	return {"schema_version": 1, "run_id": "mock_%d" % index,
		"source": "playtest", "status": "victory", "started_utc": "2026-10-03T12:00:%02d" % index,
		"metadata": {}, "events": [], "stages": [], "combat_seconds": 100.0, "app_seconds": 120.0,
		"spawn_wait_seconds": 2.0, "frame_samples": 6000, "frame_ms_sum": 100000.0,
		"frame_ms_max": 20.0, "frames_over_33ms": 0, "dropped_events": 0,
		"first_decision_seconds": 20.0, "decision_intervals": [40.0, 40.0]}

func _ready() -> void:
	var reporter := preload("res://tests/telemetry_report.gd").new()
	var runs: Array[Dictionary] = []
	for index in 6:
		runs.append(mock_run(index))
	check(reporter.valid_run(runs[0]), "Well-formed fixture validates")
	check(reporter.assess_cadence(runs.slice(0, 4)).status == "insufficient_data", "Four runs cannot satisfy five-run requirement")
	runs[0].decision_intervals = [80.0]
	var passing: Dictionary = reporter.assess_cadence(runs)
	check(passing.status == "passed_numeric_checks" and passing.runs[0].run_id == "mock_1", "Only latest five are checked, not arbitrary best five")
	runs.reverse()
	check(reporter.assess_cadence(runs).runs[0].run_id == "mock_1", "Chronology does not depend on directory order")
	runs[0].decision_intervals = [45.0, 35.0]
	check(reporter.assess_cadence(runs).status == "passed_numeric_checks", "Exactly 45-second gap is allowed")
	runs[0].decision_intervals = [45.01, 34.99]
	check(reporter.assess_cadence(runs).status == "not_met", "A late failing run cannot be cherry-picked away")
	runs[0].decision_intervals = [40.0, 40.0]
	runs[0].first_decision_seconds = 30.0
	runs[0].combat_seconds = 110.0
	check(reporter.assess_cadence(runs).status == "not_met", "First decision must be strictly below 30 seconds")
	runs[0] = mock_run(5)
	runs[0].decision_intervals = [1.0]
	check(reporter.assess_cadence(runs).status == "not_met", "Missing final tail cannot hide a long interval")
	runs[0] = mock_run(5)
	runs[0].metadata.resumed_without_earlier_telemetry = true
	check(reporter.assess_cadence(runs).status == "not_met", "Partial legacy resume cannot prove a complete run")
	runs[0] = mock_run(5)
	runs[0].dropped_events = 1
	check(reporter.assess_cadence(runs).status == "not_met", "Truncated event audit is explicit")
	runs[0] = mock_run(5)
	runs[-1] = mock_run(0)
	runs[-1].started_utc = runs[-2].started_utc
	check(reporter.assess_cadence(runs).status == "unverified", "Timestamp tie at selection boundary is not fabricated chronology")
	for run in runs:
		run.source = "synthetic"
	check(reporter.assess_cadence(runs).status == "insufficient_data", "Synthetic samples cannot satisfy cadence even when included in analysis")
	for field in ["combat_seconds", "events", "decision_intervals", "metadata", "started_utc"]:
		var corrupt := mock_run(0)
		corrupt[field] = null
		check(not reporter.valid_run(corrupt), "Reject missing/wrong type: " + field)
	var corrupt := mock_run(0)
	corrupt.spawn_wait_seconds = 101.0
	check(not reporter.valid_run(corrupt), "Spawn wait cannot exceed combat time")
	corrupt = mock_run(0)
	corrupt.frame_ms_max = INF
	check(not reporter.valid_run(corrupt), "Non-finite metrics cannot enter summaries")
	corrupt = mock_run(0)
	corrupt.events = [{"type": "decision_open", "app_seconds": 1.0, "combat_seconds": 1.0,
		"data": {"id": 1, "kind": "reward", "offers": "broken"}}]
	check(not reporter.valid_run(corrupt), "Malformed offer list cannot crash aggregation")
	corrupt = mock_run(0)
	corrupt.events = [{"type": "decision_chosen", "app_seconds": 1.0, "combat_seconds": 1.0,
		"data": {"id": 1, "think_seconds": -1.0, "selected": {}}}]
	check(not reporter.valid_run(corrupt), "Negative thinking time cannot enter summaries")
	var directory := "res://.godot/telemetry_report_test_" + Crypto.new().generate_random_bytes(6).hex_encode()
	DirAccess.make_dir_recursive_absolute(directory)
	var saved := mock_run(0)
	saved.source = "synthetic"
	write_fixture(directory.path_join("a.json"), saved)
	write_fixture(directory.path_join("b.json"), saved)
	var conflict := saved.duplicate(true)
	conflict.status = "death"
	write_fixture(directory.path_join("c.json"), conflict)
	corrupt = saved.duplicate(true)
	corrupt.run_id = "corrupt"
	corrupt.decision_intervals = "not_an_array"
	write_fixture(directory.path_join("d.json"), corrupt)
	var aggregated: Dictionary = reporter.aggregate(directory, true)
	check(aggregated.invalid_files == 1 and aggregated.completed_runs == 1, "Corrupt log cannot inflate completed-run count")
	check(aggregated.duplicates == 2 and aggregated.conflicting_duplicates == 1, "Identical copies are deduplicated and conflicting copies are explicit")
	check(aggregated.cadence.status == "unverified", "Conflicting log copies cannot certify cadence")
	check(aggregated.completed_playtests == 0, "Disk fixtures never enter real-playtest population")
	reporter.free()
	if failures.is_empty():
		print("PASS: latest-five cadence, chronology, exact thresholds, final tail, partial resume, synthetic exclusion and malformed logs")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func write_fixture(path: String, contents: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(contents))
	file.close()
