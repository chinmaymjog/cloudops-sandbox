# Tasks

Keep this short and current. Delete finished work you don't need a
record of - this is a working list, not an audit log.

## Now

- [ ] ...

## Next

- [ ] Stop `cloudflared` crash-looping on a default `make up` when no
      `CLOUDFLARE_TUNNEL_TOKEN` is set - either skip it in `stacks-up.sh`
      or move it to its own opt-in profile (decision needed)

## Done

- [x] Fix `make up`/`make down` after the profile rename (`no service
      selected`); verified with a real run - 5 of 6 default containers
      healthy, all routes answering through Traefik (2026-10-10)
- [x] Docs aligned to the `core`/`monitoring`/`management`/`database`
      profiles; removed unused Adminer/phpMyAdmin variables (2026-10-10)
- [x] Core/optional stack split via Docker Compose profiles (2026-09-14)
- [x] Cloudflare Tunnel (Mode D) public ingress (2026-09-14)
- [x] `make gen-secrets` to auto-fill placeholder passwords (2026-09-14)
