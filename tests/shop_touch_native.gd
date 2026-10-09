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
	var stale_offer := {"type": "passive", "resource": passive, "cost": 10}
	shop._offerings = [stale_offer]
	var stale_card := shop._create_card(stale_offer)
	shop._offer_generation += 1
	shop._offerings = [stale_offer.duplicate(true)]
	var gold_before_stale := RunManager.gold
	stale_card.pressed.emit()
	check(RunManager.gold == gold_before_stale,
		"A stale card cannot buy an equal-valued offer from a newer refresh")
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
	stale_card.free()
	upgrade_card.free()
	shop.free()

	RunManager.gold = 1000
	var live_shop := load("res://scenes/ui/shop.tscn").instantiate() as Shop
	live_shop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(live_shop)
	await get_tree().process_frame
	var live_offers: Array[Dictionary] = []
	for index: int in 20:
		live_offers.append({"type": "passive", "resource": passive, "cost": 10 + index})
	live_shop._offerings = live_offers
	live_shop._refresh_ui()
	await get_tree().process_frame
	await get_tree().process_frame
	var scroller := live_shop.item_list.get_parent() as ScrollContainer
	check(scroller.get_v_scroll_bar().max_value > scroller.size.y, "Long shop inventory remains scrollable")
	var live_card := live_shop.item_list.get_child(0) as Button
	var gold_before_scroll := RunManager.gold
	var wheel := InputEventMouseButton.new()
	wheel.position = live_card.get_global_rect().get_center()
	wheel.global_position = wheel.position
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	get_tree().root.push_input(wheel, true)
	await get_tree().process_frame
	check(scroller.scroll_vertical > 0, "Scrolling over the card moves the shop list")
	check(RunManager.gold == gold_before_scroll, "Scrolling over the card does not buy it")
	scroller.scroll_vertical = 0
	await get_tree().process_frame
	var padding_point := live_card.global_position + Vector2(5, 5)
	click(padding_point)
	await get_tree().process_frame
	check(RunManager.gold == gold_before_scroll - 10, "Tapping card padding purchases the offer")
	live_shop.queue_free()
	await get_tree().process_frame
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func click(point: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.position = point
	down.global_position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_tree().root.push_input(down, true)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	get_tree().root.push_input(up, true)
