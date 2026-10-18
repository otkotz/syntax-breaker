extends Node

const SCHEMA_VERSION := 1
const MAX_EVENTS := 5000
const EXPEDITION_EVENT_TYPES: Array[String] = ["room_source", "rolled_result", "decision", "loadout_delta", "forge_commitment", "post_run_settlement"]
const EXPEDITION_PAYLOAD_KEYS: Array[String] = ["room_id", "room_type", "source_tag", "reward_id", "artifact_id", "artifact_ids", "action", "slot", "before_ids", "after_ids", "commitment_id", "cost", "shards", "status", "new_ids", "duplicate_ids", "difficulty", "blood_omen"]
var enabled: bool = true
var log_directory: String = "user://telemetry"
var data: Dictionary = {}
var active: bool = false
var _open_decisions: Dictionary = {}
var _decision_serial: int = 0
var _last_opportunity: float = 0.0
var _has_opportunity: bool = false
var _pending_expedition_events: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameBus.enemy_killed.connect(_on_enemy_killed)

func _process(delta: float) -> void:
	if active:
		data.app_seconds += delta

func begin(metadata: Dictionary, synthetic: bool = false) -> void:
	if not enabled:
		return
	if active:
		finish("abandoned", [])
	data = {
		"schema_version": SCHEMA_VERSION,
		"run_id": Crypto.new().generate_random_bytes(12).hex_encode(),
		"started_utc": Time.get_datetime_string_from_system(true),
		"source": "synthetic" if synthetic or DisplayServer.get_name() == "headless" else "playtest",
		"metadata": metadata.duplicate(true), "status": "in_progress",
		"app_seconds": 0.0, "combat_seconds": 0.0, "spawn_wait_seconds": 0.0,
		"decision_intervals": [], "first_decision_seconds": null,
		"spawns_by_role": {}, "kills": 0, "stages": [], "events": [], "dropped_events": 0,
		"frame_samples": 0, "frame_ms_sum": 0.0, "frame_ms_max": 0.0, "frames_over_33ms": 0,
		"expedition_event_keys": [],
	}
	active = true
	_open_decisions.clear()
	_decision_serial = 0
	_last_opportunity = 0.0
	_has_opportunity = false
	record("run_start", {})
	var queued := _pending_expedition_events.duplicate(true)
	_pending_expedition_events.clear()
	for event: Dictionary in queued:
		record_expedition(str(event.type), str(event.id), event.payload)
	flush()

func record(event_type: String, payload: Dictionary) -> void:
	if not active:
		return
	if data.events.size() >= MAX_EVENTS:
		data.dropped_events += 1
		return
	data.events.append({"type": event_type, "combat_seconds": data.combat_seconds,
		"app_seconds": data.app_seconds, "data": payload.duplicate(true)})

func record_expedition(event_type: String, event_id: String, payload: Dictionary) -> bool:
	if not EXPEDITION_EVENT_TYPES.has(event_type) or event_id.is_empty(): return false
	if not active:
		if event_type != "forge_commitment" or _pending_expedition_events.size() >= 32: return false
		_pending_expedition_events.append({"type": event_type, "id": event_id.left(96), "payload": _bounded_expedition_payload(payload)})
		return true
	if data.events.size() >= MAX_EVENTS: return false
	if not data.has("expedition_event_keys"): data["expedition_event_keys"] = []
	var event_key := event_type + ":" + event_id.left(96)
	if data.expedition_event_keys.has(event_key): return false
	var bounded := _bounded_expedition_payload(payload)
	bounded["event_id"] = event_id.left(96)
	data.expedition_event_keys.append(event_key)
	record("expedition_" + event_type, bounded)
	return true

func _bounded_expedition_payload(payload: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in EXPEDITION_PAYLOAD_KEYS:
		if not payload.has(key): continue
		var value: Variant = payload[key]
		if value is String:
			result[key] = str(value).left(96)
		elif value is bool or value is int or value is float:
			result[key] = value
		elif value is Array:
			var bounded_values: Array[String] = []
			for item: Variant in value.slice(0, 8): bounded_values.append(str(item).left(64))
			result[key] = bounded_values
	return result

func begin_stage(stage: StageData) -> void:
	if not active:
		return
	end_stage("left")
	data.stages.append({"depth": stage.depth, "type": stage.get_type_name(), "modifiers": stage.modifiers.duplicate(),
		"start_combat": data.combat_seconds, "start_hp": RunManager.current_hp,
		"start_gold": RunManager.gold + RunManager.gold_fraction, "spawns": {}, "kills": 0,
		"combat_seconds": 0.0, "spawn_wait_seconds": 0.0, "status": "in_progress"})
	record("stage_start", {"depth": stage.depth, "type": stage.get_type_name()})

func end_stage(result: String, spawn_summary: Dictionary = {}) -> void:
	if not active or data.stages.is_empty():
		return
	var stage: Dictionary = data.stages[-1]
	if stage.status != "in_progress":
		return
	stage.status = result
	stage.end_hp = RunManager.current_hp
	stage.end_gold = RunManager.gold + RunManager.gold_fraction
	stage.spawn_summary = spawn_summary.duplicate(true)
	record("stage_end", {"depth": stage.depth, "result": result})
	flush()

func tick_combat(delta: float, waiting_for_spawn: bool) -> void:
	if not active:
		return
	data.combat_seconds += delta
	data.frame_samples += 1
	data.frame_ms_sum += delta * 1000.0
	data.frame_ms_max = maxf(data.frame_ms_max, delta * 1000.0)
	if delta > 0.033:
		data.frames_over_33ms += 1
	if waiting_for_spawn:
		data.spawn_wait_seconds += delta
	if not data.stages.is_empty():
		var stage: Dictionary = data.stages[-1]
		stage.combat_seconds += delta
		if waiting_for_spawn:
			stage.spawn_wait_seconds += delta

func enemy_spawned(role: String) -> void:
	if not active:
		return
	data.spawns_by_role[role] = int(data.spawns_by_role.get(role, 0)) + 1
	if not data.stages.is_empty():
		var stage: Dictionary = data.stages[-1]
		stage.spawns[role] = int(stage.spawns.get(role, 0)) + 1

func _on_enemy_killed(_enemy: Node2D, _skill: Resource) -> void:
	if active:
		data.kills += 1
		if not data.stages.is_empty():
			data.stages[-1].kills += 1

func open_decision(kind: String, offers: Array = []) -> int:
	if not active:
		return 0
	_decision_serial += 1
	_open_decisions[_decision_serial] = {"kind": kind, "opened_app": data.app_seconds}
	if kind != "starter" and data.combat_seconds > 0.0:
		if not _has_opportunity:
			data.first_decision_seconds = data.combat_seconds
		else:
			data.decision_intervals.append(data.combat_seconds - _last_opportunity)
		_has_opportunity = true
		_last_opportunity = data.combat_seconds
	record("decision_open", {"id": _decision_serial, "kind": kind, "offers": offers})
	return _decision_serial

func choose(id: int, selected: Dictionary) -> void:
	if not active or not _open_decisions.has(id):
		return
	var decision: Dictionary = _open_decisions[id]
	record("decision_chosen", {"id": id, "kind": decision.kind,
		"think_seconds": data.app_seconds - decision.opened_app, "selected": selected})
	_open_decisions.erase(id)

func describe_offer(offer: Dictionary) -> Dictionary:
	var result := {"type": offer.get("type", "unknown")}
	if offer.has("resource"):
		result["id"] = offer.resource.id
	elif offer.has("mutation"):
		result["id"] = offer.mutation.id
	elif offer.has("upgrade"):
		result["id"] = offer.upgrade.key
	for key in ["cost", "tier", "amount", "fraction", "skill_index"]:
		if offer.has(key):
			result[key] = offer[key]
	return result

func describe_offers(offers: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for offer: Dictionary in offers:
		result.append(describe_offer(offer))
	return result

func snapshot() -> Dictionary:
	if not active:
		return {}
	return {"data": data.duplicate(true), "decision_serial": _decision_serial,
		"last_opportunity": _last_opportunity, "has_opportunity": _has_opportunity}

func restore(saved: Dictionary) -> void:
	# A legacy/invalid save must not inherit a previously active recording.
	active = false
	data = {}
	_open_decisions.clear()
	_decision_serial = 0
	_last_opportunity = 0.0
	_has_opportunity = false
	if not enabled or saved.is_empty():
		return
	data = saved.get("data", {}).duplicate(true)
	if data.get("schema_version", 0) != SCHEMA_VERSION or data.get("status", "") != "in_progress":
		active = false
		return
	active = true
	_decision_serial = int(saved.get("decision_serial", 0))
	_last_opportunity = float(saved.get("last_opportunity", 0.0))
	_has_opportunity = bool(saved.get("has_opportunity", false))
	_open_decisions.clear()
	record("run_resumed", {})
	flush()

func finish(result: String, build: Array) -> bool:
	if not active:
		return false
	end_stage(result)
	data.status = result
	data.final_build = build.duplicate(true)
	data.run_stats = RunManager.run_stats.duplicate(true)
	data.death_source = RunManager.run_stats.get("death_source", "")
	if _has_opportunity:
		data.decision_intervals.append(data.combat_seconds - _last_opportunity)
	record("run_end", {"result": result})
	var success := flush()
	active = false
	return success

func flush() -> bool:
	if not active or not enabled:
		return false
	if DirAccess.make_dir_recursive_absolute(log_directory) != OK:
		return false
	var path := log_directory.path_join(str(data.run_id) + ".json")
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK
