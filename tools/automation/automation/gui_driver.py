from __future__ import annotations

from typing import Protocol

from .models import ActionResult, ConfidenceLevel


class WindowBackend(Protocol):
    def activate_editor_window(self) -> bool: ...
    def capture_editor_window(self, output_path: str) -> str: ...
    def dismiss_known_dialog(self) -> bool: ...


class GuiDriver:
    def __init__(self, backend: WindowBackend) -> None:
        self.backend = backend

    def activate_editor_window(self) -> ActionResult:
        ok = self.backend.activate_editor_window()
        return ActionResult(
            ok=ok,
            source="gui",
            command="activate_editor_window",
            confidence=ConfidenceLevel.MEDIUM if ok else ConfidenceLevel.LOW,
        )

    def capture_editor_window(self, output_path: str) -> ActionResult:
        saved_path = self.backend.capture_editor_window(output_path)
        return ActionResult(
            ok=bool(saved_path),
            source="gui",
            command="capture_editor_window",
            payload={"path": saved_path},
            confidence=ConfidenceLevel.MEDIUM if saved_path else ConfidenceLevel.LOW,
        )

    def dismiss_known_dialog(self) -> ActionResult:
        ok = self.backend.dismiss_known_dialog()
        return ActionResult(
            ok=ok,
            source="gui",
            command="dismiss_known_dialog",
            confidence=ConfidenceLevel.MEDIUM if ok else ConfidenceLevel.LOW,
        )
