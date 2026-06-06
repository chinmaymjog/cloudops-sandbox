# Problem

## Document Control

- Project: CloudOps-Sandbox
- Owner: Chinmay Jog
- Last updated: 2026-06-05
- Version: 0.1.0

## How To Use This File

- Keep each section short and concrete.
- Prefer measurable statements over vague goals.
- Add requirement IDs you can trace into architecture and tasks.

## Goals

- Standardize a modular local-cloud sandbox for platform engineering experiments.
- Provide one-command lifecycle operations (`make setup`, `make up`, `make down`).
- Enable repeatable stack onboarding with consistent routing, env handling, and persistence.
- Support local and remote VM deployment with the same workflow.

## Non Goals

- No production SLA guarantees for hosted workloads.
- No enterprise multi-tenant isolation model in this phase.
- No Kubernetes runtime in this repository scope (Docker Compose based).

## Success Criteria

- A new contributor can launch the baseline lab in under 30 minutes.
- New stack onboarding follows documented steps with no manual compose edits outside stack scope.
- Critical stacks (Traefik, DB, observability) start and are reachable through configured domain strategy.

## Stakeholders

- Product/Platform: Internal Platform Engineering
- Engineering: CloudOps / DevOps maintainers
- Consumers: Engineers testing cloud-native tools and workflows

## Assumptions

- Docker and `make` are available on target hosts.
- Domain strategy is provided (`nip.io` or public DNS).
- Required environment variables are set through `.env` and stack templates.

## Risks

- Risk: Stack sprawl and inconsistent conventions as catalog grows.
- Mitigation: Enforce stack onboarding checklist and validation tasks.
- Risk: Secret leakage through misconfigured env files.
- Mitigation: Keep templates in VCS, keep real `.env` out of VCS, run secret scanning.

## Scope Summary

- In scope: Compose stacks, unified ingress, database bootstrap, observability, onboarding workflow.
- Out of scope: Production hardening runbooks for managed cloud services.

## Functional Requirements

- FR-001: Repository shall provide make targets for setup/up/down/status operations.
- FR-002: New stack onboarding shall follow a documented, repeatable process under `stacks/<name>/`.
- FR-003: Routing shall support wildcard host strategy via Traefik and configured domain.
- FR-004: Database bootstrap shall support non-destructive sync for newly added services.
- FR-005: Docs shall describe local and remote deployment flows.

## Non-Functional Requirements

- NFR-001: Setup path should be executable on macOS and Linux.
- NFR-002: Core lifecycle commands should complete without manual per-stack intervention.
- NFR-003: Secrets must not be committed in plaintext (`.env` ignored; templates only tracked).
- NFR-004: Stack data should persist via named volumes.

## References

- README.md
- CONTRIBUTING.md
- Makefile
