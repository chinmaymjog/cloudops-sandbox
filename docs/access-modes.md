# Access Modes

| Mode | Where | `APP_DOMAIN` | Certificate |
| :--- | :--- | :--- | :--- |
| A | Laptop (default) | `127.0.0.1.nip.io` | Self-signed |
| B | Remote VM | `<VM_PUBLIC_IP>.nip.io` | Self-signed |
| C | Your domain | `lab.yourdomain.com` | Real, via Cloudflare DNS |
| D | Behind NAT, no open ports | `yourdomain.com` | Real, via Cloudflare Tunnel |

## Mode A: Laptop

Nothing to do — it's the `.env.template` default.

## Mode B: Remote VM

Set `APP_DOMAIN=<VM_PUBLIC_IP>.nip.io` and open ports 80 and 443 on the VM.

## Mode C: Your domain

1. In `.env`: set `APP_DOMAIN`, uncomment `CF_API_EMAIL` and `CF_DNS_API_TOKEN`
   (token needs DNS edit on the zone).
2. In `stacks/traefik/conf/traefik.yml`: set your email under
   `certificatesResolvers.myresolver.acme.email`.
3. DNS: add `*.lab.yourdomain.com` pointing at `127.0.0.1` (laptop) or the VM's IP.

## Mode D: Cloudflare Tunnel

`cloudflared` connects out to Cloudflare and forwards every `*.APP_DOMAIN`
request to Traefik. Nothing is opened on your router.

`APP_DOMAIN` must be the zone apex (`yourdomain.com`), not a subdomain —
Cloudflare's free certificate doesn't cover `*.sub.yourdomain.com`.

1. Do Mode C steps 1–2.
2. [Zero Trust](https://one.dash.cloudflare.com/) → **Networks → Tunnels →
   Create a tunnel** → Cloudflared → Docker. Put the token (after `--token`)
   in `CLOUDFLARE_TUNNEL_TOKEN` in `.env`.
3. In the tunnel's **Public Hostname** tab, add one route: subdomain `*`,
   domain `APP_DOMAIN`, type `HTTPS`, URL `traefik:443`. Leave HTTP Host
   Header empty.
4. On that route, **Additional application settings → TLS → Match SNI to
   Host**: on. Without it every request returns 502.
5. Cloudflare won't create the wildcard DNS record itself. In your zone's
   **DNS → Records**, add: type `CNAME`, name `*` (just the asterisk), target
   `<TUNNEL_ID>.cfargotunnel.com` (the Tunnel ID, not the Connector ID),
   **Proxied**.
6. `make up STACKS=cloudflared`. It restarts on reboot by itself; to start it
   with every `make up`, add it to `STACKS` in the `Makefile`.
7. Before sharing any URL, put **Access → Applications** (allow only your
   email) in front of at least `traefik`, `grafana`, `portainer` and
   `prometheus` — the Traefik dashboard and Prometheus have no login, and
   the first visitor to a new Portainer claims its admin account.

Troubleshooting:

- `cloudflared` restarting with `requires the ID or name of the tunnel`:
  `CLOUDFLARE_TUNNEL_TOKEN` is empty.
- Error 1033: the CNAME target, the token and the route belong to different
  tunnels. Compare with `docker logs cloudflared | grep tunnelID`.
- A dashboard change not taking effect: `docker restart cloudflared`.
