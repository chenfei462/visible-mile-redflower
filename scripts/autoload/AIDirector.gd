extends Node

signal settings_changed(settings: Dictionary)
signal request_logged(entry: Dictionary)

const SETTINGS_PATH := "user://ai_settings.json"
const CHAT_COMPLETIONS_PATH := "/chat/completions"
const DEFAULT_SETTINGS := {
	"mode": "hybrid",
	"base_url": "https://api.deepseek.com",
	"api_key": "",
	"model": "deepseek-v4-flash",
	"timeout_seconds": 15,
	"force_local_fallback": false
}
const RESPONSE_FORMAT := {"type": "json_object"}
const FAILURE_NO_API_KEY := "no_api_key"
const FAILURE_TIMEOUT := "timeout"
const FAILURE_INVALID_RESPONSE := "invalid_response"
const FAILURE_BLOCKED_CONTENT := "blocked_content"
const FAILURE_NETWORK_ERROR := "network_error"
const FAILURE_FALLBACK_USED := "fallback_used"

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var request_history: Array[Dictionary] = []
var fallback_count: int = 0
var blocked_count: int = 0
var success_count: int = 0
var last_failure_reason: String = ""
var last_request_status: String = "idle"
var last_fallback_event_id: String = ""
var _request_serial: int = 0
var _active_http_requests: Array = []
var _retiring_http_requests: Array = []


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				for key_variant in settings.keys():
					var key: String = str(key_variant)
					if parsed.has(key):
						settings[key] = parsed.get(key)
	_normalize_settings()
	emit_signal("settings_changed", settings.duplicate(true))


func apply_settings(new_settings: Dictionary, persist: bool = true) -> void:
	for key_variant in DEFAULT_SETTINGS.keys():
		var key: String = str(key_variant)
		if new_settings.has(key):
			settings[key] = new_settings.get(key)
	_normalize_settings()
	if persist:
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(settings))
	emit_signal("settings_changed", settings.duplicate(true))


func save_settings(new_settings: Dictionary) -> void:
	apply_settings(new_settings, true)


func set_force_local_fallback(enabled: bool) -> void:
	settings["force_local_fallback"] = enabled
	save_settings(settings)


func generate_event_candidate(_state_snapshot: Dictionary, event_def: Dictionary) -> Dictionary:
	var mode: String = _mode_name()
	if _should_use_local_mode(mode):
		return _fallback_result(event_def, "local_mode")
	if not _has_remote_config():
		return _fallback_result(event_def, "missing_api_key")
	return _fallback_result(event_def, "sync_request_not_supported")


func request_event_candidate(state_snapshot: Dictionary, event_def: Dictionary) -> Dictionary:
	var mode: String = _mode_name()
	if _should_use_local_mode(mode):
		return _fallback_result(event_def, "local_mode")
	if not _has_remote_config():
		return _fallback_result(event_def, "missing_api_key")
	return await _request_event_candidate_remote(state_snapshot, event_def)


func run_test_request() -> Dictionary:
	var state_snapshot := GameState.get_state().duplicate(true)
	var demo_event: Dictionary = {
		"event_id": "test_request",
		"category": "hybrid",
		"trigger_days": [2],
		"title": "智能测试请求",
		"announcement_text": "验证当前模式、Schema 校验与回退链路。",
		"problem_card_id": "problem_notice_conflict",
		"target_resident_ids": ["xiao_lin"],
		"manpower_required": 2,
		"reward": {"trust": 1},
		"penalty": {"trust": 1, "satisfaction_delta": 2},
		"fallback_event_id": "fallback_market_queue"
	}
	return await request_event_candidate(state_snapshot, demo_event)


func get_safety_summary() -> Dictionary:
	return {
		"settings": settings.duplicate(true),
		"request_count": request_history.size(),
		"fallback_count": fallback_count,
		"blocked_count": blocked_count,
		"success_count": success_count,
		"last_failure_reason": last_failure_reason,
		"last_request_status": last_request_status,
		"last_fallback_event_id": last_fallback_event_id,
		"request_history": request_history.duplicate(true)
	}


func classify_failure_reason(raw_reason: String) -> String:
	var reason := raw_reason.strip_edges()
	match reason:
		"missing_api_key":
			return FAILURE_NO_API_KEY
		"timeout":
			return FAILURE_TIMEOUT
		"content_filter":
			return FAILURE_BLOCKED_CONTENT
		"local_mode", "sync_request_not_supported":
			return FAILURE_FALLBACK_USED
	for token: String in ["not_json", "invalid", "missing_", "empty_", "schema", "response", "http_4", "http_5", "remote_error"]:
		if reason.contains(token):
			return FAILURE_INVALID_RESPONSE
	for token: String in ["cant_connect", "cant_resolve", "connection", "tls", "no_response", "request_failed", "host_unavailable", "busy", "unconfigured"]:
		if reason.contains(token):
			return FAILURE_NETWORK_ERROR
	return FAILURE_NETWORK_ERROR


func fallback_for_failure(event_def: Dictionary, raw_reason: String) -> Dictionary:
	blocked_count += 1
	return _fallback_result(event_def, raw_reason)


func _request_event_candidate_remote(state_snapshot: Dictionary, event_def: Dictionary) -> Dictionary:
	var base_url: String = str(settings.get("base_url", "")).strip_edges()
	var api_key: String = str(settings.get("api_key", "")).strip_edges()
	var mode: String = _mode_name()
	if api_key.is_empty():
		return _maybe_fallback(event_def, "missing_api_key")
	if not _is_valid_base_url(base_url):
		return _maybe_fallback(event_def, "invalid_base_url")

	var request_id := _next_request_id()
	var request_payload := _build_request_payload(state_snapshot, event_def)
	var request_url := "%s%s" % [_normalized_base_url(base_url), CHAT_COMPLETIONS_PATH]
	var request_headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer %s" % api_key
	])
	var http_request := HTTPRequest.new()
	http_request.use_threads = true
	http_request.timeout = float(settings.get("timeout_seconds", 15))
	var request_host: Node = _resolve_request_host()
	if request_host == null:
		return _maybe_fallback(event_def, "http_host_unavailable")
	request_host.add_child(http_request)
	_active_http_requests.append(http_request)
	if not http_request.is_inside_tree():
		await http_request.tree_entered

	var request_error := http_request.request(
		request_url,
		request_headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(request_payload)
	)
	if request_error != OK:
		_release_http_request(http_request)
		return _maybe_fallback(event_def, _request_error_reason(request_error))

	var completed: Array = await http_request.request_completed
	_release_http_request(http_request)
	if completed.size() < 4:
		return _maybe_fallback(event_def, "invalid_http_result")

	var result_code: int = int(completed[0])
	var response_code: int = int(completed[1])
	var response_headers: PackedStringArray = completed[2]
	var response_body: PackedByteArray = completed[3]
	if result_code != HTTPRequest.RESULT_SUCCESS:
		return _maybe_fallback(event_def, _http_result_reason(result_code))
	if response_code < 200 or response_code >= 300:
		return _maybe_fallback(event_def, "http_%d" % response_code)

	var response_text := response_body.get_string_from_utf8().strip_edges()
	if response_text.is_empty():
		return _maybe_fallback(event_def, "empty_response_body")

	var parsed_response: Variant = JSON.parse_string(response_text)
	if typeof(parsed_response) != TYPE_DICTIONARY:
		return _maybe_fallback(event_def, "response_not_json")

	var parsed_dict: Dictionary = parsed_response
	if parsed_dict.has("error"):
		var error_payload: Variant = parsed_dict.get("error", {})
		var error_message := ""
		if typeof(error_payload) == TYPE_DICTIONARY:
			error_message = str(error_payload.get("message", "remote_error"))
		else:
			error_message = str(error_payload)
		return _maybe_fallback(event_def, error_message)

	var choice: Dictionary = _extract_first_choice(parsed_dict)
	if choice.is_empty():
		return _maybe_fallback(event_def, "missing_choice")
	var finish_reason: String = str(choice.get("finish_reason", ""))
	if finish_reason == "content_filter":
		return _maybe_fallback(event_def, "content_filter")
	var message: Dictionary = choice.get("message", {})
	var content: String = str(message.get("content", "")).strip_edges()
	if content.is_empty():
		return _maybe_fallback(event_def, "empty_message_content")

	var candidate_raw: Variant = JSON.parse_string(content)
	if typeof(candidate_raw) != TYPE_DICTIONARY:
		return _maybe_fallback(event_def, "candidate_not_json")

	var candidate_validation: Dictionary = _validate_candidate(candidate_raw, event_def)
	if not bool(candidate_validation.get("ok", false)):
		return _maybe_fallback(event_def, str(candidate_validation.get("reason", "schema_validation_failed")))

	var candidate := _normalize_candidate(event_def, candidate_raw)
	success_count += 1
	last_request_status = "success"
	last_failure_reason = ""
	_log_request({
		"request_id": request_id,
		"mode": mode,
		"provider": "deepseek",
		"url": request_url,
		"model": str(settings.get("model", "")),
		"result": "success",
		"response_code": response_code,
		"event_id": str(event_def.get("event_id", "")),
		"fallback": false,
		"request": _truncate_text(JSON.stringify(request_payload), 900),
		"response": _truncate_text(response_text, 900),
		"response_headers": response_headers
	})
	return {
		"source_type": "ai",
		"candidate": candidate,
		"raw_response": parsed_dict,
		"fallback_used": false,
		"reason": "",
		"response_code": response_code
	}


func _fallback_result(event_def: Dictionary, reason: String) -> Dictionary:
	fallback_count += 1
	var normalized_reason := classify_failure_reason(reason)
	last_failure_reason = normalized_reason
	last_request_status = "fallback_used"
	var fallback_def: Dictionary = event_def
	var fallback_event_id: String = str(event_def.get("fallback_event_id", ""))
	if not fallback_event_id.is_empty() and DataRepository.events_by_id.has(fallback_event_id):
		fallback_def = DataRepository.get_event_def(fallback_event_id)
	last_fallback_event_id = str(fallback_def.get("event_id", fallback_event_id))
	var candidate := _build_default_candidate(fallback_def, event_def)
	_log_request({
		"request_id": _next_request_id(),
		"mode": _mode_name(),
		"provider": "local_fallback",
		"url": "%s%s" % [_normalized_base_url(str(settings.get("base_url", ""))), CHAT_COMPLETIONS_PATH],
		"model": str(settings.get("model", "")),
		"result": "fallback",
		"reason": normalized_reason,
		"raw_reason": reason,
		"event_id": str(event_def.get("event_id", "")),
		"fallback_event_id": last_fallback_event_id,
		"fallback": true
	})
	return {
		"source_type": "local",
		"candidate": candidate,
		"raw_response": candidate.duplicate(true),
		"fallback_used": true,
		"reason": reason,
		"failure_reason": normalized_reason,
		"fallback_event_id": last_fallback_event_id
	}


func _maybe_fallback(event_def: Dictionary, reason: String) -> Dictionary:
	blocked_count += 1
	return _fallback_result(event_def, reason)


func _build_request_payload(state_snapshot: Dictionary, event_def: Dictionary) -> Dictionary:
	return {
		"model": str(settings.get("model", "")),
		"temperature": 0.3,
		"max_tokens": 512,
		"stream": false,
		"thinking": {"type": "disabled"},
		"response_format": RESPONSE_FORMAT.duplicate(true),
		"messages": [
			{
				"role": "system",
				"content": _build_system_prompt()
			},
			{
				"role": "user",
				"content": JSON.stringify(_build_prompt_input(state_snapshot, event_def))
			}
		]
	}


func _build_system_prompt() -> String:
	return """You are a safe JSON generator for a community event system.
Return valid json only. No markdown, no code fence, no extra text.
The json must contain:
{
  "title": "string",
  "announcement_text": "string",
  "problem_stub": "card_id",
  "target_resident_ids": ["resident_id"],
  "manpower_required": 1,
  "reward": {"trust": 1},
  "penalty": {"trust": 1, "satisfaction_delta": 1}
}
"""


func _build_prompt_input(state_snapshot: Dictionary, event_def: Dictionary) -> Dictionary:
	return {
		"day_count": int(state_snapshot.get("day_count", 1)),
		"trust": int(state_snapshot.get("trust", 0)),
		"resident_states": state_snapshot.get("resident_states", []),
		"event_seed": event_def.duplicate(true)
	}


func _build_default_candidate(primary_def: Dictionary, source_def: Dictionary) -> Dictionary:
	var candidate := {
		"title": str(primary_def.get("title", source_def.get("title", ""))),
		"announcement_text": str(primary_def.get("announcement_text", source_def.get("announcement_text", ""))),
		"problem_stub": str(primary_def.get("problem_card_id", source_def.get("problem_card_id", ""))),
		"target_resident_ids": _duplicate_array(primary_def.get("target_resident_ids", source_def.get("target_resident_ids", []))),
		"manpower_required": int(primary_def.get("manpower_required", source_def.get("manpower_required", 0))),
		"reward": _duplicate_dictionary(primary_def.get("reward", source_def.get("reward", {}))),
		"penalty": _duplicate_dictionary(primary_def.get("penalty", source_def.get("penalty", {})))
	}
	return candidate


func _normalize_candidate(event_def: Dictionary, raw_candidate: Dictionary) -> Dictionary:
	var candidate := _build_default_candidate(event_def, event_def)
	if raw_candidate.has("title"):
		candidate["title"] = str(raw_candidate.get("title", candidate["title"]))
	if raw_candidate.has("announcement_text"):
		candidate["announcement_text"] = str(raw_candidate.get("announcement_text", candidate["announcement_text"]))
	if raw_candidate.has("problem_stub"):
		candidate["problem_stub"] = str(raw_candidate.get("problem_stub", candidate["problem_stub"]))
	if raw_candidate.has("target_resident_ids"):
		candidate["target_resident_ids"] = _filter_resident_ids(raw_candidate.get("target_resident_ids", []))
	if raw_candidate.has("manpower_required"):
		candidate["manpower_required"] = maxi(int(raw_candidate.get("manpower_required", candidate["manpower_required"])), 0)
	if raw_candidate.has("reward") and typeof(raw_candidate.get("reward", {})) == TYPE_DICTIONARY:
		candidate["reward"] = _sanitize_resource_bundle(raw_candidate.get("reward", {}), false)
	if raw_candidate.has("penalty") and typeof(raw_candidate.get("penalty", {})) == TYPE_DICTIONARY:
		candidate["penalty"] = _sanitize_penalty_bundle(raw_candidate.get("penalty", {}))
	return candidate


func _validate_candidate(candidate: Dictionary, event_def: Dictionary) -> Dictionary:
	var required_keys := ["title", "announcement_text", "problem_stub", "target_resident_ids", "manpower_required", "reward", "penalty"]
	for key: String in required_keys:
		if not candidate.has(key):
			return {"ok": false, "reason": "missing_%s" % key}
	if typeof(candidate.get("title", "")) != TYPE_STRING or str(candidate.get("title", "")).strip_edges().is_empty():
		return {"ok": false, "reason": "invalid_title"}
	if typeof(candidate.get("announcement_text", "")) != TYPE_STRING:
		return {"ok": false, "reason": "invalid_announcement_text"}
	if typeof(candidate.get("problem_stub", "")) != TYPE_STRING or not DataRepository.cards_by_id.has(str(candidate.get("problem_stub", ""))):
		return {"ok": false, "reason": "missing_problem_card"}
	if typeof(candidate.get("target_resident_ids", [])) != TYPE_ARRAY:
		return {"ok": false, "reason": "target_resident_ids_not_array"}
	if int(candidate.get("manpower_required", -1)) < 0:
		return {"ok": false, "reason": "invalid_manpower_required"}
	if typeof(candidate.get("reward", {})) != TYPE_DICTIONARY or typeof(candidate.get("penalty", {})) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "reward_or_penalty_not_dictionary"}
	var reward_validation := _validate_resource_bundle(candidate.get("reward", {}), false)
	if not bool(reward_validation.get("ok", false)):
		return reward_validation
	var penalty_validation := _validate_penalty_bundle(candidate.get("penalty", {}))
	if not bool(penalty_validation.get("ok", false)):
		return penalty_validation
	var filtered_ids := _filter_resident_ids(candidate.get("target_resident_ids", []))
	if filtered_ids.is_empty():
		return {"ok": false, "reason": "missing_valid_target_resident_ids"}
	if str(event_def.get("fallback_event_id", "")).is_empty() and str(candidate.get("problem_stub", "")).is_empty():
		return {"ok": false, "reason": "missing_problem_stub"}
	return {"ok": true}


func _validate_resource_bundle(bundle: Dictionary, allow_satisfaction_delta: bool) -> Dictionary:
	for key_variant in bundle.keys():
		var key: String = str(key_variant)
		if key == "satisfaction_delta" and allow_satisfaction_delta:
			continue
		if not _is_valid_resource_key(key, false):
			return {"ok": false, "reason": "invalid_resource_key_%s" % key}
	return {"ok": true}


func _validate_penalty_bundle(bundle: Dictionary) -> Dictionary:
	return _validate_resource_bundle(bundle, true)


func _sanitize_resource_bundle(bundle: Dictionary, allow_satisfaction_delta: bool) -> Dictionary:
	var sanitized := {}
	for key_variant in bundle.keys():
		var key: String = str(key_variant)
		if key == "satisfaction_delta" and allow_satisfaction_delta:
			sanitized[key] = int(bundle.get(key_variant, 0))
			continue
		if _is_valid_resource_key(key, false):
			sanitized[key] = int(bundle.get(key_variant, 0))
	return sanitized


func _sanitize_penalty_bundle(bundle: Dictionary) -> Dictionary:
	return _sanitize_resource_bundle(bundle, true)


func _filter_resident_ids(resident_ids: Array) -> Array:
	var filtered: Array = []
	for resident_id_variant in resident_ids:
		var resident_id: String = str(resident_id_variant)
		if DataRepository.residents_by_id.has(resident_id):
			filtered.append(resident_id)
	return filtered


func _has_remote_config() -> bool:
	return not str(settings.get("api_key", "")).strip_edges().is_empty() and _is_valid_base_url(str(settings.get("base_url", "")))


func _should_use_local_mode(mode: String) -> bool:
	return bool(settings.get("force_local_fallback", false)) or mode == "local"


func _mode_name() -> String:
	var mode: String = str(settings.get("mode", "hybrid"))
	if mode == "local" or mode == "live" or mode == "hybrid":
		return mode
	return "hybrid"


func _normalized_base_url(base_url: String) -> String:
	return base_url.strip_edges().trim_suffix("/")


func _is_valid_base_url(base_url: String) -> bool:
	var trimmed := base_url.strip_edges()
	return trimmed.begins_with("https://") or trimmed.begins_with("http://")


func _is_valid_resource_key(resource_key: String, allow_empty: bool) -> bool:
	var valid_keys := ["flowers", "funds", "manpower", "trust"]
	if resource_key.is_empty():
		return allow_empty
	return valid_keys.has(resource_key)


func _normalize_settings() -> void:
	settings["mode"] = _mode_name()
	settings["base_url"] = _normalized_base_url(str(settings.get("base_url", "https://api.deepseek.com")))
	settings["api_key"] = str(settings.get("api_key", "")).strip_edges()
	settings["model"] = str(settings.get("model", "deepseek-v4-flash")).strip_edges()
	settings["timeout_seconds"] = maxi(int(settings.get("timeout_seconds", 15)), 5)
	settings["force_local_fallback"] = bool(settings.get("force_local_fallback", false))


func _request_error_reason(error_code: int) -> String:
	match error_code:
		ERR_UNCONFIGURED:
			return "http_unconfigured"
		ERR_BUSY:
			return "http_busy"
		ERR_INVALID_PARAMETER:
			return "http_invalid_parameter"
		ERR_CANT_CONNECT:
			return "http_cant_connect"
		_:
			return "http_request_error_%d" % error_code


func _http_result_reason(result_code: int) -> String:
	match result_code:
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "chunked_body_size_mismatch"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "cant_connect"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "cant_resolve"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "connection_error"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "tls_handshake_error"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "no_response"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "body_size_limit_exceeded"
		HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED:
			return "body_decompress_failed"
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "request_failed"
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			return "download_file_cant_open"
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "download_file_write_error"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return "redirect_limit_reached"
		HTTPRequest.RESULT_TIMEOUT:
			return "timeout"
		_:
			return "http_result_%d" % result_code


func _extract_first_choice(response: Dictionary) -> Dictionary:
	var choices: Array = response.get("choices", [])
	if choices.is_empty():
		return {}
	var first_choice: Variant = choices[0]
	if typeof(first_choice) != TYPE_DICTIONARY:
		return {}
	return first_choice


func _duplicate_dictionary(source: Variant) -> Dictionary:
	if typeof(source) == TYPE_DICTIONARY:
		return source.duplicate(true)
	return {}


func _duplicate_array(source: Variant) -> Array:
	if typeof(source) == TYPE_ARRAY:
		return source.duplicate(true)
	return []


func _truncate_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return "%s..." % text.substr(0, max_length)


func _next_request_id() -> int:
	_request_serial += 1
	return _request_serial


func _log_request(entry: Dictionary) -> void:
	request_history.append(entry)
	if request_history.size() > 12:
		request_history.pop_front()
	emit_signal("request_logged", entry)


func _resolve_request_host() -> Node:
	if is_inside_tree():
		return self
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root
	return null


func drain_http_requests() -> void:
	for http_request in _active_http_requests.duplicate():
		if not is_instance_valid(http_request):
			_active_http_requests.erase(http_request)
			continue
		http_request.cancel_request()
		_release_http_request(http_request)

	var tree := get_tree()
	for _frame_index: int in range(8):
		if _retiring_http_requests.is_empty():
			return
		await tree.process_frame
		for http_request in _retiring_http_requests.duplicate():
			if not is_instance_valid(http_request) or not http_request.is_inside_tree():
				_retiring_http_requests.erase(http_request)
	_retiring_http_requests.clear()


func _release_http_request(http_request: HTTPRequest) -> void:
	_active_http_requests.erase(http_request)
	if not is_instance_valid(http_request):
		return
	if not _retiring_http_requests.has(http_request):
		_retiring_http_requests.append(http_request)
	if not http_request.is_queued_for_deletion():
		http_request.queue_free()
