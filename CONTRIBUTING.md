# Contributing

- Branch from `main` (`feature/*`, `bugfix/*`), one stack or change per
  branch, Conventional Commits, PR into `main`. Don't commit to `main` directly.
- New stack: follow README → Add a service, starting from `template/`.
- Prefer a documented command over a new script.
- Never commit `.env` or real secrets.
- Before opening the PR: `make up STACKS=<name>` from a fresh `.env`, then
  check its URL and `docker logs <name>`.
