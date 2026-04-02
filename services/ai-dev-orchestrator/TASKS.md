# AI Dev Orchestrator Rollout Tasks

## Phase 1: VM and Network

- [ ] Confirm the `traefik` Docker network name on the VM matches the Compose file.
- [ ] Choose a subdomain for the orchestrator, for example `orchestrator.example.com`.
- [ ] Add DNS for that subdomain to point to the VM.
- [ ] Decide where persistent orchestrator data should live on the VM, for example `/opt/ai-dev-orchestrator/data`.
- [ ] Create a deployment directory on the VM for this repo.

## Phase 2: Container Deployment

- [ ] Copy `.env.example` to `.env` and replace `ORCHESTRATOR_HOST`.
- [ ] Generate a long random `ORCHESTRATOR_TOKEN`.
- [ ] Populate `ALLOWED_REPOS_JSON` with repo keys and clone URLs for only the repos you want automated.
- [ ] Build and start the container with `docker compose up -d --build`.
- [ ] Verify `docker compose ps` shows the orchestrator as healthy enough to serve traffic.
- [ ] Verify `https://<your-host>/healthz` works through Traefik.

## Phase 3: GitLab Access

- [ ] Create a dedicated GitLab bot user or use a narrowly scoped PAT for automation.
- [ ] Decide whether the container will use SSH deploy keys or PAT-based HTTPS cloning.
- [ ] Mount the required Git credentials into the container securely.
- [ ] Verify the VM can clone one target repo without interactive auth.
- [ ] Keep default branches protected in GitLab.
- [ ] Confirm the automation identity can push feature branches and create merge requests.

## Phase 4: Orchestrator Execution

- [ ] Implement repository clone into the per-run `repo/` workspace.
- [ ] Implement branch creation from the configured default branch.
- [ ] Add persistent run status transitions for clone success and failure.
- [ ] Add command execution logging per run.
- [ ] Add cleanup rules for stale workspaces.

## Phase 5: Jira Setup

- [ ] Create a Jira custom field named `Target GitLab Repo`.
- [ ] Add the field to the issue create screen.
- [ ] Decide which issue types or labels are eligible for automation.
- [ ] Create a test Jira issue template for automation-ready tickets.

## Phase 6: n8n Workflow

- [ ] Create a Jira webhook for issue creation or a narrower event if needed.
- [ ] Build an n8n workflow to receive the Jira webhook.
- [ ] Filter out issues that should not trigger automation.
- [ ] Map Jira ticket fields to a normalized payload with `issue_key`, `summary`, `description`, and `repo`.
- [ ] Send that payload to the orchestrator with `X-Orchestrator-Token`.
- [ ] Add retry handling and failure alerting in n8n.

## Phase 7: AI Change Generation

- [ ] Add repository context gathering rules.
- [ ] Choose the coding model and prompt format.
- [ ] Require structured patch output instead of full file rewrites.
- [ ] Apply patches in the cloned workspace.
- [ ] Capture model inputs and outputs per run with redaction where needed.

## Phase 8: Quality Gates

- [ ] Detect the repo test command per project or configure it explicitly.
- [ ] Run formatters, linters, and tests before any push.
- [ ] Block GitLab push and MR creation when checks fail.
- [ ] Persist failure summaries and expose them in run artifacts.

## Phase 9: Feedback Loop

- [ ] Create GitLab merge requests automatically after a successful run.
- [ ] Post the MR link back to Jira.
- [ ] Transition the Jira issue to `In Review` only after MR creation succeeds.
- [ ] Record final run status and external links in the run metadata.
