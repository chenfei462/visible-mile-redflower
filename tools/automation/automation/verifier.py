from __future__ import annotations

from .models import ActionResult, ConfidenceLevel


class Verifier:
    def is_acceptable(self, result: ActionResult) -> bool:
        if not result.ok:
            return False
        return result.confidence in {ConfidenceLevel.HIGH, ConfidenceLevel.MEDIUM}

    def require(self, result: ActionResult) -> ActionResult:
        if not self.is_acceptable(result):
            raise RuntimeError(
                f"automation step failed: command={result.command} source={result.source} "
                f"confidence={result.confidence.value} error={result.error}"
            )
        return result
