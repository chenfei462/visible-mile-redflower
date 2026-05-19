from __future__ import annotations

from .models import ActionResult, ConfidenceLevel
from .runtime_session import RuntimeSession


class RuntimeDriver:
    def __init__(self, session: RuntimeSession) -> None:
        self.session = session

    def _result(self, command: str, payload: dict) -> ActionResult:
        return ActionResult(
            ok=True,
            source="runtime",
            command=command,
            payload=payload,
            confidence=ConfidenceLevel.HIGH,
        )

    def ping(self) -> ActionResult:
        return self._result("ping", self.session.call("ping"))

    def get_state(self) -> ActionResult:
        return self._result("get_state", self.session.call("get_state"))

    def screenshot(self, name: str) -> ActionResult:
        return self._result("screenshot", self.session.call("screenshot", {"name": name}))

    def start_error_capture(self) -> ActionResult:
        return self._result("start_error_capture", self.session.call("start_error_capture"))

    def get_captured_errors(self) -> ActionResult:
        return self._result("get_captured_errors", self.session.call("get_captured_errors"))

    def assert_performance(self, *, min_fps: int, max_frame_ms: float | None = None) -> ActionResult:
        params = {"min_fps": min_fps}
        if max_frame_ms is not None:
            params["max_frame_ms"] = max_frame_ms
        return self._result("assert_performance", self.session.call("assert_performance", params))
