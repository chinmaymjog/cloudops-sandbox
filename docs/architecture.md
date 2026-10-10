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
  `scripts/setup.sh`; `make up` brings up the core and monitoring stacks
  (plus any optional groups named in `PROFILE=`) via
  `scripts/stacks-up.sh`.
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

- **Decision:** Split stacks into an always-on set (`core` plus
  `monitoring`) and opt-in Docker Compose profiles (`management`,
  `database`) for Keycloak, Portainer/WUD, and MySQL.
  **Why:** `make up` used to bring up every stack unconditionally -
  more containers, more passwords to set, more exposed surface than
  most first-time users need. A small default set is a much smaller
  first step.
  **Revisit if:** A group needs finer-grained selection than
  `PROFILE=<group1,group2>` comfortably supports.

## Known Risks / Rough Edges

- `cloudflared` is in the `core` profile but needs `CLOUDFLARE_TUNNEL_TOKEN`
  to run. With no token it restarts in a loop (exit 255) on every default
  `make up`. It's harmless to the other stacks but noisy; see
  `docs/tasks.md`.
- Compose exits with `no service selected` if every service in a file is
  filtered out by profiles. `stacks-up.sh` checks each stack first and
  skips it, so new stacks must carry a `profiles:` entry in a group the
  scripts know about (`KNOWN_GROUPS` / `ALL_PROFILES`).
- Broken stack env generation blocks startup at the setup phase (fail
  fast, not silent).
- No Kubernetes runtime in scope - that's `k3s-argocd-sandbox`.
- Tracing isn't standardized; logs and Prometheus metrics are the
  current observability surface.
