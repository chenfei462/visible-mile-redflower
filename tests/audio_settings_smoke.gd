extends SceneTree

var failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings_manager: Node = root.get_node("SettingsManager")
	var audio_manager: Node = root.get_node("AudioManager")
	settings_manager.reset_to_defaults(false)
	settings_manager.set_value("music_volume", 0.25)
	settings_manager.set_value("sfx_volume", 0.55)
	await process_frame
	_assert_equal(float(audio_manager.get_music_volume()), 0.25, "AudioManager should follow SettingsManager music volume changes")
	_assert_equal(float(audio_manager.get_sfx_volume()), 0.55, "AudioManager should follow SettingsManager SFX volume changes")
	_assert_true(audio_manager.play_sfx("card_pick"), "registered card_pick SFX should be safe even without an asset")
	_assert_equal(str(audio_manager.get_last_sfx_id()), "card_pick", "AudioManager should record the last SFX id")
	_assert_true(audio_manager.play_bgm("dusk"), "registered dusk BGM should be safe even without an asset")
	_assert_equal(str(audio_manager.get_last_bgm_id()), "dusk", "AudioManager should record the last BGM id")
	settings_manager.set_value("music_volume", 0.0)
	settings_manager.set_value("sfx_volume", 0.0)
	await process_frame
	_assert_equal(float(audio_manager.get_music_volume()), 0.0, "Music volume should support mute")
	_assert_equal(float(audio_manager.get_sfx_volume()), 0.0, "SFX volume should support mute")
	call_deferred("_finish")


func _finish() -> void:
	if failures.is_empty():
		print("AUDIO SETTINGS SMOKE PASSED")
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
