extends SceneTree

const CORE_TESTS_PATH := "res://tests/test_core.gd"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var required_nodes := [
		"DataRepository",
		"ResourceManager",
		"GameState",
		"DayCycle",
		"TutorialManager",
		"AIDirector",
		"EventManager",
		"SettingsManager",
		"AudioManager",
		"SaveManager",
		"SteamBridge"
	]
	for node_name: String in required_nodes:
		if not root.has_node(node_name):
			push_error("Missing autoload node: %s" % node_name)
			quit(1)
			return
	var suite_script: Script = load(CORE_TESTS_PATH)
	if suite_script == null:
		push_error("Missing core test suite script: %s" % CORE_TESTS_PATH)
		quit(1)
		return
	var suite: RefCounted = suite_script.new()
	var context := {
		"data_repository": root.get_node("DataRepository"),
		"resource_manager": root.get_node("ResourceManager"),
		"game_state": root.get_node("GameState"),
		"day_cycle": root.get_node("DayCycle"),
		"tutorial_manager": root.get_node("TutorialManager"),
		"ai_director": root.get_node("AIDirector"),
		"event_manager": root.get_node("EventManager"),
		"settings_manager": root.get_node("SettingsManager"),
		"audio_manager": root.get_node("AudioManager"),
		"save_manager": root.get_node("SaveManager"),
		"steam_bridge": root.get_node("SteamBridge")
	}
	var failures: PackedStringArray = await suite.run(context)
	suite = null
	suite_script = null
	context.clear()
	call_deferred("_finish", failures)


func _finish(failures: PackedStringArray) -> void:
	await process_frame
	await process_frame
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)
