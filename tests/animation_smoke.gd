extends SceneTree

var failures: PackedStringArray = []
var main_view: Control
var settings_manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	settings_manager = root.get_node("SettingsManager")
	settings_manager.reset_to_defaults(false)
	settings_manager.set_value("reduce_motion", false)

	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	main_view = main_scene.instantiate()
	root.add_child(main_view)
	await process_frame
	await process_frame

	_assert_true(main_view.get("animation_layer") != null, "main view should expose an animation layer")
	_assert_true(main_view.call("_motion_enabled"), "motion should be enabled when reduce_motion is false")
	main_view.call("_clear_transient_animations")

	var start_rect := Rect2(Vector2(80, 80), Vector2(160, 116))
	var end_rect := Rect2(Vector2(320, 120), Vector2(160, 116))
	main_view.call("_animate_card_fly", "ramp_blueprint", start_rect, end_rect, "test")
	_assert_true(int(main_view.call("_animation_layer_child_count")) > 0, "card fly should create a temporary ghost")
	await create_timer(0.35).timeout
	_assert_equal(int(main_view.call("_animation_layer_child_count")), 0, "card fly ghost should clean itself up")

	main_view.call("_show_unlock_banner", [0, 1])
	main_view.call("_animate_tutorial_pointer", "bulletin")
	_assert_true(int(main_view.call("_animation_layer_child_count")) >= 2, "banner and tutorial pointer should create temporary UI")
	main_view.call("_refresh_tutorial_pointer")
	_assert_true(int(main_view.call("_animation_layer_child_count")) >= 2, "active tutorial state should keep a pointer visible")

	settings_manager.set_value("reduce_motion", true)
	main_view.call("_clear_transient_animations")
	_assert_true(not bool(main_view.call("_motion_enabled")), "motion should be disabled when reduce_motion is true")
	main_view.call("_animate_card_fly", "ramp_blueprint", start_rect, end_rect, "test")
	main_view.call("_show_unlock_banner", [0])
	main_view.call("_animate_tutorial_pointer", "hand")
	_assert_equal(int(main_view.call("_animation_layer_child_count")), 0, "reduce motion should skip transient animation nodes")

	main_view.queue_free()
	if failures.is_empty():
		print("ANIMATION SMOKE PASSED")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
