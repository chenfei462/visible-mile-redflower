extends RefCounted


static func estimate_minutes(profile: Dictionary, scenario_id: String = "normal") -> float:
	var scenario: Dictionary = _get_scenario(profile, scenario_id)
	var actions: Dictionary = scenario.get("actions", {})
	var costs: Dictionary = profile.get("action_cost_seconds", {})
	var total_seconds := 0.0
	total_seconds += float(actions.get("pick", 0)) * float(costs.get("pick", 20))
	total_seconds += float(actions.get("craft", 0)) * float(costs.get("craft", 25))
	total_seconds += float(actions.get("build", actions.get("place", 0))) * float(costs.get("build", costs.get("place", 20)))
	total_seconds += float(actions.get("problem", 0)) * float(costs.get("problem", 25))
	total_seconds += float(actions.get("reading", 0)) * float(costs.get("reading", 60))
	total_seconds += float(actions.get("settlement", 0)) * float(costs.get("settlement", 45))
	return total_seconds / 60.0


static func build_scenario_metrics(profile: Dictionary, scenario_id: String) -> Dictionary:
	var scenario: Dictionary = _get_scenario(profile, scenario_id)
	var metrics: Dictionary = scenario.get("metrics", {}).duplicate(true)
	metrics["scenario_id"] = scenario_id
	metrics["estimated_minutes"] = estimate_minutes(profile, scenario_id)
	return metrics


static func is_rating_expected(metrics: Dictionary, scenario_id: String, profile: Dictionary) -> bool:
	var scenario: Dictionary = _get_scenario(profile, scenario_id)
	var expected_ratings: Array = scenario.get("expected_ratings", [])
	return expected_ratings.has(str(metrics.get("rating", "")))


static func get_demo_goal(profile: Dictionary) -> Dictionary:
	return profile.get("demo_goal", {}).duplicate(true)


static func _get_scenario(profile: Dictionary, scenario_id: String) -> Dictionary:
	var scenarios: Dictionary = profile.get("scenarios", {})
	return scenarios.get(scenario_id, {})
