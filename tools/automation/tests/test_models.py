from tools.automation.automation.models import ActionResult, AutomationState, ConfidenceLevel


def test_action_result_uses_independent_payload_dicts() -> None:
    first = ActionResult(ok=True, source="semantic", command="open_scene")
    second = ActionResult(ok=True, source="semantic", command="open_scene")

    first.payload["scene"] = "res://scenes/Main.tscn"

    assert second.payload == {}


def test_automation_state_defaults_to_unknown_confidence() -> None:
    state = AutomationState()

    assert state.confidence is ConfidenceLevel.UNKNOWN
    assert state.editor.connected is False
    assert state.runtime.connected is False
