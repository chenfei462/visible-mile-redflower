import json

import pytest

from tools.automation.automation.editor_session import EditorSession
from tools.automation.automation.transport import JsonLineClient, TransportError


class FakeSocket:
    def __init__(self, responses: list[dict] | None = None, raw_responses: list[bytes] | None = None) -> None:
        self._responses = list(raw_responses or [])
        if responses:
            self._responses.extend((json.dumps(response) + "\n").encode("utf-8") for response in responses)
        self.sent = b""
        self.closed = False

    def sendall(self, data: bytes) -> None:
        self.sent += data

    def recv(self, _size: int) -> bytes:
        if not self._responses:
            return b""
        return self._responses.pop(0)

    def close(self) -> None:
        self.closed = True


def test_json_line_client_connects_via_socket_factory_and_sends_one_json_object_per_line() -> None:
    calls: list[tuple[tuple[str, int], float]] = []
    sock = FakeSocket(responses=[{"ok": True}])

    def socket_factory(address: tuple[str, int], timeout: float) -> FakeSocket:
        calls.append((address, timeout))
        return sock

    client = JsonLineClient("127.0.0.1", 9600, 1.5, socket_factory=socket_factory)
    client.connect()

    reply = client.send({"cmd": "get_editor_state"})

    assert calls == [(("127.0.0.1", 9600), 1.5)]
    assert reply == {"ok": True}
    assert sock.sent.decode("utf-8") == '{"cmd": "get_editor_state"}\n'


def test_json_line_client_raises_if_send_is_called_before_connect() -> None:
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: FakeSocket())

    with pytest.raises(TransportError, match="not connected"):
        client.send({"cmd": "get_editor_state"})


def test_json_line_client_raises_if_the_peer_returns_an_empty_response() -> None:
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: FakeSocket())
    client.connect()

    with pytest.raises(TransportError, match="empty response"):
        client.send({"cmd": "get_editor_state"})


def test_editor_session_wraps_bridge_commands() -> None:
    sock = FakeSocket(responses=[{"ok": True, "scene_path": "res://scenes/Main.tscn"}])
    session = EditorSession(host="127.0.0.1", port=9600, socket_factory=lambda *_args, **_kwargs: sock)
    session.connect()

    reply = session.command("open_scene", path="res://scenes/Main.tscn")

    assert reply["scene_path"] == "res://scenes/Main.tscn"
    assert sock.sent.decode("utf-8") == '{"cmd": "open_scene", "path": "res://scenes/Main.tscn"}\n'


def test_editor_session_close_closes_the_underlying_transport() -> None:
    sock = FakeSocket(responses=[{"ok": True}])
    session = EditorSession(host="127.0.0.1", port=9600, socket_factory=lambda *_args, **_kwargs: sock)
    session.connect()

    session.close()

    assert sock.closed is True
