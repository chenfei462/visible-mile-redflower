from __future__ import annotations

from typing import Any

from .models import ActionResult, ConfidenceLevel
from .runtime_session import RuntimeSession


class RuntimeDriver:
    def __init__(self, session: RuntimeSession) -> None:
        self.session = session

    def _result(self, command: str, payload: dict[str, Any]) -> ActionResult:
        ok = bool(payload.get("success", True))
        return ActionResult(
            ok=ok,
            source="runtime",
            command=command,
            payload=payload,
            error="" if ok else self._failure_message(payload),
            confidence=ConfidenceLevel.HIGH if ok else ConfidenceLevel.LOW,
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

    @staticmethod
    def _failure_message(payload: dict[str, Any]) -> str:
        if isinstance(payload.get("error"), str) and payload["error"]:
            return payload["error"]
        if isinstance(payload.get("message"), str) and payload["message"]:
            return payload["message"]
        failures = payload.get("failures")
        if isinstance(failures, list) and failures:
            return "; ".join(str(item) for item in failures)
        return "runtime command returned success=false"
