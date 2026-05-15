extends SceneTree

const CORE_TESTS := preload("res://tests/test_core.gd")

func _initialize() -> void:
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
	var suite: RefCounted = CORE_TESTS.new()
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
	var failures: PackedStringArray = suite.run(context)
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)
