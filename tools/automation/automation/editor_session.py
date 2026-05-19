from __future__ import annotations

import socket
from typing import Any, Callable

from .transport import JsonLineClient


class EditorSession:
    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 9600,
        timeout: float = 5.0,
        socket_factory: Callable[..., socket.socket] | None = None,
    ) -> None:
        self.client = JsonLineClient(
            host=host,
            port=port,
            timeout=timeout,
            socket_factory=socket_factory,
        )

    def connect(self) -> None:
        self.client.connect()

    def close(self) -> None:
        self.client.close()

    def command(self, command_name: str, /, **payload: Any) -> dict[str, Any]:
        if "cmd" in payload:
            raise ValueError("payload contains reserved field: cmd")
        return self.client.send({"cmd": command_name, **payload})
