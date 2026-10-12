# Contributing

Use this repository to evolve a modular Docker Compose sandbox with consistent onboarding, routing, and stateful service patterns.

## Workflow

1. Create a short-lived branch from `main` using `feature/*`, `bugfix/*`, or `hotfix/*`.
2. Keep the branch focused on one stack, runtime behavior, or documentation change.
3. Use Conventional Commits such as `feat: add stack onboarding flow` or `docs: update local setup guidance`.
4. Validate the affected stack or workflow locally before opening a Pull Request.
5. Open a Pull Request with summary, validation, and any operator notes for local or VM setup.

## Repo-Specific Guidance

- Follow the modular structure under `stacks/`.
- For a new stack, follow the README's "Add a Service" steps: a folder with a `docker-compose.yml`, its variables in `.env.template`, and its name on the `STACKS` line in the `Makefile`.
- For a shared PostgreSQL database, use the README's `docker exec` commands - there is no init script.
- Prefer a documented command over a new script. If something needs automating, it should be obviously simpler than the commands it replaces.
- Keep ingress labels consistent with the existing stacks.

## Guardrails

- Do not commit directly to `main`.
- Do not commit secrets or real environment values.
- Keep persistence on named volumes unless the repo explicitly documents another pattern.
- Update README and docs when setup, onboarding, or runtime behavior changes.

## Validation

Before opening a Pull Request:

- validate the affected stack with `make up STACKS=<name>` from a fresh `.env`
- confirm routing/logs for the affected service
- review the diff for scope and secret safety

## Documentation Updates

- Update README when stack onboarding or operator workflow changes.
- Update stack-specific docs if a service needs extra setup notes.
- Keep examples aligned with the current local and remote VM flow.
