# Problem

## What are you building, and why?

A modular local-cloud sandbox for testing infrastructure components,
observability stacks, and automation tools on a laptop or remote VM,
with simple, documented lifecycle commands (`make up`, `make down`) and a
consistent ingress/domain model across every stack.

## Goals

- Instructions over automation: every step is a command you can read and
  run by hand; `make up` is a thin loop over `docker compose`.
- Repeatable stack onboarding with consistent routing, env handling,
  and persistence.
- Same workflow for local laptop and remote VM deployment.
- A lean, good-to-get-started default stack set - see the README's
  Stacks table. More (Portainer/WUD, Cloudflare Tunnel) lives on the
  `advanced` branch, which follows the same flow.

## Non-Goals

- No production SLA guarantees for hosted workloads.
- No enterprise multi-tenant isolation model.
- No Kubernetes runtime in this repo's scope (Docker Compose based -
  see `k3s-argocd-sandbox` for the Kubernetes/GitOps version).

## Success Criteria

- A new user can go from clone to a running lab in under 15 minutes,
  following only the README.
- A new stack is defined in its own Compose file; shared runtime values live
  in the root `.env`; new secrets and shared databases are added manually
  using the README's OpenSSL and `docker exec` instructions.

## Risks

- Stack sprawl as the catalog grows - mitigated by keeping the default
  set small and moving anything niche to the `advanced` branch.
- Secret leakage through misconfigured env files - mitigated by
  templates staying in VCS, real `.env` staying out, and pre-commit
  secret scanning.

## Notes

- Domain strategy is provided by the user (`nip.io` for local/remote-IP
  use, or a real domain via Cloudflare for Mode C).
- Required environment variables are set through the root `.env` and
  referenced directly from each stack's Compose YAML. New secret values are
  generated with OpenSSL.
