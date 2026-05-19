from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class ConfidenceLevel(str, Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    UNKNOWN = "unknown"


@dataclass(slots=True)
class ActionResult:
    ok: bool
    source: str
    command: str
    payload: dict[str, Any] = field(default_factory=dict)
    error: str = ""
    confidence: ConfidenceLevel = ConfidenceLevel.UNKNOWN


@dataclass(slots=True)
class EditorState:
    connected: bool = False
    window_active: bool = False
    scene_open: bool = False
    scene_path: str = ""
    scene_dirty: bool = False
    editor_playing: bool = False


@dataclass(slots=True)
class RuntimeState:
    connected: bool = False
    scene_name: str = ""
    screenshot_name: str = ""


@dataclass(slots=True)
class AutomationState:
    editor: EditorState = field(default_factory=EditorState)
    runtime: RuntimeState = field(default_factory=RuntimeState)
    modal_dialog_present: bool = False
    last_error: str = ""
    confidence: ConfidenceLevel = ConfidenceLevel.UNKNOWN
