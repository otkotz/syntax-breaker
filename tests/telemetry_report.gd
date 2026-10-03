extends Node

# Read-only aggregation; output stays separate from the input run logs.
func _ready() -> void:
	var directory := "user://telemetry"
	var output := "res://.godot/telemetry_report.json"
	var include_synthetic := false
	var minimum := 0
	var require_cadence := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--directory="):
			directory = argument.trim_prefix("--directory=")
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		elif argument == "--include-synthetic":
			include_synthetic = true
		elif argument.begins_with("--min-runs="):
			minimum = maxi(0, argument.trim_prefix("--min-runs=").to_int())
		elif argument == "--require-cadence":
			require_cadence = true
	var report := aggregate(directory, include_synthetic)
	var file := FileAccess.open(output, FileAccess.WRITE)
	if not file:
		push_error("Cannot write report: " + output)
		get_tree().quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Telemetry: %d completed runs (%d playtests), %d synthetic excluded, %d invalid; report: %s" % [
		report.completed_runs, report.completed_playtests, report.synthetic_excluded, report.invalid_files, output])
	# Even --include-synthetic never satisfies the human-sample requirement.
	get_tree().quit(0 if report.completed_playtests >= minimum and (not require_cadence or report.cadence.status == "passed_numeric_checks") else 2)

func aggregate(directory: String, include_synthetic: bool) -> Dictionary:
	var report := {"schema_version": 1, "directory": directory, "includes_synthetic": include_synthetic,
		"completed_runs": 0, "completed_playtests": 0, "synthetic_excluded": 0,
		"invalid_files": 0, "duplicates": 0, "conflicting_duplicates": 0, "unfinished_runs": 0, "abandoned_runs": 0,
		"wins": 0, "deaths_by_source": {}, "cohorts": {}, "choices": {}, "dropped_events": 0,
		"limitations": ["Unfinished logs do not prove crashes.", "Frame measurements are not phone performance evidence unless collected on that phone.",
			"Pick rates cover logged decisions, not causal build strength; capped events can omit choices.",
			"Synthetic fixtures never satisfy the required real-playtest sample."]}
	var samples := {"combat_seconds": [], "app_seconds": [], "spawn_wait_seconds": [],
		"first_decision_seconds": [], "positive_decision_intervals": [], "think_seconds": [],
		"mean_frame_ms": [], "slow_frame_fraction": []}
	var seen := {}
	var cadence_runs: Array[Dictionary] = []
	var folder := DirAccess.open(directory)
	if not folder:
		report["directory_missing"] = true
		report["metrics"] = {}
		report["cadence"] = assess_cadence([])
		return report
	var files := folder.get_files()
	files.sort()
	for filename in files:
		if not filename.ends_with(".json"):
			continue
		var file := FileAccess.open(directory.path_join(filename), FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_as_text()) if file else null
		if not valid_run(parsed):
			report.invalid_files += 1
			continue
		var run: Dictionary = parsed
		if seen.has(run.run_id):
			report.duplicates += 1
			if run != seen[run.run_id]:
				report.conflicting_duplicates += 1
			continue
		seen[run.run_id] = run
		if run.source == "synthetic" and not include_synthetic:
			report.synthetic_excluded += 1
			continue
		if run.status not in ["victory", "death"]:
			if run.status == "abandoned":
				report.abandoned_runs += 1
			else:
				report.unfinished_runs += 1
			continue
		report.completed_runs += 1
		if run.source == "playtest":
			report.completed_playtests += 1
			cadence_runs.append(run)
		report.wins += int(run.status == "victory")
		report.dropped_events += int(run.get("dropped_events", 0))
		if run.status == "death":
			increment(report.deaths_by_source, str(run.get("death_source", "unknown")))
		var metadata: Dictionary = run.metadata
		var cohort_key := "%s/A%s/%s/%s/%s" % [metadata.get("region", "unknown"), metadata.get("ascension", "?"),
			metadata.get("quality", "unknown"), metadata.get("starter", "unknown"), metadata.get("starter_contract", "standard")]
		if not report.cohorts.has(cohort_key):
			report.cohorts[cohort_key] = {"runs": 0, "wins": 0}
		var cohort: Dictionary = report.cohorts[cohort_key]
		cohort.runs += 1
		cohort.wins += int(run.status == "victory")
		for key in ["combat_seconds", "app_seconds", "spawn_wait_seconds", "first_decision_seconds"]:
			if run.get(key) is float or run.get(key) is int:
				samples[key].append(float(run[key]))
		for interval in run.get("decision_intervals", []):
			if (interval is float or interval is int) and interval > 0:
				samples.positive_decision_intervals.append(float(interval))
		var frames := float(run.get("frame_samples", 0))
		if frames > 0:
			samples.mean_frame_ms.append(float(run.get("frame_ms_sum", 0)) / frames)
			samples.slow_frame_fraction.append(float(run.get("frames_over_33ms", 0)) / frames)
		collect_choices(run.events, report.choices, samples.think_seconds)
	report["win_rate"] = float(report.wins) / report.completed_runs if report.completed_runs > 0 else null
	report["metrics"] = {}
	for key in samples:
		report.metrics[key] = summarize(samples[key])
	for cohort in report.cohorts.values():
		cohort["win_rate"] = float(cohort.wins) / cohort.runs
	for choice in report.choices.values():
		choice["pick_rate"] = float(choice.picked) / choice.offered if choice.offered > 0 else null
	report["cadence"] = assess_cadence(cadence_runs)
	if report.invalid_files > 0 and report.cadence.status == "passed_numeric_checks":
		report.cadence.status = "unverified"
		report.cadence.reasons.append("Invalid files may hide a more recent run; resolve them before claiming consecutive-run evidence.")
	if report.conflicting_duplicates > 0:
		report.cadence.status = "unverified"
		report.cadence.reasons.append("Conflicting copies of the same run ID; resolve them before interpreting the report.")
	return report

func valid_run(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if not (value.get("schema_version") == 1 and value.get("run_id") is String \
		and not value.run_id.is_empty() and value.get("source") in ["playtest", "synthetic"] \
		and value.get("metadata") is Dictionary and value.get("events") is Array \
		and value.get("status") in ["victory", "death", "in_progress", "abandoned"]):
		return false
	if not value.get("started_utc") is String or value.started_utc.is_empty():
		return false
	var date_pattern := RegEx.new()
	date_pattern.compile("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$")
	if not date_pattern.search(value.started_utc):
		return false
	for key in ["combat_seconds", "app_seconds", "spawn_wait_seconds", "frame_samples", "frame_ms_sum", "frame_ms_max", "frames_over_33ms", "dropped_events"]:
		if not nonnegative_number(value.get(key)):
			return false
	if value.spawn_wait_seconds > value.combat_seconds or value.frames_over_33ms > value.frame_samples:
		return false
	if value.get("first_decision_seconds") != null and (not nonnegative_number(value.first_decision_seconds) or value.first_decision_seconds > value.combat_seconds):
		return false
	if not value.get("decision_intervals") is Array or not value.get("stages") is Array:
		return false
	for interval in value.decision_intervals:
		if not nonnegative_number(interval) or interval > value.combat_seconds:
			return false
	for event in value.events:
		if not event is Dictionary or not event.get("type") is String or not event.get("data") is Dictionary:
			return false
		for key in ["combat_seconds", "app_seconds"]:
			if not nonnegative_number(event.get(key)) or event[key] > value[key]:
				return false
		var payload: Dictionary = event.data
		if event.type == "decision_open":
			if not payload.get("offers") is Array or not payload.get("kind") is String or not nonnegative_number(payload.get("id")):
				return false
			for offer in payload.offers:
				if not offer is Dictionary:
					return false
		elif event.type == "decision_chosen":
			if not payload.get("selected") is Dictionary or not nonnegative_number(payload.get("think_seconds")) or not nonnegative_number(payload.get("id")):
				return false
	return true

func nonnegative_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0

func assess_cadence(runs: Array[Dictionary]) -> Dictionary:
	var result := {"status": "insufficient_data", "required_runs": 5, "available_runs": 0,
		"runs": [], "reasons": [], "scope": "Numeric cadence checks only; not the full Milestone B gate."}
	var real_runs: Array[Dictionary] = []
	for run in runs:
		if run.get("source") == "playtest" and run.get("status") in ["victory", "death"]:
			real_runs.append(run)
	result.available_runs = real_runs.size()
	if real_runs.size() < 5:
		result.reasons.append("Need five completed real playtests; synthetic runs never qualify.")
		return result
	real_runs.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.started_utc) < str(b.started_utc))
	var selected := real_runs.slice(-5)
	result.status = "passed_numeric_checks"
	# Second-resolution timestamps cannot establish the boundary when two runs tie.
	if real_runs.size() > 5 and real_runs[-6].started_utc == selected[0].started_utc:
		result.status = "unverified"
		result.reasons.append("Timestamp tie at five-run boundary; chronological selection is ambiguous.")
	for run: Dictionary in selected:
		var reasons: Array[String] = []
		var max_gap := 0.0
		var first: Variant = run.get("first_decision_seconds")
		if first == null:
			reasons.append("No measured first combat decision.")
		else:
			max_gap = float(first)
			if first >= 30.0:
				reasons.append("First decision is not below 30 seconds.")
		for interval in run.get("decision_intervals", []):
			max_gap = maxf(max_gap, float(interval))
		var covered := float(first) if first != null else 0.0
		for interval in run.get("decision_intervals", []):
			covered += float(interval)
		if first != null and absf(covered - float(run.get("combat_seconds", 0))) > 0.001:
			reasons.append("Decision intervals do not cover the recorded combat time; final tail may be missing.")
		if max_gap > 45.0:
			reasons.append("Decision gap exceeds 45 seconds, including initial wait and final tail.")
		if run.get("metadata", {}).get("resumed_without_earlier_telemetry", false):
			reasons.append("Legacy resume omits the beginning of the run.")
		if run.get("dropped_events", 0) > 0:
			reasons.append("Event truncation prevents a complete decision audit.")
		if run.get("decision_intervals", []).is_empty():
			reasons.append("No measured final tail or inter-decision interval.")
		result.runs.append({"run_id": run.run_id, "started_utc": run.started_utc,
			"first_decision_seconds": first, "max_gap_seconds": max_gap,
			"spawn_wait_seconds": run.get("spawn_wait_seconds", 0), "reasons": reasons})
		if not reasons.is_empty():
			result.status = "not_met"
	return result

func collect_choices(events: Array, choices: Dictionary, thinking: Array) -> void:
	var decisions := {}
	for event in events:
		if not event is Dictionary or not event.get("data") is Dictionary:
			continue
		var payload: Dictionary = event.data
		if event.get("type") == "decision_open":
			if payload.get("kind") in ["shop", "shop_reroll"]:
				continue # Purchases are not mutually exclusive picker choices.
			var available := {}
			for offer in payload.get("offers", []):
				if offer is Dictionary and offer.has("id"):
					var key := "%s/%s/%s" % [payload.get("kind", "unknown"), offer.get("type", "option"), offer.id]
					available[str(offer.id)] = key
			for key in available.values():
				if not choices.has(key):
					choices[key] = {"offered": 0, "picked": 0}
				choices[key].offered += 1
			decisions[payload.get("id", -1)] = available
		elif event.get("type") == "decision_chosen":
			thinking.append(float(payload.get("think_seconds", 0)))
			var available: Dictionary = decisions.get(payload.get("id", -1), {})
			var selected: Dictionary = payload.get("selected", {})
			var id := str(selected.get("id", ""))
			if available.has(id):
				choices[available[id]].picked += 1
			decisions.erase(payload.get("id", -1))

func increment(counts: Dictionary, key: String) -> void:
	counts[key] = int(counts.get(key, 0)) + 1

func summarize(values: Array) -> Dictionary:
	if values.is_empty():
		return {"count": 0}
	values.sort()
	return {"count": values.size(), "p10": values[int((values.size() - 1) * 0.1)],
		"median": values[int((values.size() - 1) * 0.5)], "p90": values[int((values.size() - 1) * 0.9)], "max": values[-1]}
