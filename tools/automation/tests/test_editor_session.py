import json

import pytest

from tools.automation.automation.editor_session import EditorSession
from tools.automation.automation.transport import JsonLineClient, TransportError


class FakeSocket:
    def __init__(
        self,
        responses: list[dict] | None = None,
        raw_responses: list[bytes] | None = None,
        send_error: OSError | None = None,
        recv_error: OSError | None = None,
    ) -> None:
        self._responses = list(raw_responses or [])
        if responses:
            self._responses.extend((json.dumps(response) + "\n").encode("utf-8") for response in responses)
        self._send_error = send_error
        self._recv_error = recv_error
        self.sent = b""
        self.closed = False

    def sendall(self, data: bytes) -> None:
        if self._send_error is not None:
            raise self._send_error
        self.sent += data

    def recv(self, _size: int) -> bytes:
        if not self._responses:
            if self._recv_error is not None:
                raise self._recv_error
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
    assert sock.sent.endswith(b"\n")
    assert json.loads(sock.sent.decode("utf-8").rstrip("\n")) == {"cmd": "get_editor_state"}


def test_json_line_client_reads_fragmented_json_frames() -> None:
    sock = FakeSocket(raw_responses=[b'{"ok": tr', b'ue}\n'])
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: sock)
    client.connect()

    reply = client.send({"cmd": "get_editor_state"})

    assert reply == {"ok": True}


def test_json_line_client_buffers_multiple_frames_from_one_read() -> None:
    sock = FakeSocket(raw_responses=[b'{"ok": true}\n{"scene_path": "res://scenes/Main.tscn"}\n'])
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: sock)
    client.connect()

    first = client.send({"cmd": "get_editor_state"})
    second = client.send({"cmd": "get_editor_state"})

    assert first == {"ok": True}
    assert second == {"scene_path": "res://scenes/Main.tscn"}


def test_json_line_client_raises_if_send_is_called_before_connect() -> None:
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: FakeSocket())

    with pytest.raises(TransportError, match="not connected"):
        client.send({"cmd": "get_editor_state"})


def test_json_line_client_raises_if_the_peer_returns_an_empty_response() -> None:
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: FakeSocket())
    client.connect()

    with pytest.raises(TransportError, match="empty response"):
        client.send({"cmd": "get_editor_state"})


def test_json_line_client_wraps_invalid_json_as_transport_error() -> None:
    sock = FakeSocket(raw_responses=[b"not json\n"])
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: sock)
    client.connect()

    with pytest.raises(TransportError, match="invalid JSON"):
        client.send({"cmd": "get_editor_state"})


def test_json_line_client_wraps_socket_errors_as_transport_error() -> None:
    sock = FakeSocket(send_error=OSError("send failed"))
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: sock)
    client.connect()

    with pytest.raises(TransportError, match="socket error"):
        client.send({"cmd": "get_editor_state"})


def test_json_line_client_wraps_recv_errors_as_transport_error() -> None:
    sock = FakeSocket(recv_error=OSError("recv failed"))
    client = JsonLineClient("127.0.0.1", 9600, socket_factory=lambda *_args, **_kwargs: sock)
    client.connect()

    with pytest.raises(TransportError, match="socket error"):
        client.send({"cmd": "get_editor_state"})


def test_json_line_client_wraps_connect_errors_as_transport_error() -> None:
    def socket_factory(*_args, **_kwargs):
        raise OSError("connect failed")

    client = JsonLineClient("127.0.0.1", 9600, socket_factory=socket_factory)

    with pytest.raises(TransportError, match="connect failed"):
        client.connect()


def test_editor_session_wraps_bridge_commands() -> None:
    sock = FakeSocket(responses=[{"ok": True, "scene_path": "res://scenes/Main.tscn"}])
    session = EditorSession(host="127.0.0.1", port=9600, socket_factory=lambda *_args, **_kwargs: sock)
    session.connect()

    reply = session.command("open_scene", path="res://scenes/Main.tscn")

    assert reply["scene_path"] == "res://scenes/Main.tscn"
    assert json.loads(sock.sent.decode("utf-8").rstrip("\n")) == {
        "cmd": "open_scene",
        "path": "res://scenes/Main.tscn",
    }


def test_editor_session_command_rejects_reserved_cmd_payload_field() -> None:
    sock = FakeSocket(responses=[{"ok": True}])
    session = EditorSession(host="127.0.0.1", port=9600, socket_factory=lambda *_args, **_kwargs: sock)
    session.connect()

    with pytest.raises(ValueError, match="reserved"):
        session.command("open_scene", cmd="unexpected", path="res://scenes/Main.tscn")


def test_editor_session_close_closes_the_underlying_transport() -> None:
    sock = FakeSocket(responses=[{"ok": True}])
    session = EditorSession(host="127.0.0.1", port=9600, socket_factory=lambda *_args, **_kwargs: sock)
    session.connect()

    session.close()

    assert sock.closed is True
