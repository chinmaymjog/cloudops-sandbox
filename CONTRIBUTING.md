# Contributing

- Branch from `main` (`feature/*`, `bugfix/*`), one stack or change per
  branch, Conventional Commits, PR into `main`. Don't commit to `main` directly.
- New stack: follow README → Add a service, starting from `template/`.
- Prefer a documented command over a new script.
- Never commit `.env` or real secrets.
- Before opening the PR: `make up STACKS=<name>` from a fresh `.env`, then
  check its URL and `docker logs <name>`.

## AI-assisted contributions

AI tools are welcome, with these rules:

- **You are accountable** for every line you submit. Read and understand
  the code; unreviewed AI output will be closed.
- **Disclose** substantial AI assistance in the PR description.
- Never paste credentials or host details into AI tools, issues or PRs.
- Low-effort, bulk or off-topic AI-generated PRs and issues may be closed
  without review.

## Maintainer automation

The Claude agent GitHub workflow is restricted to the repository owner and
has no shell access. Agent-authored PRs get the same review as any other PR
and are never auto-merged.

## Security issues

See [SECURITY.md](SECURITY.md); do not file them as public issues.
