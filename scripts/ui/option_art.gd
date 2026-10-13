class_name OptionArt
extends RefCounted

const EVOLUTION_DIR := "res://assets/icons/evolutions/"
const MUTATION_DIR := "res://assets/icons/mutations/"
const SYSTEM_DIR := "res://assets/icons/system/"

static func resolve(offer: Variant) -> Texture2D:
	if offer is Resource and "icon" in offer and offer.icon is Texture2D:
		return offer.icon
	if offer is Dictionary:
		var explicit: Variant = offer.get("icon")
		if explicit is Texture2D:
			return explicit
		var resource: Variant = offer.get("resource")
		if resource != null:
			var resource_art := resolve(resource)
			if resource_art:
				return resource_art
		var nested_mutation: Variant = offer.get("mutation")
		if nested_mutation is Dictionary:
			return resolve(nested_mutation)
		var path := str(offer.get("icon_path", ""))
		if not path.is_empty() and ResourceLoader.exists(path):
			var loaded := load(path) as Texture2D
			if loaded:
				return loaded
		var evolution_id := str(offer.get("evolution_id", ""))
		if not evolution_id.is_empty():
			var evolution_art := _load_icon(EVOLUTION_DIR + evolution_id + ".png")
			if evolution_art:
				return evolution_art
		var id := str(offer.get("id", ""))
		if not id.is_empty():
			var mutation_art := _load_icon(MUTATION_DIR + id + ".png")
			if mutation_art:
				return mutation_art
		var semantic: String = {"support_slot": "hot_socket", "gold": "gold", "heal": "heal",
			"target_selection": "target_selection", "reroll": "reroll"}.get(str(offer.get("type", "")), "")
		if not semantic.is_empty():
			var system_art := _load_icon(SYSTEM_DIR + semantic + ".png")
			if system_art:
				return system_art
	return fallback()

static func badge(offer: Variant) -> String:
	if offer is Resource and "id" in offer and str(offer.id).ends_with("_mastery"):
		return "MASTERY"
	if offer is Dictionary:
		if offer.get("type") == "evolution":
			return EvolutionData.roman(int(offer.get("offered_tier", 0)))
		if offer.get("resource") != null:
			return badge(offer.get("resource"))
	return ""

static func fallback() -> Texture2D:
	return _load_icon(SYSTEM_DIR + "fallback.png")

static func _load_icon(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null
