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
- For a new stack, add its folder, `docker-compose.yml`, and `.env.template`.
- If a stack needs a database, wire provisioning through the documented PostgreSQL or MySQL init pattern.
- Keep ingress labels consistent with the root README onboarding flow.

## Guardrails

- Do not commit directly to `main`.
- Do not commit secrets or real environment values.
- Keep persistence on named volumes unless the repo explicitly documents another pattern.
- Update README and docs when setup, onboarding, or runtime behavior changes.

## Validation

Before opening a Pull Request:

- run `make setup`
- validate the affected stack with `make up` or a targeted `docker compose` run
- confirm routing/logs for the affected service
- review the diff for scope and secret safety

## Documentation Updates

- Update README when stack onboarding or operator workflow changes.
- Update stack-specific docs if a service needs extra setup notes.
- Keep examples aligned with the current local and remote VM flow.
