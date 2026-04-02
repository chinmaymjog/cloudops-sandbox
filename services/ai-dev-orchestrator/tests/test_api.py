from __future__ import annotations

import json
from pathlib import Path

from fastapi.testclient import TestClient

from ai_dev_orchestrator.config import Settings
from ai_dev_orchestrator.main import create_app
from ai_dev_orchestrator.models import TaskPayload


def build_client(monkeypatch, tmp_path):
    monkeypatch.setenv("ORCHESTRATOR_TOKEN", "secret-token")
    monkeypatch.setenv(
        "ALLOWED_REPOS_JSON",
        '{"sample-repo":{"clone_url":"git@gitlab.example.com:team/sample-repo.git","default_branch":"main"}}',
    )
    monkeypatch.delenv("ALLOWED_REPOS_FILE", raising=False)
    monkeypatch.setenv("ORCHESTRATOR_WORK_ROOT", str(tmp_path / "work"))
    return TestClient(create_app())


def test_healthcheck(monkeypatch, tmp_path):
    client = build_client(monkeypatch, tmp_path)
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_trigger_requires_token(monkeypatch, tmp_path):
    client = build_client(monkeypatch, tmp_path)
    response = client.post(
        "/trigger-agent",
        json={
            "issue_key": "PROJ-123",
            "repo": "sample-repo",
            "summary": "Add login field",
            "description": "Implement the login field on the form.",
        },
    )
    assert response.status_code == 401


def test_trigger_rejects_unknown_repo(monkeypatch, tmp_path):
    client = build_client(monkeypatch, tmp_path)
    response = client.post(
        "/trigger-agent",
        headers={"X-Orchestrator-Token": "secret-token"},
        json={
            "issue_key": "PROJ-123",
            "repo": "other-repo",
            "summary": "Add login field",
            "description": "Implement the login field on the form.",
        },
    )
    assert response.status_code == 400
    assert "Unknown repo" in response.json()["detail"]


def test_trigger_accepts_allowed_repo(monkeypatch, tmp_path):
    client = build_client(monkeypatch, tmp_path)
    response = client.post(
        "/trigger-agent",
        headers={"X-Orchestrator-Token": "secret-token"},
        json={
            "issue_key": "PROJ-123",
            "repo": "sample-repo",
            "summary": "Add login field",
            "description": "Implement the login field on the form.",
        },
    )
    assert response.status_code == 202
    assert response.json()["branch"] == "feature/proj-123"


def test_duplicate_active_run_returns_conflict(monkeypatch, tmp_path):
    monkeypatch.setenv("ORCHESTRATOR_TOKEN", "secret-token")
    monkeypatch.setenv(
        "ALLOWED_REPOS_JSON",
        '{"sample-repo":"git@gitlab.example.com:team/sample-repo.git"}',
    )
    monkeypatch.delenv("ALLOWED_REPOS_FILE", raising=False)
    monkeypatch.setenv("ORCHESTRATOR_WORK_ROOT", str(tmp_path / "work"))
    app = create_app()
    service = app.state.container.service
    client = TestClient(app)

    payload = {
        "issue_key": "PROJ-123",
        "repo": "sample-repo",
        "summary": "Add login field",
        "description": "Implement the login field on the form.",
    }

    first_task = service.prepare_task(TaskPayload(**payload))
    try:
        response = client.post(
            "/trigger-agent",
            headers={"X-Orchestrator-Token": "secret-token"},
            json=payload,
        )
        assert response.status_code == 409
    finally:
        service.finish_task(first_task.payload.issue_key)


def test_trigger_persists_run_artifacts(monkeypatch, tmp_path):
    client = build_client(monkeypatch, tmp_path)
    response = client.post(
        "/trigger-agent",
        headers={"X-Orchestrator-Token": "secret-token"},
        json={
            "issue_key": "PROJ-123",
            "repo": "sample-repo",
            "summary": "Add login field",
            "description": "Implement the login field on the form.",
        },
    )

    assert response.status_code == 202
    body = response.json()
    run_dir = Path(tmp_path / "work" / "runs" / body["run_id"])
    run_record = json.loads((run_dir / "run.json").read_text(encoding="utf-8"))
    context = json.loads((run_dir / "context.json").read_text(encoding="utf-8"))

    assert run_record["status"] == "completed"
    assert run_record["issue_key"] == "PROJ-123"
    assert context["planned_branch"] == "feature/proj-123"
    assert (run_dir / "repo").is_dir()


def test_settings_load_repo_registry_from_file(monkeypatch, tmp_path):
    repo_file = tmp_path / "allowed-repos.json"
    repo_file.write_text(
        '{"sample-repo":{"clone_url":"git@gitlab.example.com:team/sample-repo.git","default_branch":"develop"}}',
        encoding="utf-8",
    )
    monkeypatch.delenv("ALLOWED_REPOS_JSON", raising=False)
    monkeypatch.setenv("ALLOWED_REPOS_FILE", str(repo_file))
    monkeypatch.setenv("ORCHESTRATOR_WORK_ROOT", str(tmp_path / "work"))

    settings = Settings.from_env()

    assert settings.repo_registry["sample-repo"].clone_url == "git@gitlab.example.com:team/sample-repo.git"
    assert settings.repo_registry["sample-repo"].default_branch == "develop"
