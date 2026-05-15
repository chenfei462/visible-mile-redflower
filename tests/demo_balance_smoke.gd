extends SceneTree

const BALANCE_PROFILE := preload("res://scripts/core/BalanceProfile.gd")

var _failures: PackedStringArray = []


func _initialize() -> void:
	if not root.has_node("DataRepository"):
		push_error("Missing autoload node: DataRepository")
		quit(1)
		return

	var repository: Node = root.get_node("DataRepository")
	if not repository.load_all("res://data"):
		_failures.append("repository should load demo balance targets")

	var profile: Dictionary = repository.demo_balance_targets
	_check_scenario(profile, "conservative", ["C", "B"], false)
	_check_scenario(profile, "normal", ["B", "A"], true)
	_check_scenario(profile, "optimized", ["A"], false)

	if _failures.is_empty():
		print("DEMO BALANCE SMOKE PASSED")
		quit(0)
		return

	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check_scenario(profile: Dictionary, scenario_id: String, expected_ratings: Array, should_hit_target_window: bool) -> void:
	var metrics: Dictionary = BALANCE_PROFILE.build_scenario_metrics(profile, scenario_id)
	print("%s metrics: %s" % [scenario_id, JSON.stringify(metrics)])
	var rating := str(metrics.get("rating", ""))
	if not expected_ratings.has(rating):
		_failures.append("%s rating should be in %s, got %s" % [scenario_id, str(expected_ratings), rating])
	if int(metrics.get("final_day", 0)) != 10:
		_failures.append("%s should finish on day 10" % scenario_id)
	var minutes := float(metrics.get("estimated_minutes", 0.0))
	if minutes < 45.0 or minutes > 60.0:
		_failures.append("%s should estimate 45-60 minutes, got %.2f" % [scenario_id, minutes])
	if should_hit_target_window and (minutes < 50.0 or minutes > 55.0):
		_failures.append("%s should estimate the 50-55 minute target, got %.2f" % [scenario_id, minutes])
	if scenario_id == "normal" and not ["B", "A"].has(rating):
		_failures.append("normal route should not finish below B")
	if scenario_id == "optimized" and rating == "S":
		_failures.append("optimized demo route should not require S")
