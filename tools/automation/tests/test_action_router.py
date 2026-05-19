from tools.automation.automation.action_router import ActionRouter
from tools.automation.automation.models import ActionResult, ConfidenceLevel


class FlakySemanticDriver:
    def __init__(self, responses: list[bool]) -> None:
        self.responses = responses
        self.calls = 0

    def open_scene(self, scene_path: str) -> ActionResult:
        ok = self.responses[self.calls]
        self.calls += 1
        return ActionResult(
            ok=ok,
            source="semantic",
            command="open_scene",
            payload={"scene_path": scene_path},
            error="" if ok else "semantic failed",
            confidence=ConfidenceLevel.HIGH if ok else ConfidenceLevel.LOW,
        )


class FakeGuiDriver:
    def __init__(self) -> None:
        self.activations = 0

    def activate_editor_window(self) -> ActionResult:
        self.activations += 1
        return ActionResult(
            ok=True,
            source="gui",
            command="activate_editor_window",
            confidence=ConfidenceLevel.MEDIUM,
        )


def test_router_prefers_semantic_results_when_they_succeed() -> None:
    router = ActionRouter(FlakySemanticDriver([True]), FakeGuiDriver())

    result = router.open_scene("res://scenes/Main.tscn")

    assert result.source == "semantic"


def test_router_uses_gui_recovery_before_retrying_semantic_action() -> None:
    semantic = FlakySemanticDriver([False, True])
    gui = FakeGuiDriver()
    router = ActionRouter(semantic, gui)

    result = router.open_scene("res://scenes/Main.tscn")

    assert gui.activations == 1
    assert semantic.calls == 2
    assert result.source == "semantic"
    assert result.ok is True
