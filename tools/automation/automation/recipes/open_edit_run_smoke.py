from __future__ import annotations

import argparse
import time
from pathlib import Path

from tools.automation.automation.action_router import ActionRouter
from tools.automation.automation.editor_semantic_driver import EditorSemanticDriver
from tools.automation.automation.editor_session import EditorSession
from tools.automation.automation.models import ActionResult, ConfidenceLevel
from tools.automation.automation.project_config import AutomationConfig, find_project_root, resolve_res_path
from tools.automation.automation.runtime_driver import RuntimeDriver
from tools.automation.automation.runtime_session import RuntimeSession


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", help="Path to the target Godot project root. Defaults to the nearest parent containing project.godot.")
    parser.add_argument("--scene", default="res://scenes/Main.tscn")
    parser.add_argument("--probe-node", default="AutomationProbe")
    parser.add_argument("--screenshot-name", default="automation-smoke")
    parser.add_argument("--editor-host", default="127.0.0.1")
    parser.add_argument("--editor-port", type=int)
    parser.add_argument("--runtime-host", default="127.0.0.1")
    parser.add_argument("--runtime-port", type=int)
    args = parser.parse_args()
    config = AutomationConfig.from_values(
        project=args.project,
        scene=args.scene,
        editor_host=args.editor_host,
        editor_port=args.editor_port,
        runtime_host=args.runtime_host,
        runtime_port=args.runtime_port,
    )

    editor_session = EditorSession(
        host=config.editor_host,
        port=config.editor_port,
    )
    runtime_session = RuntimeSession(
        host=config.runtime_host,
        port=config.runtime_port,
    )
    semantic = None
    router = None
    probe_created = False
    project_running = False
    original_scene_bytes = _resolve_res_path(config.scene, project_root=config.project_root).read_bytes()

    try:
        editor_session.connect()
        semantic = EditorSemanticDriver(editor_session)
        router = ActionRouter(semantic, gui_driver=_NoOpGuiDriver())

        router.verifier.require(router.open_scene(config.scene))
        router.verifier.require(semantic.create_node(".", "Node", args.probe_node))
        probe_created = True
        router.verifier.require(semantic.modify_node(args.probe_node, {"process_mode": 0}))
        router.save_scene()
        router.run_project()
        project_running = True

        for _ in range(20):
            try:
                runtime_session.connect()
                break
            except Exception:
                time.sleep(0.5)
        else:
            raise RuntimeError(
                "failed to connect to playtest server on %s:%d"
                % (config.runtime_host, config.runtime_port)
            )

        runtime = RuntimeDriver(runtime_session)
        runtime.ping()
        runtime.start_error_capture()
        runtime.screenshot(args.screenshot_name)
        router.stop_project()
        project_running = False
        router.verifier.require(semantic.delete_node(args.probe_node))
        probe_created = False
        router.save_scene()
        _restore_scene_file(config.scene, original_scene_bytes, router, project_root=config.project_root)
        return 0
    finally:
        if router is not None and project_running:
            try:
                router.stop_project()
            except RuntimeError:
                pass
        if semantic is not None and router is not None and probe_created:
            try:
                router.verifier.require(semantic.delete_node(args.probe_node))
                router.save_scene()
            except RuntimeError:
                pass
        if router is not None:
            try:
                _restore_scene_file(config.scene, original_scene_bytes, router, project_root=config.project_root)
            except RuntimeError:
                pass
        runtime_session.close()
        editor_session.close()


def _resolve_res_path(resource_path: str, *, project_root: Path | None = None) -> Path:
    return resolve_res_path(
        resource_path,
        project_root=project_root or find_project_root(Path.cwd()),
    )


def _restore_scene_file(
    scene_path: str,
    original_bytes: bytes,
    router: ActionRouter,
    *,
    project_root: Path | None = None,
) -> None:
    scene_file = _resolve_res_path(scene_path, project_root=project_root)
    if scene_file.read_bytes() == original_bytes:
        return
    scene_file.write_bytes(original_bytes)
    router.verifier.require(router.open_scene(scene_path))


class _NoOpGuiDriver:
    def activate_editor_window(self):
        return ActionResult(
            ok=True,
            source="gui",
            command="activate_editor_window",
            confidence=ConfidenceLevel.MEDIUM,
        )


if __name__ == "__main__":
    raise SystemExit(main())
