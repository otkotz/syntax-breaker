extends Node

const ShopUpgradeIconsScript = preload("res://scripts/ui/shop_upgrade_icons.gd")

class TestShop extends Shop:
	func _refresh_ui() -> void:
		pass

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func _visual_children_ignore_input(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is Control and child.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return false
		if not _visual_children_ignore_input(child):
			return false
	return true

func _has_texture(node: Node, expected: Texture2D) -> bool:
	if node is TextureRect and (node as TextureRect).texture == expected:
		return true
	for child: Node in node.get_children():
		if _has_texture(child, expected):
			return true
	return false

func run_checks() -> void:
	RunManager.start_run()
	RunManager.gold = 100
	var shop := TestShop.new()
	var passive := load("res://resources/passives/heavy_hitter.tres") as PassiveResource
	var offering := {"type": "passive", "resource": passive, "cost": 10}
	shop._offerings = [offering]
	var card := shop._create_card(offering)
	check(card is Button, "Offer is one semantic button")
	check(card.custom_minimum_size.y >= 130.0, "Offer meets the mobile touch height")
	check(_visual_children_ignore_input(card), "Every visual child ignores pointer input")
	if card is Button:
		(card as Button).pressed.emit()
		check(RunManager.gold == 90, "A card press spends exactly once")
		(card as Button).pressed.emit()
		check(RunManager.gold == 90, "A stale second press cannot spend twice")

	var expensive := {"type": "passive", "resource": passive, "cost": 999}
	shop._offerings = [expensive]
	var disabled_card := shop._create_card(expensive)
	shop._set_card_affordability(disabled_card, expensive)
	check(disabled_card.disabled, "Unaffordable card is disabled")
	var gold_before := RunManager.gold
	disabled_card.pressed.emit()
	check(RunManager.gold == gold_before, "Disabled offer never spends gold")
	for key: String in ["damage", "cooldown", "crit_chance"]:
		var icon: Texture2D = ShopUpgradeIconsScript.get_icon(key)
		check(icon != null and icon.get_size().x >= 64.0 and icon.get_size().y >= 64.0,
			"Stat upgrade has readable art: " + key)
	var upgrade := shop._make_stat_upgrade(Shop.STAT_UPGRADES[0])
	shop._offerings = [upgrade]
	var upgrade_card := shop._create_card(upgrade)
	check(_has_texture(upgrade_card, ShopUpgradeIconsScript.get_icon("damage")),
		"Upgrade card renders its dedicated icon")
	card.free()
	disabled_card.free()
	upgrade_card.free()
	shop.free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
