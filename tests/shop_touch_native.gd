extends Node

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
	card.free()
	disabled_card.free()
	shop.free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
