from __future__ import annotations

from dataclasses import dataclass, field
from threading import Lock


@dataclass
class RunRegistry:
    _active_issue_keys: set[str] = field(default_factory=set)
    _lock: Lock = field(default_factory=Lock)

    def acquire(self, issue_key: str) -> bool:
        with self._lock:
            if issue_key in self._active_issue_keys:
                return False
            self._active_issue_keys.add(issue_key)
            return True

    def release(self, issue_key: str) -> None:
        with self._lock:
            self._active_issue_keys.discard(issue_key)
