extends SceneTree


func _initialize() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var data_repository: Node = root.get_node("DataRepository")
	var game_state: Node = root.get_node("GameState")
	var ai_director = root.get_node("AIDirector")
	var event_manager: Node = root.get_node("EventManager")

	data_repository.load_all("res://data")
	game_state.reset_state()
	event_manager.reset_runtime()
	ai_director.load_settings()

	var state: Dictionary = game_state.get_state()
	state["day_count"] = 4

	var event_lines: PackedStringArray = await event_manager.resolve_sunrise_events_async()
	var announcements: Array = state.get("announcement_queue", [])
	var active_problems: Array = state.get("active_problems", [])
	var safety_summary: Dictionary = ai_director.get_safety_summary()
	var last_request: Dictionary = {}
	var request_history: Array = safety_summary.get("request_history", [])
	if not request_history.is_empty():
		last_request = request_history.back()

	var output := {
		"event_lines": event_lines,
		"announcement_count": announcements.size(),
		"problem_count": active_problems.size(),
		"source_type": "",
		"fallback_used": false,
		"last_request": last_request
	}
	if not active_problems.is_empty():
		output["source_type"] = str(active_problems[0].get("source_type", ""))
	if not announcements.is_empty():
		output["fallback_used"] = bool(announcements[0].get("fallback_used", false))

	print(JSON.stringify(output))

	var exit_code := 2
	if output["source_type"] == "ai" and not bool(output["fallback_used"]):
		exit_code = 0

	await ai_director.drain_http_requests()
	call_deferred("_finish", exit_code)


func _finish(exit_code: int) -> void:
	quit(exit_code)
