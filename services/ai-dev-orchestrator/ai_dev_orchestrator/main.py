from __future__ import annotations

from dataclasses import dataclass

from fastapi import BackgroundTasks, Depends, FastAPI

from ai_dev_orchestrator.config import Settings
from ai_dev_orchestrator.models import HealthResponse, TaskPayload, TriggerResponse
from ai_dev_orchestrator.run_store import RunStore
from ai_dev_orchestrator.runtime import RunRegistry
from ai_dev_orchestrator.security import require_orchestrator_token, verify_token
from ai_dev_orchestrator.service import OrchestratorService


@dataclass(frozen=True)
class AppContainer:
    settings: Settings
    service: OrchestratorService


def create_app() -> FastAPI:
    settings = Settings.from_env()
    run_store = RunStore(settings.workspace_root)
    service = OrchestratorService(
        repo_registry=settings.repo_registry,
        run_registry=RunRegistry(),
        run_store=run_store,
    )
    container = AppContainer(settings=settings, service=service)

    app = FastAPI(title="AI Dev Orchestrator", version="0.1.0")
    app.state.container = container

    @app.get("/healthz", response_model=HealthResponse)
    async def healthcheck() -> HealthResponse:
        return HealthResponse(status="ok")

    @app.post("/trigger-agent", response_model=TriggerResponse, status_code=202)
    async def trigger_agent(
        payload: TaskPayload,
        background_tasks: BackgroundTasks,
        provided_token: str | None = Depends(require_orchestrator_token),
    ) -> TriggerResponse:
        verify_token(container.settings.orchestrator_token, provided_token)
        task = container.service.prepare_task(payload)
        background_tasks.add_task(container.service.execute_task, task)
        return TriggerResponse(
            status="accepted",
            issue_key=payload.issue_key,
            repo=payload.repo,
            branch=task.branch_name,
            run_id=task.run_id,
            message="Run accepted. Execution pipeline is currently stubbed.",
        )

    return app


app = create_app()
