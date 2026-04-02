from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass
from pathlib import Path

from fastapi import HTTPException, status

from ai_dev_orchestrator.config import RepoDefinition
from ai_dev_orchestrator.models import TaskPayload
from ai_dev_orchestrator.run_store import RunRecord, RunStore
from ai_dev_orchestrator.runtime import RunRegistry

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class ResolvedTask:
    payload: TaskPayload
    repo_definition: RepoDefinition
    branch_name: str
    run_id: str
    record: RunRecord


class OrchestratorService:
    def __init__(
        self,
        repo_registry: dict[str, RepoDefinition],
        run_registry: RunRegistry,
        run_store: RunStore,
    ) -> None:
        self._repo_registry = repo_registry
        self._run_registry = run_registry
        self._run_store = run_store

    def prepare_task(self, payload: TaskPayload) -> ResolvedTask:
        repo_definition = self._repo_registry.get(payload.repo)
        if repo_definition is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unknown repo {payload.repo!r}. Configure it in ALLOWED_REPOS_JSON.",
            )

        if not self._run_registry.acquire(payload.issue_key):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"An active run already exists for {payload.issue_key}.",
            )

        branch_name = f"feature/{payload.issue_key.lower()}"
        run_id = str(uuid.uuid4())
        try:
            record = self._run_store.init_run(
                run_id=run_id,
                issue_key=payload.issue_key,
                repo=payload.repo,
                clone_url=repo_definition.clone_url,
                branch=branch_name,
                summary=payload.summary,
                description=payload.description,
            )
        except Exception:
            self.finish_task(payload.issue_key)
            raise

        return ResolvedTask(
            payload=payload,
            repo_definition=repo_definition,
            branch_name=branch_name,
            run_id=run_id,
            record=record,
        )

    def finish_task(self, issue_key: str) -> None:
        self._run_registry.release(issue_key)

    def execute_task(self, task: ResolvedTask) -> None:
        try:
            record = self._run_store.update_status(task.record, "running")
            logger.info(
                "Accepted run %s for %s against repo %s (%s)",
                task.run_id,
                task.payload.issue_key,
                task.payload.repo,
                task.repo_definition.clone_url,
            )
            repo_workspace = Path(record.workspace_dir) / "repo"
            repo_workspace.mkdir(parents=True, exist_ok=True)
            self._run_store.write_step_output(
                record,
                "context.json",
                {
                    "issue_key": task.payload.issue_key,
                    "repo": task.payload.repo,
                    "clone_url": task.repo_definition.clone_url,
                    "default_branch": task.repo_definition.default_branch,
                    "planned_branch": task.branch_name,
                    "workspace_repo_dir": str(repo_workspace),
                    "next_steps": [
                        "clone repository",
                        "gather code context",
                        "call coding model",
                        "run tests",
                        "push branch and create merge request",
                    ],
                },
            )
            logger.info("Prepared workspace at %s", repo_workspace)
            self._run_store.update_status(record, "completed")
        except Exception as exc:
            self._run_store.update_status(task.record, "failed", error=str(exc))
            logger.exception("Run %s failed", task.run_id)
            raise
        finally:
            self.finish_task(task.payload.issue_key)
