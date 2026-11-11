extends SceneTree

const SUITE_PATH := "res://tests/test_core.gd"
const TARGET_METHODS := [
	"_test_card_view_uses_full_card_art_as_background",
	"_test_card_view_keeps_icon_art_inside_inset_frame",
	"_test_selected_art_manifest_entries_load_custom_assets",
	"_test_art_manifest_uses_existing_assets_for_referenced_keys",
	"_test_opening_card_art_manifest_loads_35_custom_card_faces",
	"_test_full_card_art_remains_legible_when_dimmed",
	"_test_demand_cards_reuse_resident_full_card_art"
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var suite_script: Script = load(SUITE_PATH)
	if suite_script == null:
		push_error("Missing core test suite script: %s" % SUITE_PATH)
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
	suite.set("_failures", PackedStringArray())
	suite.set("_context", context)
	for method_name: String in TARGET_METHODS:
		await suite.call(method_name)
	var failures: PackedStringArray = suite.get("_failures")
	if failures.is_empty():
		print("TARGETED CARD ART TESTS PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)
