# Tasks

Keep this short and current. Delete finished work you don't need a
record of - this is a working list, not an audit log.

## Now

- [ ] ...

## Done

- [x] Strip automation to documented commands: no scripts, no profiles,
      no init/sync DB scripts, no generated env files; `make up` loops over
      an explicit `STACKS` list; Cloudflare access modes moved to
      `docs/access-modes.md` (2026-10-12)
- [x] Fix `make up`/`make down` after the profile rename (`no service
      selected`); verified with a real run (2026-10-10)
- [x] Core/optional stack split via Docker Compose profiles (2026-09-14)
- [x] Cloudflare Tunnel (Mode D) public ingress (2026-09-14)
