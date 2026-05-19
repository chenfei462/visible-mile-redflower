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

    def connect(self) -> None:
        if self._socket is None:
            self._socket = self.socket_factory((self.host, self.port), self.timeout_seconds)

    def close(self) -> None:
        if self._socket is not None:
            self._socket.close()
            self._socket = None

    def send(self, payload: dict[str, Any]) -> dict[str, Any]:
        if self._socket is None:
            raise TransportError("transport is not connected")

        wire = json.dumps(payload) + "\n"
        self._socket.sendall(wire.encode("utf-8"))

        raw = self._socket.recv(65536)
        if not raw:
            raise TransportError("empty response from peer")

        return json.loads(raw.decode("utf-8").strip())
