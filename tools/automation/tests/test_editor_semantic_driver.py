from tools.automation.automation.editor_semantic_driver import EditorSemanticDriver
from tools.automation.automation.models import ConfidenceLevel, EditorState


class FakeSession:
    def __init__(self, replies: dict[str, dict] | None = None) -> None:
        self.replies = replies or {}
        self.calls: list[tuple[str, dict]] = []

    def command(self, command_name: str, /, **payload):
        self.calls.append((command_name, payload))
        if command_name in self.replies:
            return self.replies[command_name]
        return {"ok": True, **payload}


def test_get_editor_state_maps_bridge_reply() -> None:
    session = FakeSession(
        {
            "get_editor_state": {
                "ok": True,
                "has_scene": True,
                "scene_path": "res://scenes/Main.tscn",
                "is_playing": False,
            }
        }
    )
    driver = EditorSemanticDriver(session)

    state = driver.get_editor_state()

    assert isinstance(state, EditorState)
    assert state.connected is True
    assert state.window_active is False
    assert state.scene_open is True
    assert state.scene_path == "res://scenes/Main.tscn"
    assert state.scene_dirty is False
    assert state.editor_playing is False


def test_open_scene_returns_high_confidence_action_result() -> None:
    session = FakeSession({"open_scene": {"ok": True, "scene_path": "res://scenes/Main.tscn"}})
    driver = EditorSemanticDriver(session)

    result = driver.open_scene("res://scenes/Main.tscn")

    assert result.ok is True
    assert result.source == "semantic"
    assert result.command == "open_scene"
    assert result.payload["scene_path"] == "res://scenes/Main.tscn"
    assert result.confidence is ConfidenceLevel.HIGH
    assert session.calls == [("open_scene", {"path": "res://scenes/Main.tscn"})]


def test_semantic_driver_forwards_bridge_commands_for_scene_mutations() -> None:
    session = FakeSession()
    driver = EditorSemanticDriver(session)

    driver.get_scene_tree()
    driver.create_node(".", "Node", "Probe")
    driver.modify_node("Probe", {"process_mode": 0})
    driver.delete_node("Probe")
    driver.save_scene()
    driver.run_project()
    driver.stop_project()
    driver.get_output()

    assert session.calls == [
        ("get_scene_tree", {}),
        ("create_node", {"parent_path": ".", "type": "Node", "name": "Probe"}),
        ("modify_node", {"node_path": "Probe", "properties": {"process_mode": 0}}),
        ("delete_node", {"node_path": "Probe"}),
        ("save_scene", {}),
        ("run_project", {}),
        ("stop_project", {}),
        ("get_output", {}),
    ]
