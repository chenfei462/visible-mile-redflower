from tools.automation.automation.gui_driver import GuiDriver
from tools.automation.automation.models import ActionResult, ConfidenceLevel
from tools.automation.automation.verifier import Verifier


class FakeBackend:
    def __init__(self) -> None:
        self.activated = False
        self.screenshots: list[str] = []

    def activate_editor_window(self) -> bool:
        self.activated = True
        return True

    def capture_editor_window(self, output_path: str) -> str:
        self.screenshots.append(output_path)
        return output_path

    def dismiss_known_dialog(self) -> bool:
        return False


def test_gui_driver_activates_editor_window() -> None:
    backend = FakeBackend()
    driver = GuiDriver(backend)

    result = driver.activate_editor_window()

    assert result.ok is True
    assert backend.activated is True


def test_verifier_rejects_low_confidence_results() -> None:
    verifier = Verifier()
    result = ActionResult(ok=True, source="gui", command="capture", confidence=ConfidenceLevel.LOW)

    assert verifier.is_acceptable(result) is False
