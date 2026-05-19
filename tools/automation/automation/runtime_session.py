from __future__ import annotations

from typing import Any

from .transport import JsonLineClient


class RuntimeSession:
    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 9876,
        timeout: float = 5.0,
        *,
        timeout_seconds: float | None = None,
        transport: JsonLineClient | Any | None = None,
    ) -> None:
        if timeout_seconds is not None:
            timeout = timeout_seconds
        self.transport = transport or JsonLineClient(host=host, port=port, timeout=timeout)
        self._next_id = 1

    def connect(self) -> None:
        self.transport.connect()

    def close(self) -> None:
        self.transport.close()

    def call(self, method: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
        request_id = self._next_id
        payload = {
            "jsonrpc": "2.0",
            "id": request_id,
            "method": method,
            "params": params or {},
        }
        self._next_id += 1

        reply = self.transport.send(payload)
        if reply.get("jsonrpc") != "2.0":
            raise RuntimeError("runtime response was not valid JSON-RPC 2.0")
        if reply.get("id") != request_id:
            raise RuntimeError(
                f"response id {reply.get('id')} did not match request id {request_id}"
            )
        if "error" in reply:
            error = reply["error"]
            message = error.get("message", str(error)) if isinstance(error, dict) else str(error)
            raise RuntimeError(f"runtime request failed: {message}")
        if "result" not in reply:
            raise RuntimeError("runtime response did not include a result")
        return reply["result"]
