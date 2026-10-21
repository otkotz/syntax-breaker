class_name BreakerVisualLoadout
extends RefCounted

const ELEMENT_PRIORITY: Array[String] = ["fire", "lightning", "poison", "cold", "physical"]
const EMBER_ARTIFACTS: Array[String] = ["furnace_heart", "ashen_needle", "cinder_crown"]
const ANCHORS := {
	"focus": {"N": Vector2(22, 10), "NE": Vector2(25, 12), "E": Vector2(27, 18), "SE": Vector2(25, 23), "S": Vector2(22, 25), "SW": Vector2(9, 23), "W": Vector2(5, 18), "NW": Vector2(7, 12)},
	"back": {"N": Vector2(16, 9), "NE": Vector2(11, 12), "E": Vector2(10, 16), "SE": Vector2(9, 20), "S": Vector2(10, 20), "SW": Vector2(22, 20), "W": Vector2(22, 16), "NW": Vector2(21, 12)},
	"body_accent": {"N": Vector2(16, 19), "NE": Vector2(17, 20), "E": Vector2(16, 21), "SE": Vector2(16, 22), "S": Vector2(16, 22), "SW": Vector2(16, 22), "W": Vector2(16, 21), "NW": Vector2(15, 20)},
	"emblem": {"N": Vector2(16, 20), "NE": Vector2(18, 21), "E": Vector2(18, 22), "SE": Vector2(17, 23), "S": Vector2(16, 23), "SW": Vector2(15, 23), "W": Vector2(14, 22), "NW": Vector2(14, 21)},
}

static func resolve(skill_instances: Array, artifact_ids: Array[String] = []) -> Dictionary:
	var scores := {"fire": 0, "lightning": 0, "poison": 0, "cold": 0, "physical": 0}
	for instance: Variant in skill_instances:
		if instance == null or instance.base == null: continue
		var matched := false
		for element: String in ELEMENT_PRIORITY:
			if instance.base.tags.has(element):
				scores[element] += 1
				matched = true
				break
		if not matched or instance.base.id == "rollback": scores["physical"] += 1
	var element := "physical"
	var best := -1
	for candidate: String in ELEMENT_PRIORITY:
		if int(scores[candidate]) > best:
			best = int(scores[candidate]); element = candidate
	var ids := artifact_ids.duplicate()
	ids.sort()
	var support_ids: Array[String] = []
	for instance: Variant in skill_instances:
		if instance == null: continue
		for support: SupportResource in instance.linked_supports:
			if not support_ids.has(support.id): support_ids.append(support.id)
	support_ids.sort()
	var layers: Array[String] = []
	if ids.has("bloodwritten_sigil"): layers.append("emblem")
	for id: String in ids:
		if id in EMBER_ARTIFACTS and not layers.has("back"):
			layers.append("back")
	if not support_ids.is_empty() and layers.size() < 3: layers.append("body_accent")
	if layers.size() < 3: layers.append("focus")
	if layers.size() < 3: layers.append("body_accent")
	return {"element": element, "layers": layers.slice(0, 3), "artifact_ids": ids,
		"support_ids": support_ids, "focus_shape": _focus_shape(element), "body_accent": _body_accent(element)}

static func anchor_for(layer: String, dir: String) -> Vector2:
	return ANCHORS.get(layer, ANCHORS["body_accent"]).get(dir, Vector2(16, 20))

static func _focus_shape(element: String) -> String:
	return {"fire": "ember_hand", "lightning": "antenna_rune", "poison": "vials", "cold": "crystal_shoulder", "physical": "hooked_forearm"}.get(element, "hooked_forearm")

static func _body_accent(element: String) -> String:
	return {"fire": "charred_hem", "lightning": "forked_rune", "poison": "respirator", "cold": "ice_seam", "physical": "back_bracket"}.get(element, "back_bracket")
