# Architecture

- Traefik is the only entry point; every app is `https://<name>.<APP_DOMAIN>`.
- One folder per tool under `stacks/`. All share the `control-plane` network
  and read the root `.env`.
- One PostgreSQL server; each app gets its own user and database, created by
  hand (README, Quick start step 2).
- Data lives in named Docker volumes.
- `make up` runs `docker compose --env-file .env -f stacks/<name>/docker-compose.yml up -d`
  for each name on the Makefile's `STACKS` line. Nothing else runs.

## Decisions

- **Commands, not automation** (2026-10-12). Removed the scripts, generated
  env files, Compose profiles and database init scripts: adding a service
  meant editing four places, and each layer hid its failures. Revisit only
  if a script is clearly simpler than the commands it replaces.
- **Traefik with wildcard hosts**, not a port per tool: one way to reach
  everything, on a laptop or a VM.
- **Two branches, one flow.** `main` is a starter set for new users;
  `advanced` adds the Cloudflare Tunnel (for running behind NAT/CGNAT with
  no open ports) and the stacks the owner uses.

## Rough edges

- Skip the database step and the app restarts with `password authentication
  failed`; it recovers once the database exists.
- A variable missing from `.env` becomes an empty string (Compose warns).
- WUD and Pi-hole return 404 until their first health check passes (~30s).
- In nip.io mode Traefik logs ACME errors (no Cloudflare token). Harmless.
