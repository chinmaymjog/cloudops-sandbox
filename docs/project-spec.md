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
- A lean, good-to-get-started default stack set - see the README's
  Stack Catalog. More (Keycloak, a second DB engine, Cloudflare Tunnel)
  lives on the `advanced` branch instead of being on by default.

## Non-Goals

- No production SLA guarantees for hosted workloads.
- No enterprise multi-tenant isolation model.
- No Kubernetes runtime in this repo's scope (Docker Compose based -
  see `k3s-argocd-sandbox` for the Kubernetes/GitOps version).

## Success Criteria

- A new user can go from clone to a running lab in under 15 minutes,
  following only the README.
- Onboarding a new stack needs no manual edits outside that stack's own
  directory.

## Risks

- Stack sprawl as the catalog grows - mitigated by keeping the default
  set small and moving anything niche to the `advanced` branch.
- Secret leakage through misconfigured env files - mitigated by
  templates staying in VCS, real `.env` staying out, and pre-commit
  secret scanning.

## Notes

- Domain strategy is provided by the user (`nip.io` for local/remote-IP
  use, or a real domain via Cloudflare for Mode C).
- Required environment variables are set through `.env` and stack
  templates - see the README's "What You Edit" section.
