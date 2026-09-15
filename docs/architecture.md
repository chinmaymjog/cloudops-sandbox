# Architecture

## What This Is

A local-cloud style platform for testing infrastructure components,
observability stacks, and automation tools, with one consistent ingress
and environment model. See the architecture diagram in `README.md`.

## How It Works

- **Traefik** is the single ingress entry point - all routing is
  host-based (`<service>.<APP_DOMAIN>`), with TLS handled per the
  chosen setup mode (see README).
- Each tool lives in its own `stacks/<name>/` directory with its own
  `docker-compose.yml` and `.env.template` - no monolithic compose file.
- `make setup` regenerates every stack's `.env` from the root `.env` via
  `scripts/setup.sh`; `make up` brings up core stacks (or more, via
  `PROFILE=`) via `scripts/stacks-up.sh`.
- Shared Postgres/MySQL init scripts provision per-service databases and
  users on startup.
- State persists via named Docker volumes.

## Key Decisions

- **Decision:** Modular stack directories under `stacks/<name>/`, not a
  single compose file.
  **Why:** Scales to many tools without one file becoming unmanageable;
  each stack is self-contained (compose + env template).
  **Revisit if:** Stack count causes real orchestration overhead.

- **Decision:** Standardize ingress on Traefik with a wildcard host
  strategy (`<service>.$APP_DOMAIN`), not per-stack host ports.
  **Why:** One consistent access pattern for local and remote runs,
  instead of remembering a different port per tool.
  **Revisit if:** Routing conflicts or TLS management overhead becomes
  the dominant pain point.

- **Decision:** Add `stacks/cloudflared` (Cloudflare Tunnel) as an
  optional public ingress path in front of Traefik.
  **Why:** The lab commonly runs behind NAT/CGNAT with no static public
  IP. A tunnel makes an outbound-only connection to Cloudflare's edge,
  so nothing needs to be opened on the router - unlike port-forwarding,
  which also just doesn't work under CGNAT.
  **Revisit if:** Per-app tunnel behavior (different origin
  ports/protocols per stack) is needed that a single wildcard route
  can't express.

- **Decision:** Split stacks into a core set (always up) and opt-in
  Docker Compose profiles (`identity`, `db-admin`, `management`) for
  Keycloak, MySQL/Adminer/phpMyAdmin, and Portainer/WUD.
  **Why:** `make up` used to bring up all 12 stacks unconditionally -
  more containers, more passwords to set, more exposed surface than
  most first-time users need. Core-only is a much smaller first step.
  **Revisit if:** A group needs finer-grained selection than
  `PROFILE=<group1,group2>` comfortably supports.

## Known Risks / Rough Edges

- Broken stack env generation blocks startup at the setup phase (fail
  fast, not silent).
- No Kubernetes runtime in scope - that's `k3s-argocd-sandbox`.
- Tracing isn't standardized; logs and Prometheus metrics are the
  current observability surface.
