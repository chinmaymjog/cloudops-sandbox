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
  `scripts/setup.sh`; `make up` brings every stack up via
  `scripts/stacks-up.sh`.
- The shared Postgres init script provisions per-service databases and
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

- **Decision:** Keep the default stack set to what's good to get
  started - Traefik, Postgres, Grafana, Prometheus, n8n. Keycloak, a
  second DB engine (MySQL, Adminer, phpMyAdmin), Portainer/WUD, and
  Cloudflare Tunnel all live on the `advanced` branch instead.
  **Why:** A smaller default means fewer containers, fewer passwords to
  set, and less exposed surface for a first-time user.
  **Revisit if:** A genuinely common use case needs one of those by
  default.

## Known Risks / Rough Edges

- Broken stack env generation blocks startup at the setup phase (fail
  fast, not silent).
- No Kubernetes runtime in scope - that's `k3s-argocd-sandbox`.
- Tracing isn't standardized; logs and Prometheus metrics are the
  current observability surface.
