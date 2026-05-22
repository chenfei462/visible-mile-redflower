extends Node

const DEFAULT_PORT := 9501

var port := DEFAULT_PORT
var tcp_server: TCPServer
var clients: Array[StreamPeerTCP] = []
var pending_screenshot_client: StreamPeerTCP = null
var _deferred_release: Vector2 = Vector2.ZERO
var _drag_points: Array[Vector2] = []
var _drag_step_index := 0
var _drag_pressed := false
var _drag_max_frame_ms := 0.0
var _drag_frame_count := 0
var _last_drag_summary := {
	"ok": false,
	"message": "no drag has run yet",
	"max_frame_ms": 0.0,
	"frame_count": 0
}


func _ready() -> void:
	if OS.get_environment("RFT_DISABLE_AUTOMATION_SERVERS") == "1":
		set_process(false)
		return
	var config := ConfigFile.new()
	if config.load("res://mcp_ports.cfg") == OK:
		port = config.get_value("mcp", "game_port", DEFAULT_PORT)
	tcp_server = TCPServer.new()
	var err := tcp_server.listen(port, "127.0.0.1")
	if err != OK:
		push_error("MCP Bridge Game: Failed to listen on port %d (error %d)" % [port, err])
	else:
		print("MCP Bridge Game: Listening on 127.0.0.1:%d" % port)
	RenderingServer.frame_post_draw.connect(_on_frame_post_draw)


func _exit_tree() -> void:
	for client in clients:
		client.disconnect_from_host()
	clients.clear()
	if tcp_server:
		tcp_server.stop()


func _process(delta: float) -> void:
	_process_deferred_drag(delta)
	if not tcp_server or not tcp_server.is_listening():
		return

	# Accept new connections
	while tcp_server.is_connection_available():
		var peer := tcp_server.take_connection()
		if peer:
			clients.append(peer)

	# Process existing clients
	var to_remove: Array[int] = []
	for i in range(clients.size()):
		var client := clients[i]
		client.poll()
		var status := client.get_status()

		if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
			to_remove.append(i)
			continue

		if status != StreamPeerTCP.STATUS_CONNECTED:
			continue

		if client.get_available_bytes() > 0:
			var data := client.get_utf8_string(client.get_available_bytes())
			if data.length() > 0:
				_handle_request(client, data)

	# Remove disconnected clients (reverse order)
	for i in range(to_remove.size() - 1, -1, -1):
		clients.remove_at(to_remove[i])


func _handle_request(client: StreamPeerTCP, data: String) -> void:
	var json := JSON.new()
	var err := json.parse(data)
	if err != OK:
		_send_response(client, {"error": "Invalid JSON: %s" % json.get_error_message()})
		return

	var request: Dictionary = json.data
	var cmd: String = request.get("cmd", "")

	match cmd:
		"screenshot":
			# Defer to frame_post_draw for correct viewport capture
			pending_screenshot_client = client
			# Force a frame draw in case low_processor_mode is active
			RenderingServer.force_draw()
		"get_runtime_tree":
			_send_response(client, _cmd_get_runtime_tree())
		"click":
			var x: float = request.get("x", 0.0)
			var y: float = request.get("y", 0.0)
			_send_response(client, _cmd_click(x, y))
		"drag":
			var start_x: float = request.get("start_x", 0.0)
			var start_y: float = request.get("start_y", 0.0)
			var end_x: float = request.get("end_x", 0.0)
			var end_y: float = request.get("end_y", 0.0)
			var steps: int = int(request.get("steps", 24))
			_send_response(client, _cmd_drag(Vector2(start_x, start_y), Vector2(end_x, end_y), steps))
		"get_last_drag_summary":
			_send_response(client, _last_drag_summary)
		_:
			_send_response(client, {"error": "Unknown command: %s" % cmd})


func _on_frame_post_draw() -> void:
	if pending_screenshot_client == null:
		return

	var client := pending_screenshot_client
	pending_screenshot_client = null

	var image := get_viewport().get_texture().get_image()
	if not image:
		_send_response(client, {"error": "Failed to capture viewport"})
		return

	var png_bytes := image.save_png_to_buffer()
	var b64 := Marshalls.raw_to_base64(png_bytes)
	_send_response(client, {"ok": true, "image_base64": b64})


func _cmd_click(x: float, y: float) -> Dictionary:
	# Simulate mouse press
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = Vector2(x, y)
	press.global_position = Vector2(x, y)
	press.pressed = true
	get_viewport().push_input(press)
	# Defer the release to next frame so the UI processes the press first
	_deferred_release = Vector2(x, y)
	call_deferred("_send_mouse_release")
	return {"ok": true, "x": x, "y": y}


func _send_mouse_release() -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = _deferred_release
	release.global_position = _deferred_release
	release.pressed = false
	get_viewport().push_input(release)


func _cmd_drag(start_position: Vector2, end_position: Vector2, steps: int = 24) -> Dictionary:
	var safe_steps := clampi(steps, 2, 120)
	_drag_points.clear()
	for index in range(safe_steps + 1):
		var t := float(index) / float(safe_steps)
		_drag_points.append(start_position.lerp(end_position, t))
	_drag_step_index = 0
	_drag_pressed = false
	_drag_max_frame_ms = 0.0
	_drag_frame_count = 0
	_last_drag_summary = {
		"ok": false,
		"message": "drag running",
		"max_frame_ms": 0.0,
		"frame_count": 0,
		"start": [start_position.x, start_position.y],
		"end": [end_position.x, end_position.y]
	}
	return {"ok": true, "steps": safe_steps, "start": [start_position.x, start_position.y], "end": [end_position.x, end_position.y]}


func _process_deferred_drag(delta: float) -> void:
	if _drag_points.is_empty():
		return
	_drag_frame_count += 1
	_drag_max_frame_ms = maxf(_drag_max_frame_ms, delta * 1000.0)
	if not _drag_pressed:
		var start := _drag_points[0]
		_push_mouse_motion(start)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.position = start
		press.global_position = start
		press.pressed = true
		get_viewport().push_input(press)
		_drag_pressed = true
		_drag_step_index = 1
		return
	if _drag_step_index < _drag_points.size():
		_push_mouse_motion(_drag_points[_drag_step_index])
		_drag_step_index += 1
		return
	var end: Vector2 = _drag_points[_drag_points.size() - 1]
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = end
	release.global_position = end
	release.pressed = false
	get_viewport().push_input(release)
	_last_drag_summary = {
		"ok": true,
		"message": "drag completed",
		"max_frame_ms": _drag_max_frame_ms,
		"frame_count": _drag_frame_count,
		"start": [_drag_points[0].x, _drag_points[0].y],
		"end": [end.x, end.y]
	}
	_drag_points.clear()
	_drag_step_index = 0
	_drag_pressed = false


func _push_mouse_motion(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_viewport().push_input(motion)


func _cmd_get_runtime_tree() -> Dictionary:
	return {"ok": true, "tree": _serialize_node(get_tree().root)}


func _serialize_node(node: Node) -> Dictionary:
	var result := {
		"name": node.name,
		"type": node.get_class(),
	}
	var children: Array[Dictionary] = []
	for child in node.get_children():
		children.append(_serialize_node(child))
	if children.size() > 0:
		result["children"] = children
	return result


func _send_response(client: StreamPeerTCP, response: Dictionary) -> void:
	var json_str := JSON.stringify(response)
	client.put_data((json_str + "\n").to_utf8_buffer())
