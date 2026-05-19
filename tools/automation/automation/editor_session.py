from __future__ import annotations

import socket
from typing import Any, Callable

from .transport import JsonLineClient


class EditorSession:
    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 9600,
        timeout_seconds: float = 5.0,
        socket_factory: Callable[..., socket.socket] | None = None,
    ) -> None:
        self.client = JsonLineClient(
            host=host,
            port=port,
            timeout_seconds=timeout_seconds,
            socket_factory=socket_factory,
        )

    def connect(self) -> None:
        self.client.connect()

    def close(self) -> None:
        self.client.close()

    def command(self, name: str, **payload: Any) -> dict[str, Any]:
        return self.client.send({"cmd": name, **payload})
