from __future__ import annotations

from typing import Any

from .editor_session import EditorSession
from .models import ActionResult, ConfidenceLevel, EditorState


class EditorSemanticDriver:
    def __init__(self, session: EditorSession) -> None:
        self.session = session

    def get_editor_state(self) -> EditorState:
        reply = self.session.command("get_editor_state")
        return EditorState(
            connected=bool(reply.get("ok", False)),
            window_active=bool(reply.get("window_active", False)),
            scene_open=bool(reply.get("has_scene", False)),
            scene_path=self._string_or_empty(reply.get("scene_path", "")),
            scene_dirty=bool(reply.get("scene_dirty", False)),
            editor_playing=bool(reply.get("is_playing", False)),
        )

    def open_scene(self, scene_path: str) -> ActionResult:
        return self._command_result("open_scene", path=scene_path)

    def get_scene_tree(self) -> ActionResult:
        return self._command_result("get_scene_tree")

    def create_node(self, parent_path: str, type_name: str, node_name: str) -> ActionResult:
        return self._command_result(
            "create_node",
            parent_path=parent_path,
            type=type_name,
            name=node_name,
        )

    def modify_node(self, node_path: str, properties: dict[str, Any]) -> ActionResult:
        return self._command_result("modify_node", node_path=node_path, properties=properties)

    def delete_node(self, node_path: str) -> ActionResult:
        return self._command_result("delete_node", node_path=node_path)

    def save_scene(self) -> ActionResult:
        return self._command_result("save_scene")

    def run_project(self) -> ActionResult:
        return self._command_result("run_project")

    def stop_project(self) -> ActionResult:
        return self._command_result("stop_project")

    def get_output(self) -> ActionResult:
        return self._command_result("get_output")

    def _command_result(self, command_name: str, **payload: Any) -> ActionResult:
        reply = self.session.command(command_name, **payload)
        ok = bool(reply.get("ok", False))
        return ActionResult(
            ok=ok,
            source="semantic",
            command=command_name,
            payload=reply,
            error=self._string_or_empty(reply.get("error", "")),
            confidence=ConfidenceLevel.HIGH if ok else ConfidenceLevel.LOW,
        )

    @staticmethod
    def _string_or_empty(value: Any) -> str:
        return "" if value is None else str(value)
