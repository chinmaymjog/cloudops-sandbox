# cloudops-sandbox

Local cloud lab on Docker Compose: one Traefik entry point, one PostgreSQL server, one folder per tool under `stacks/` (traefik, pgsql, prometheus, grafana, n8n, portainer, wud, pi-hole). `template/` is the starter for new stacks; the `Makefile` only loops over `docker compose` commands. See `README.md` and `CONTRIBUTING.md`.

## Hard rules

- You have no shell tools here: you cannot run `docker`, `make` or anything else. Edit files carefully and say in the PR which checks the owner should run (for example `docker compose --env-file .env.template -f stacks/<name>/docker-compose.yml config`).
- Never commit `.env` or real secrets. `.env.template` holds placeholders only; services must not ship with default credentials that work.
- Pin image tags/versions; never use `latest`.
- Don't change `.github/workflows/` unless the issue asks for it.
- Prefer a documented command over a new script (repo convention).

## Working on issues

- New stack: follow README "Add a service", starting from `template/`; add the folder name to `STACKS` in the `Makefile`.
- Keep changes minimal and scoped; one stack or change per PR; Conventional Commits.
- Update README/docs when stacks, URLs or setup steps change.
- Open a PR against `main` that references the issue (`Fixes #N`). Never push to `main` directly.
