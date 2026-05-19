import pytest

from tools.automation.automation.models import ConfidenceLevel
from tools.automation.automation.runtime_driver import RuntimeDriver
from tools.automation.automation.runtime_session import RuntimeSession


class FakeTransport:
    def __init__(self, responses: list[dict] | None = None) -> None:
        self.responses = list(responses or [])
        self.payloads: list[dict] = []
        self.connected = False
        self.closed = False

    def connect(self) -> None:
        self.connected = True

    def close(self) -> None:
        self.closed = True

    def send(self, payload: dict) -> dict:
        self.payloads.append(payload)
        return self.responses.pop(0)


class FakeSession:
    def __init__(self, replies: dict[str, dict] | None = None) -> None:
        self.replies = replies or {}
        self.calls: list[tuple[str, dict]] = []

    def call(self, method: str, params: dict | None = None) -> dict:
        payload = params or {}
        self.calls.append((method, payload))
        return self.replies.get(method, {"method": method, **payload})


def test_runtime_session_sends_json_rpc_requests_with_incrementing_ids() -> None:
    transport = FakeTransport(
        responses=[
            {"jsonrpc": "2.0", "id": 1, "result": {"pong": True}},
            {"jsonrpc": "2.0", "id": 2, "result": {"path": "user://screenshots/smoke.png"}},
        ]
    )
    session = RuntimeSession(transport=transport)
    session.connect()

    first = session.call("ping")
    second = session.call("screenshot", {"name": "smoke"})

    assert transport.connected is True
    assert first == {"pong": True}
    assert second == {"path": "user://screenshots/smoke.png"}
    assert transport.payloads == [
        {"jsonrpc": "2.0", "id": 1, "method": "ping", "params": {}},
        {"jsonrpc": "2.0", "id": 2, "method": "screenshot", "params": {"name": "smoke"}},
    ]


def test_runtime_session_rejects_mismatched_response_ids() -> None:
    session = RuntimeSession(transport=FakeTransport(responses=[{"jsonrpc": "2.0", "id": 2, "result": {"pong": True}}]))
    session.connect()

    with pytest.raises(RuntimeError, match="response id 2 did not match request id 1"):
        session.call("ping")


def test_runtime_session_raises_server_errors() -> None:
    session = RuntimeSession(
        transport=FakeTransport(
            responses=[{"jsonrpc": "2.0", "id": 1, "error": {"code": -32603, "message": "runtime exploded"}}]
        )
    )
    session.connect()

    with pytest.raises(RuntimeError, match="runtime exploded"):
        session.call("ping")


def test_runtime_driver_wraps_phase_one_methods_as_action_results() -> None:
    session = FakeSession(
        replies={
            "ping": {"pong": True},
            "get_state": {"scene": "Main", "paused": False},
            "screenshot": {"path": "user://screenshots/smoke.png"},
            "start_error_capture": {"capturing": True},
            "get_captured_errors": {"count": 0, "errors": []},
            "assert_performance": {"success": True, "fps": 60.0},
        }
    )
    driver = RuntimeDriver(session)

    ping = driver.ping()
    state = driver.get_state()
    screenshot = driver.screenshot("smoke")
    capture = driver.start_error_capture()
    errors = driver.get_captured_errors()
    performance = driver.assert_performance(min_fps=30, max_frame_ms=20.0)

    assert ping.ok is True
    assert ping.source == "runtime"
    assert ping.command == "ping"
    assert ping.payload == {"pong": True}
    assert ping.confidence is ConfidenceLevel.HIGH
    assert state.payload == {"scene": "Main", "paused": False}
    assert screenshot.payload["path"] == "user://screenshots/smoke.png"
    assert capture.payload == {"capturing": True}
    assert errors.payload == {"count": 0, "errors": []}
    assert performance.payload == {"success": True, "fps": 60.0}
    assert performance.ok is True
    assert performance.confidence is ConfidenceLevel.HIGH
    assert session.calls == [
        ("ping", {}),
        ("get_state", {}),
        ("screenshot", {"name": "smoke"}),
        ("start_error_capture", {}),
        ("get_captured_errors", {}),
        ("assert_performance", {"min_fps": 30, "max_frame_ms": 20.0}),
    ]


def test_runtime_driver_marks_success_false_payloads_as_failures() -> None:
    driver = RuntimeDriver(
        FakeSession(
            replies={
                "assert_performance": {
                    "success": False,
                    "failures": ["fps 24.0 below minimum 30"],
                }
            }
        )
    )

    result = driver.assert_performance(min_fps=30)

    assert result.ok is False
    assert result.confidence is ConfidenceLevel.LOW
    assert result.error == "fps 24.0 below minimum 30"
