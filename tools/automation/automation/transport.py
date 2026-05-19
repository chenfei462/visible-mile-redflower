from __future__ import annotations

import json
import socket
from typing import Any, Callable


class TransportError(RuntimeError):
    pass


class JsonLineClient:
    def __init__(
        self,
        host: str,
        port: int,
        timeout_seconds: float = 5.0,
        socket_factory: Callable[..., socket.socket] | None = None,
    ) -> None:
        self.host = host
        self.port = port
        self.timeout_seconds = timeout_seconds
        self.socket_factory = socket_factory or socket.create_connection
        self._socket: socket.socket | None = None
        self._buffer = b""

    def connect(self) -> None:
        if self._socket is None:
            try:
                self._socket = self.socket_factory((self.host, self.port), self.timeout_seconds)
                self._buffer = b""
            except OSError as error:
                raise TransportError(f"connect failed: {error}") from error

    def close(self) -> None:
        if self._socket is not None:
            self._socket.close()
            self._socket = None
        self._buffer = b""

    def send(self, payload: dict[str, Any]) -> dict[str, Any]:
        if self._socket is None:
            raise TransportError("transport is not connected")

        wire = json.dumps(payload) + "\n"
        try:
            self._socket.sendall(wire.encode("utf-8"))
            raw = self._readline()
        except OSError as error:
            raise TransportError(f"socket error: {error}") from error

        try:
            return json.loads(raw.decode("utf-8"))
        except UnicodeDecodeError as error:
            raise TransportError(f"invalid UTF-8 response from peer: {error}") from error
        except json.JSONDecodeError as error:
            raise TransportError(f"invalid JSON response from peer: {error}") from error

    def _readline(self) -> bytes:
        while True:
            newline_index = self._buffer.find(b"\n")
            if newline_index >= 0:
                line = self._buffer[:newline_index]
                self._buffer = self._buffer[newline_index + 1 :]
                if not line:
                    raise TransportError("empty response from peer")
                return line

            assert self._socket is not None
            chunk = self._socket.recv(65536)
            if not chunk:
                if self._buffer:
                    raise TransportError("incomplete response from peer")
                raise TransportError("empty response from peer")
            self._buffer += chunk
