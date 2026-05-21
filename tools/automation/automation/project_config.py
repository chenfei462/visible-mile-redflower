from __future__ import annotations

import configparser
from dataclasses import dataclass
from pathlib import Path

DEFAULT_EDITOR_HOST = "127.0.0.1"
DEFAULT_RUNTIME_HOST = "127.0.0.1"
DEFAULT_EDITOR_PORT = 9500
DEFAULT_GAME_PORT = 9601
DEFAULT_RUNTIME_PORT = 9876


@dataclass(frozen=True, slots=True)
class PortConfig:
    editor_port: int = DEFAULT_EDITOR_PORT
    game_port: int = DEFAULT_GAME_PORT
    runtime_port: int = DEFAULT_RUNTIME_PORT


@dataclass(frozen=True, slots=True)
class AutomationConfig:
    project_root: Path
    scene: str
    editor_host: str = DEFAULT_EDITOR_HOST
    editor_port: int = DEFAULT_EDITOR_PORT
    runtime_host: str = DEFAULT_RUNTIME_HOST
    runtime_port: int = DEFAULT_RUNTIME_PORT

    @classmethod
    def from_values(
        cls,
        *,
        project: str | Path | None,
        scene: str,
        editor_host: str = DEFAULT_EDITOR_HOST,
        editor_port: int | None = None,
        runtime_host: str = DEFAULT_RUNTIME_HOST,
        runtime_port: int | None = None,
        cwd: str | Path | None = None,
    ) -> "AutomationConfig":
        project_root = Path(project).expanduser().resolve() if project is not None else find_project_root(cwd)
        if not (project_root / "project.godot").is_file():
            raise FileNotFoundError(f"Godot project file not found: {project_root / 'project.godot'}")

        ports = load_ports(project_root)
        return cls(
            project_root=project_root,
            scene=scene,
            editor_host=editor_host,
            editor_port=editor_port if editor_port is not None else ports.editor_port,
            runtime_host=runtime_host,
            runtime_port=runtime_port if runtime_port is not None else ports.runtime_port,
        )


def find_project_root(start: str | Path | None = None) -> Path:
    current = Path(start or Path.cwd()).expanduser().resolve()
    if current.is_file():
        current = current.parent

    for candidate in [current, *current.parents]:
        if (candidate / "project.godot").is_file():
            return candidate

    raise FileNotFoundError(f"Could not find project.godot from {current}")


def load_ports(project_root: str | Path) -> PortConfig:
    config_path = Path(project_root) / "mcp_ports.cfg"
    if not config_path.is_file():
        return PortConfig()

    parser = configparser.ConfigParser()
    parser.read(config_path, encoding="utf-8")
    section = parser["mcp"] if parser.has_section("mcp") else {}
    return PortConfig(
        editor_port=_read_int(section, "editor_port", DEFAULT_EDITOR_PORT),
        game_port=_read_int(section, "game_port", DEFAULT_GAME_PORT),
        runtime_port=_read_int(section, "playtest_port", DEFAULT_RUNTIME_PORT),
    )


def resolve_res_path(resource_path: str, *, project_root: str | Path) -> Path:
    if not resource_path.startswith("res://"):
        raise ValueError(f"expected a res:// path, got {resource_path!r}")

    root = Path(project_root).expanduser().resolve()
    relative = resource_path.removeprefix("res://")
    candidate = root.joinpath(*relative.split("/")).resolve()
    if candidate != root and root not in candidate.parents:
        raise ValueError(f"resolved resource path must stay inside project: {resource_path!r}")
    return candidate


def _read_int(section, key: str, default: int) -> int:
    try:
        value = section.get(key, fallback=None)
    except TypeError:
        value = section.get(key)
    if value in (None, ""):
        return default
    return int(value)
