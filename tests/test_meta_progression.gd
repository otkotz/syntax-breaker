extends GutTest

var _condition: UnlockConditionResource

func test_reach_stage_condition_met() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "reach_stage"
	_condition.condition_params = {"stage": 3}
	var stats := {"stages_reached": 3}
	assert_true(_condition.check(stats))

func test_reach_stage_condition_not_met() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "reach_stage"
	_condition.condition_params = {"stage": 3}
	var stats := {"stages_reached": 2}
	assert_false(_condition.check(stats))

func test_kill_count_condition() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "kill_count"
	_condition.condition_params = {"count": 50}
	assert_true(_condition.check({"enemies_killed": 50}))
	assert_false(_condition.check({"enemies_killed": 49}))

func test_complete_run_condition() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "complete_run"
	assert_true(_condition.check({"run_completed": true}))
	assert_false(_condition.check({"run_completed": false}))

func test_kill_mini_boss_condition() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "kill_mini_boss"
	assert_true(_condition.check({"mini_bosses_killed": 1}))
	assert_false(_condition.check({"mini_bosses_killed": 0}))

func test_stat_threshold_with_tag_damage() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "stat_threshold"
	_condition.condition_params = {"stat": "damage_by_tag.fire", "threshold": 1000}
	assert_true(_condition.check({"damage_by_tag": {"fire": 1200}}))
	assert_false(_condition.check({"damage_by_tag": {"fire": 500}}))

func test_max_event_condition() -> void:
	_condition = UnlockConditionResource.new()
	_condition.condition_type = "max_event"
	_condition.condition_params = {"event": "max_aoe_kill", "count": 10}
	assert_true(_condition.check({"max_aoe_kill": 10}))
	assert_false(_condition.check({"max_aoe_kill": 5}))
