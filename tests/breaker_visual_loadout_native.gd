extends Node

const VISUAL_LOADOUT := preload("res://scripts/player/breaker_visual_loadout.gd")
const BUILD_PORTRAIT := preload("res://scripts/ui/build_portrait.gd")

var failures := 0

func _ready() -> void:
	var fire := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	var lightning := SkillInstance.new(load("res://resources/skills/lightning_bolt.tres"))
	var rollback := SkillInstance.new(load("res://resources/skills/blade_spin.tres"))
	var first: Dictionary = VISUAL_LOADOUT.resolve([lightning, fire, rollback], ["bloodwritten_sigil", "furnace_heart"])
	var second: Dictionary = VISUAL_LOADOUT.resolve([rollback, lightning, fire], ["furnace_heart", "bloodwritten_sigil"])
	_check(first == second, "loadout is independent from save/load ordering")
	_check(first.element == "fire", "stable tie priority chooses fire")
	_check(first.layers.size() <= 3, "visible layer budget is capped at three")
	_check(first.layers.has("emblem"), "bloodwritten sigil claims emblem slot")
	_check(first.layers.has("back"), "ember covenant claims back slot")
	for dir: String in BreakerSprite.DIRS:
		for layer: String in ["focus", "back", "body_accent", "emblem"]:
			var anchor: Vector2 = VISUAL_LOADOUT.anchor_for(layer, dir)
			_check(anchor.x >= 2.0 and anchor.x <= 29.0 and anchor.y >= 3.0 and anchor.y < 30.0,
				"%s anchor stays clear of hood/feet in %s" % [layer, dir])
	var portrait := BUILD_PORTRAIT.new()
	portrait.setup(first)
	_check(portrait.custom_minimum_size.x >= 160.0, "portrait is authored at bust scale")
	_check(portrait.loadout == first, "portrait uses the exact combat loadout")
	var buffer := BreakerSprite.build("S", 0, "idle", 0.0, first)
	_check(buffer.w == 32 and buffer.h == 36, "reactive sprite preserves gameplay footprint")
	_check(Player.SHIELD_SEGMENTS == 4, "shield language is segmented")
	portrait.free()
	if failures == 0:
		print("breaker_visual_loadout_native: PASS")
	get_tree().quit(failures)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
