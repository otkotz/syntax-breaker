extends Node

func _ready() -> void:
	# Separate processes make shutdown diagnostics observable; no policy changes.
	for samples in [48, 480]:
		var log_path := ProjectSettings.globalize_path("res://.godot/economy_cleanup_%d.log" % samples)
		var report_path := "res://.godot/economy_cleanup_%d.json" % samples
		var output: Array = []
		var exit_code := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--scene", "res://tests/economy_simulation.tscn", "--log-file", log_path,
			"--", "--runs=%d" % samples, "--seed=20261003", "--output=" + report_path]), output, true)
		var text := FileAccess.get_file_as_string(log_path)
		if exit_code != 0 or text.contains("ObjectDB instances leaked") or text.contains("resources still in use") or text.contains("SCRIPT ERROR"):
			push_error("Economy teardown regression: " + log_path)
			get_tree().quit(1)
			return
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(report_path))
		if not parsed is Dictionary or parsed.get("runs") != samples or not parsed.get("failures", ["missing"]).is_empty() or parsed.get("scenarios", []).size() != 48:
			push_error("Invalid economy report: " + report_path)
			get_tree().quit(1)
			return
	print("PASS: 48- and 480-run simulations finish without ObjectDB/resource/script warnings; all 48 cohorts and conservation checks pass")
	get_tree().quit(0)
