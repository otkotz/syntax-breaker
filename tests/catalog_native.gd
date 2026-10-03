extends Node

const CATEGORIES := ["skills", "supports", "passives", "unlocks", "regions", "consumables"]
const DOCUMENT := "res://docs/catalog-snapshot.md"
var failures: Array[String] = []
var counts: Dictionary = {}

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var lines := PackedStringArray(["<!-- catalog:start -->", "| Category | Count |", "| --- | ---: |"])
	for category: String in CATEGORIES:
		var directory := "res://resources/%s/" % category
		var files := ResourceListing.get_resource_files(directory)
		files.sort()
		var ids: Array[String] = []
		var registry: Array = ResourceListing._REGISTRY.get(directory, [])
		if files.size() != registry.size():
			failures.append("Export registry size differs: %s" % category)
		for filename: String in files:
			var resource := load(directory + filename)
			if resource == null:
				failures.append("Failed to load: %s%s" % [directory, filename])
				continue
			var id: String = resource.get("id")
			if id.is_empty() or ids.has(id):
				failures.append("Empty or duplicate %s ID: %s" % [category, id])
			ids.append(id)
			if not registry.has(filename.get_basename()):
				failures.append("Missing from Android registry: %s%s" % [directory, filename])
		lines.append("| %s | %d |" % [category, files.size()])
		counts[category] = files.size()
	var mutation_ids: Array[String] = []
	for mutation: Dictionary in MutationData.POOL:
		var id: String = mutation.get("id", "")
		if id.is_empty() or mutation_ids.has(id):
			failures.append("Empty or duplicate mutation ID: %s" % id)
		mutation_ids.append(id)
	mutation_ids.sort()
	lines.append("| mutations | %d |" % mutation_ids.size())
	lines.append("| registered behaviors | %d |" % BehaviorRegistry._behaviors.size())
	lines.append("")
	lines.append("Mutation IDs: `%s`." % "`, `".join(mutation_ids))
	lines.append("")
	var region := RegionResource.new()
	var fields: Array[String] = []
	for property: Dictionary in region.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_EDITOR:
			fields.append(property.name)
	fields.sort()
	lines.append("RegionResource exported fields: `%s`." % "`, `".join(fields))
	lines.append("<!-- catalog:end -->")
	var snapshot := "\n".join(lines)
	var output := FileAccess.open("res://.godot/catalog_snapshot.md", FileAccess.WRITE)
	if output:
		output.store_string(snapshot + "\n")
		output.close()
	else:
		failures.append("Cannot write generated snapshot")
	if not OS.get_cmdline_user_args().has("--emit"):
		var document := FileAccess.get_file_as_string(DOCUMENT).replace("\r\n", "\n")
		if not matches_snapshot(document, snapshot):
			failures.append("Catalog documentation is stale; inspect .godot/catalog_snapshot.md")
		var overview := FileAccess.get_file_as_string("res://docs/design-overview.md")
		for category: String in ["skills", "supports", "passives", "regions", "consumables"]:
			var prefix := "###" if category in ["skills", "supports", "passives"] else "##"
			if not overview.contains("%s %s (%d)" % [prefix, category.capitalize(), counts[category]]):
				failures.append("Design overview has stale count: %s" % category)
		if not overview.contains("## Mutations (%d)" % mutation_ids.size()):
			failures.append("Design overview has stale mutation count")
	if not matches_snapshot("Introduction\n" + snapshot + "\nNotes", snapshot):
		failures.append("Snapshot checker rejects surrounding prose")
	if matches_snapshot(snapshot.replace("| skills |", "| changed |"), snapshot):
		failures.append("Snapshot checker accepts changed catalog")
	if matches_snapshot(snapshot.replace("<!-- catalog:end -->", ""), snapshot):
		failures.append("Snapshot checker accepts missing marker")
	print(JSON.stringify({"failures": failures, "categories": CATEGORIES.size(), "mutations": mutation_ids.size()}))
	get_tree().quit(0 if failures.is_empty() else 1)

func matches_snapshot(document: String, snapshot: String) -> bool:
	var begin := document.find("<!-- catalog:start -->")
	var end := document.find("<!-- catalog:end -->")
	return begin >= 0 and end >= begin and document.substr(begin, end + "<!-- catalog:end -->".length() - begin) == snapshot
