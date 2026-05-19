from __future__ import annotations

from .verifier import Verifier


class ActionRouter:
    def __init__(self, semantic_driver, gui_driver, verifier: Verifier | None = None) -> None:
        self.semantic_driver = semantic_driver
        self.gui_driver = gui_driver
        self.verifier = verifier or Verifier()

    def open_scene(self, scene_path: str):
        result = self.semantic_driver.open_scene(scene_path)
        if self.verifier.is_acceptable(result):
            return result
        recovery = self.gui_driver.activate_editor_window()
        if not self.verifier.is_acceptable(recovery):
            return result
        return self.semantic_driver.open_scene(scene_path)

    def save_scene(self):
        return self.verifier.require(self.semantic_driver.save_scene())

    def run_project(self):
        return self.verifier.require(self.semantic_driver.run_project())

    def stop_project(self):
        return self.verifier.require(self.semantic_driver.stop_project())
