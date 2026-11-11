extends SceneTree


func _initialize() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var data_repository: Node = root.get_node("DataRepository")
	var game_state: Node = root.get_node("GameState")
	var ai_director = root.get_node("AIDirector")

	data_repository.load_all("res://data")
	game_state.reset_state()
	ai_director.load_settings()

	var result: Dictionary = await ai_director.run_test_request()
	var safety_summary: Dictionary = ai_director.get_safety_summary()
	var last_request: Dictionary = {}
	var request_history: Array = safety_summary.get("request_history", [])
	if not request_history.is_empty():
		last_request = request_history.back()

	var output := {
		"source_type": str(result.get("source_type", "")),
		"fallback_used": bool(result.get("fallback_used", false)),
		"failure_reason": str(result.get("failure_reason", result.get("reason", ""))),
		"fallback_event_id": str(result.get("fallback_event_id", "")),
		"candidate": result.get("candidate", {}),
		"last_request": last_request
	}

	print(JSON.stringify(output))

	var exit_code := 2
	if output["source_type"] == "ai" and not bool(output["fallback_used"]):
		exit_code = 0
	elif bool(output["fallback_used"]) and str(output["failure_reason"]) == "no_api_key":
		exit_code = 0

	await ai_director.drain_http_requests()
	call_deferred("_finish", exit_code)


func _finish(exit_code: int) -> void:
	quit(exit_code)
