extends SceneTree

const LICENSES_PLUGIN_CFG := "res://addons/licenses/plugin.cfg"
const LICENSES_DATA := "res://licenses.json"
const REQUIRED_COMPONENT_IDS := [
	"godot_engine",
	"license_manager",
	"godot_doctor",
	"godot_ai_playtest",
	"mcp_bridge",
]

func _initialize() -> void:
	var failures: Array[String] = []
	_check_file_exists(LICENSES_PLUGIN_CFG, failures)
	_check_file_exists(LICENSES_DATA, failures)
	_check_plugin_enabled(failures)
	_check_project_settings(failures)
	_check_plugin_cfg(failures)
	_check_license_data(failures)

	if failures.is_empty():
		print("LICENSE MANAGER SMOKE PASSED")
		quit(0)
		return

	push_error("LICENSE MANAGER SMOKE FAILED")
	for failure: String in failures:
		push_error("- " + failure)
	quit(1)

func _check_file_exists(path: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing file: " + path)

func _check_plugin_enabled(failures: Array[String]) -> void:
	var enabled: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	if not enabled.has(LICENSES_PLUGIN_CFG):
		failures.append("License Manager is not enabled in editor_plugins/enabled")

func _check_project_settings(failures: Array[String]) -> void:
	var data_file: String = ProjectSettings.get_setting("plugins/licenses/data_file", "")
	if data_file != LICENSES_DATA:
		failures.append("plugins/licenses/data_file should be %s but was %s" % [LICENSES_DATA, data_file])

func _check_plugin_cfg(failures: Array[String]) -> void:
	if not FileAccess.file_exists(LICENSES_PLUGIN_CFG):
		return
	var cfg := ConfigFile.new()
	var err := cfg.load(LICENSES_PLUGIN_CFG)
	if err != OK:
		failures.append("Could not load License Manager plugin.cfg: " + error_string(err))
		return
	if cfg.get_value("plugin", "name", "") != "License Manager":
		failures.append("plugin.cfg name should be License Manager")
	if cfg.get_value("plugin", "version", "") != "1.11.0":
		failures.append("plugin.cfg version should be 1.11.0")
	if cfg.get_value("plugin.dependencies", "godot", "") != ">=4.4":
		failures.append("plugin.cfg Godot dependency should be >=4.4")

func _check_license_data(failures: Array[String]) -> void:
	if not FileAccess.file_exists(LICENSES_DATA):
		return
	var file := FileAccess.open(LICENSES_DATA, FileAccess.READ)
	if file == null:
		failures.append("Could not open licenses.json: " + error_string(FileAccess.get_open_error()))
		return
	var parser := JSON.new()
	var err := parser.parse(file.get_as_text())
	if err != OK:
		failures.append("Could not parse licenses.json: " + parser.get_error_message())
		return
	var data: Variant = parser.data
	if typeof(data) != TYPE_DICTIONARY or not data.has("components"):
		failures.append("licenses.json must contain a components array")
		return
	var components: Array = data["components"]
	if components.size() < REQUIRED_COMPONENT_IDS.size():
		failures.append("licenses.json should contain initial third-party component entries")
	var seen := {}
	for component: Variant in components:
		if typeof(component) != TYPE_DICTIONARY:
			failures.append("Every component entry must be a dictionary")
			continue
		var id: String = component.get("id", "")
		seen[id] = true
		_check_component(component, failures)
	for id: String in REQUIRED_COMPONENT_IDS:
		if not seen.has(id):
			failures.append("licenses.json missing component id: " + id)

func _check_component(component: Dictionary, failures: Array[String]) -> void:
	var id: String = component.get("id", "<missing id>")
	for key: String in ["category", "name", "copyright", "licenses"]:
		if not component.has(key):
			failures.append("Component %s missing key: %s" % [id, key])
	if component.get("name", "") == "":
		failures.append("Component %s has no name" % id)
	var licenses: Array = component.get("licenses", [])
	if licenses.is_empty():
		failures.append("Component %s has no license entries" % id)
	for index: int in range(licenses.size()):
		var license_entry: Variant = licenses[index]
		if typeof(license_entry) != TYPE_DICTIONARY:
			failures.append("Component %s license %d is not a dictionary" % [id, index])
			continue
		if license_entry.get("name", "") == "":
			failures.append("Component %s license %d has no name" % [id, index])
		var license_file: String = license_entry.get("file", "")
		var license_text: String = license_entry.get("text", "")
		if license_file == "" and license_text == "":
			failures.append("Component %s license %d must have file or text" % [id, index])
		if license_file != "" and not FileAccess.file_exists(license_file):
			failures.append("Component %s license file does not exist: %s" % [id, license_file])
