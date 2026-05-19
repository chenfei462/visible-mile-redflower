from pathlib import Path

from tools.automation.automation.models import ActionResult, ConfidenceLevel
from tools.automation.automation.recipes.open_edit_run_smoke import _resolve_res_path, _restore_scene_file


class FakeRouter:
    def __init__(self) -> None:
        self.opened: list[str] = []
        self.verifier = self

    def open_scene(self, scene_path: str) -> ActionResult:
        self.opened.append(scene_path)
        return ActionResult(
            ok=True,
            source="semantic",
            command="open_scene",
            confidence=ConfidenceLevel.HIGH,
        )

    def require(self, result: ActionResult) -> ActionResult:
        return result


def test_resolve_res_path_maps_res_urls_to_project_files() -> None:
    project_root = Path("C:/tmp/project")

    result = _resolve_res_path("res://scenes/Main.tscn", project_root=project_root)

    assert result == project_root / "scenes" / "Main.tscn"


def test_restore_scene_file_puts_original_bytes_back_and_reopens_scene(tmp_path: Path) -> None:
    router = FakeRouter()
    scene_path = tmp_path / "scenes" / "Main.tscn"
    scene_path.parent.mkdir(parents=True)
    original_bytes = b"original scene"
    scene_path.write_bytes(b"changed scene")

    _restore_scene_file(
        "res://scenes/Main.tscn",
        original_bytes,
        router,
        project_root=tmp_path,
    )

    assert scene_path.read_bytes() == original_bytes
    assert router.opened == ["res://scenes/Main.tscn"]
