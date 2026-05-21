from pathlib import Path

import pytest

from tools.automation.automation.project_config import (
    AutomationConfig,
    find_project_root,
    load_ports,
    resolve_res_path,
)


def test_find_project_root_walks_up_from_nested_tools_directory(tmp_path: Path) -> None:
    project_root = tmp_path / "OtherGodotGame"
    nested = project_root / "tools" / "automation"
    nested.mkdir(parents=True)
    (project_root / "project.godot").write_text("config_version=5\n", encoding="utf-8")

    result = find_project_root(nested)

    assert result == project_root


def test_find_project_root_rejects_directories_without_project_file(tmp_path: Path) -> None:
    with pytest.raises(FileNotFoundError, match="project.godot"):
        find_project_root(tmp_path / "not-a-godot-project")


def test_load_ports_reads_target_project_mcp_ports_cfg(tmp_path: Path) -> None:
    (tmp_path / "mcp_ports.cfg").write_text(
        "[mcp]\neditor_port=17600\ngame_port=17601\nplaytest_port=19876\n",
        encoding="utf-8",
    )

    ports = load_ports(tmp_path)

    assert ports.editor_port == 17600
    assert ports.game_port == 17601
    assert ports.runtime_port == 19876


def test_load_ports_uses_bridge_defaults_when_config_is_absent(tmp_path: Path) -> None:
    ports = load_ports(tmp_path)

    assert ports.editor_port == 9500
    assert ports.game_port == 9601
    assert ports.runtime_port == 9876


def test_resolve_res_path_maps_resource_paths_inside_selected_project(tmp_path: Path) -> None:
    result = resolve_res_path("res://levels/intro/Main.tscn", project_root=tmp_path)

    assert result == tmp_path / "levels" / "intro" / "Main.tscn"


def test_resolve_res_path_rejects_paths_that_escape_the_project(tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="must stay inside"):
        resolve_res_path("res://../outside.tscn", project_root=tmp_path)


def test_automation_config_uses_project_ports_unless_cli_overrides(tmp_path: Path) -> None:
    project_root = tmp_path / "ReusableGame"
    project_root.mkdir()
    (project_root / "project.godot").write_text("config_version=5\n", encoding="utf-8")
    (project_root / "mcp_ports.cfg").write_text(
        "[mcp]\neditor_port=17600\ngame_port=17601\n",
        encoding="utf-8",
    )

    config = AutomationConfig.from_values(
        project=project_root,
        scene="res://scenes/Main.tscn",
        editor_port=19600,
    )

    assert config.project_root == project_root
    assert config.scene == "res://scenes/Main.tscn"
    assert config.editor_port == 19600
    assert config.runtime_port == 9876
