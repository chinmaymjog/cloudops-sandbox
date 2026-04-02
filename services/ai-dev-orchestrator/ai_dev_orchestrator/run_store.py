from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


def utc_now() -> str:
    return datetime.now(UTC).isoformat()


@dataclass(frozen=True)
class RunRecord:
    run_id: str
    issue_key: str
    repo: str
    clone_url: str
    branch: str
    status: str
    workspace_dir: str
    created_at: str
    updated_at: str
    summary: str
    description: str
    error: str | None = None


class RunStore:
    def __init__(self, workspace_root: Path) -> None:
        self._workspace_root = workspace_root
        self._runs_root = workspace_root / "runs"

    @property
    def workspace_root(self) -> Path:
        return self._workspace_root

    def ensure_base_dirs(self) -> None:
        self._runs_root.mkdir(parents=True, exist_ok=True)

    def run_dir(self, run_id: str) -> Path:
        return self._runs_root / run_id

    def init_run(
        self,
        *,
        run_id: str,
        issue_key: str,
        repo: str,
        clone_url: str,
        branch: str,
        summary: str,
        description: str,
    ) -> RunRecord:
        self.ensure_base_dirs()
        run_dir = self.run_dir(run_id)
        run_dir.mkdir(parents=True, exist_ok=False)
        record = RunRecord(
            run_id=run_id,
            issue_key=issue_key,
            repo=repo,
            clone_url=clone_url,
            branch=branch,
            status="accepted",
            workspace_dir=str(run_dir),
            created_at=utc_now(),
            updated_at=utc_now(),
            summary=summary,
            description=description,
        )
        self.write_record(record)
        return record

    def write_record(self, record: RunRecord) -> None:
        run_dir = Path(record.workspace_dir)
        run_dir.mkdir(parents=True, exist_ok=True)
        (run_dir / "run.json").write_text(
            json.dumps(asdict(record), indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    def update_status(self, record: RunRecord, status: str, error: str | None = None) -> RunRecord:
        updated = RunRecord(
            **{
                **asdict(record),
                "status": status,
                "updated_at": utc_now(),
                "error": error,
            }
        )
        self.write_record(updated)
        return updated

    def write_step_output(self, record: RunRecord, filename: str, data: dict[str, Any]) -> None:
        target = Path(record.workspace_dir) / filename
        target.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
