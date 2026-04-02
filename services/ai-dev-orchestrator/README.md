# AI Dev Orchestrator

> Status: early scaffold

AI Dev Orchestrator is a FastAPI service intended to receive normalized Jira tasks from n8n, validate them against an allowlisted GitLab repository registry, and drive a future AI-assisted implementation pipeline.

## Current Implementation

The repo now contains a working service skeleton:

- `GET /healthz` for liveness checks
- `POST /trigger-agent` for authenticated task intake
- Repo validation through `ALLOWED_REPOS_JSON` or `ALLOWED_REPOS_FILE`
- Header-based shared-secret auth through `X-Orchestrator-Token`
- In-memory duplicate-run protection per Jira issue key
- Filesystem-backed run workspaces under `ORCHESTRATOR_WORK_ROOT`
- Persisted `run.json` and `context.json` artifacts for each accepted run
- Stubbed execution pipeline where clone, edit, test, push, MR, and Jira update steps will be added next

The current app does not yet clone repositories or call an LLM. That is deliberate: intake security and request validation are implemented first.

## Local Run

Create a virtual environment, install the package, set the required environment variables, and start Uvicorn.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
export ORCHESTRATOR_TOKEN="replace-me"
export ALLOWED_REPOS_JSON='{"sample-repo":{"clone_url":"git@gitlab.example.com:team/sample-repo.git","default_branch":"main"}}'
export ORCHESTRATOR_WORK_ROOT=".orchestrator"
uvicorn ai_dev_orchestrator.main:app --reload
```

If you prefer a file-based repo registry:

```bash
cat > allowed-repos.json <<'EOF_JSON'
{"sample-repo":{"clone_url":"git@gitlab.example.com:team/sample-repo.git","default_branch":"main"}}
EOF_JSON
export ALLOWED_REPOS_FILE="$PWD/allowed-repos.json"
```

Example request:

```bash
curl -X POST http://127.0.0.1:8000/trigger-agent \
  -H "Content-Type: application/json" \
  -H "X-Orchestrator-Token: replace-me" \
  -d '{
    "issue_key": "PROJ-123",
    "repo": "sample-repo",
    "summary": "Add login field",
    "description": "Implement the login field on the sign-in form."
  }'
```

## Container Deployment

This repo includes a `Dockerfile` and `docker-compose.yml` for running the orchestrator behind Traefik on your VM.

1. Copy `.env.template` to `.env` and fill in real values.
2. Make sure your Traefik external Docker network is named `control-plane`.
3. If you use a file-based repo registry, place `allowed-repos.json` under `./conf` and set `ALLOWED_REPOS_FILE=/run/config/allowed-repos.json`.
4. Start the service:

```bash
docker compose up -d --build
```

The Compose setup intentionally does not publish a host port. Traffic is expected to come through Traefik only.

The default deployment behavior is:

- Traefik routes `https://orchestrator.${APP_DOMAIN}` to the container
- workspace data is persisted under `./data`
- optional repo allowlist files can be mounted from `./conf`
- the app stores run artifacts at `/app/.orchestrator`

If your Traefik network or labels differ, adjust `docker-compose.yml` accordingly.

## Project Layout

- `ai_dev_orchestrator/main.py`: app factory and API routes
- `ai_dev_orchestrator/config.py`: environment-driven configuration
- `ai_dev_orchestrator/service.py`: task admission and execution pipeline scaffold
- `ai_dev_orchestrator/runtime.py`: in-memory run lock registry
- `ai_dev_orchestrator/run_store.py`: persisted run metadata and workspace artifacts
- `Dockerfile`: production image for the orchestrator container
- `docker-compose.yml`: container runtime definition with Traefik labels
- `TASKS.md`: rollout checklist across VM, GitLab, Jira, n8n, and AI execution
- `tests/test_api.py`: API behavior tests for auth, repo validation, and duplicate-run rejection

## Next Build Steps

- Replace the stub executor with a real job pipeline and persistent run state
- Add Git clone/branch creation using an allowlisted repo registry
- Add test/lint gates before any push or MR creation
- Add GitLab and Jira client integrations
- Add webhook signing or stronger service-to-service auth if n8n is internet reachable

## Further Reading

The original architecture notes are in [jira-gitlab-ai-workflow/how_to_guide.md](./jira-gitlab-ai-workflow/how_to_guide.md) and [jira-gitlab-ai-workflow/task.md](./jira-gitlab-ai-workflow/task.md).
