# Problem

## What are you building, and why?

A modular local-cloud sandbox for testing infrastructure components,
observability stacks, and automation tools on a laptop or remote VM,
with one-command lifecycle operations (`make setup`, `make up`, `make
down`) and a consistent ingress/domain model across every stack.

## Goals

- One-command lifecycle: `make setup`, `make up`, `make down`.
- Repeatable stack onboarding with consistent routing, env handling,
  and persistence.
- Same workflow for local laptop and remote VM deployment.
- A lean default install (core stacks only) with optional stacks
  available on request - see the README's Optional Stack Groups.

## Non-Goals

- No production SLA guarantees for hosted workloads.
- No enterprise multi-tenant isolation model.
- No Kubernetes runtime in this repo's scope (Docker Compose based -
  see `k3s-argocd-sandbox` for the Kubernetes/GitOps version).

## Success Criteria

- A new user can go from clone to a running core lab in under 15
  minutes, following only the README.
- Onboarding a new stack needs no manual edits outside that stack's own
  directory.

## Risks

- Stack sprawl as the catalog grows - mitigated by the core/optional
  split and the documented onboarding pattern in the README.
- Secret leakage through misconfigured env files - mitigated by
  templates staying in VCS, real `.env` staying out, and pre-commit
  secret scanning.

## Notes

- Domain strategy is provided by the user (`nip.io` for local/remote-IP
  use, or a real domain via Cloudflare for Mode C/D).
- Required environment variables are set through `.env` and stack
  templates - see the README's "What You Edit" section.
