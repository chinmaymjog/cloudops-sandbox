# Access Modes

How you reach the lab depends on where it runs and whether you want real
certificates. Mode A is the default and needs nothing beyond the README's
Quick Start.

| Mode | Where it runs | Certificates | Extra setup |
| :--- | :--- | :--- | :--- |
| A | Local laptop, `127.0.0.1.nip.io` | Self-signed (browser warning) | None |
| B | Remote VM, `<VM_PUBLIC_IP>.nip.io` | Self-signed (browser warning) | Open ports 80/443 |
| C | Your own domain | Real wildcard cert via Cloudflare DNS | Cloudflare API token, DNS record |
| D | Home laptop/server behind NAT, your own domain | Real cert, no open ports | Mode C + Cloudflare Tunnel |

## Mode A: Local Laptop with nip.io

`APP_DOMAIN=127.0.0.1.nip.io` is already the `.env.template` default.

- `https://grafana.127.0.0.1.nip.io`
- `https://n8n.127.0.0.1.nip.io`

nip.io is for routing convenience, not trusted public TLS. Traefik serves a
default certificate, so browser certificate warnings are expected.

## Mode B: Remote VM with nip.io

Set `APP_DOMAIN=<VM_PUBLIC_IP>.nip.io` in `.env`, and open inbound ports `80`
and `443` on the VM's firewall/security group.

- `https://grafana.<VM_PUBLIC_IP>.nip.io`
- `https://n8n.<VM_PUBLIC_IP>.nip.io`

Browser certificate warnings are expected, as in Mode A. Use Mode C if you
need publicly trusted certificates.

## Mode C: Public Domain with Cloudflare

Use this mode if you want real, DNS-challenge based certificates.

Set in `.env`:
- `APP_DOMAIN=lab.yourdomain.com`
- `CF_API_EMAIL` (uncomment it)
- `CF_DNS_API_TOKEN` (uncomment it; needs DNS edit permission for the zone)

Also set your own email as the ACME registration email in
`stacks/traefik/conf/traefik.yml` (`certificatesResolvers.myresolver.acme.email`).

DNS: create a wildcard record `*.lab.yourdomain.com` pointing to `127.0.0.1`
(local) or the VM's public IP (remote).

## Mode D: Cloudflare Tunnel, no port-forwarding

Use this mode when the lab runs on a home laptop/server behind NAT/CGNAT and
you don't want to open any inbound ports on your router. `cloudflared` makes an
outbound-only connection to Cloudflare's edge; Cloudflare terminates public TLS
and forwards matched requests down the tunnel to Traefik over the internal
`control-plane` Docker network. Traefik still does its own host-based routing
and TLS (Mode C's DNS-01 cert), so `cloudflared` just forwards to
`https://traefik:443` — no per-app config is needed as you add stacks.

Set the same values as Mode C, plus `CLOUDFLARE_TUNNEL_TOKEN` in `.env`.

> [!IMPORTANT]
> `APP_DOMAIN` must be your zone apex (e.g. `yourdomain.com`) or, at most,
> one label deep — **not** a subdomain like `tools.yourdomain.com`.
> Cloudflare's free Universal SSL only covers the apex and its direct
> first-level wildcard (`*.yourdomain.com`); it does **not** cover a second
> -level wildcard like `*.tools.yourdomain.com`. Using a subdomain there
> makes the Cloudflare edge itself unable to complete TLS for any of your
> service hostnames (symptom: `curl`/browser fails at the TLS handshake,
> before ever reaching your tunnel) — fixable only by paying for Advanced
> Certificate Manager, or by dropping down to the apex/first level instead.

Steps:

1. In the [Zero Trust dashboard](https://one.dash.cloudflare.com/) go to
   **Networks -> Tunnels -> Create a tunnel**, choose **Cloudflared**, name it
   (e.g. `cloudops-sandbox`), and pick the **Docker** connector. Copy the
   token shown in the install command (the long string after `--token`) into
   `CLOUDFLARE_TUNNEL_TOKEN` in `.env`.
2. Still in the tunnel's **Public Hostname** tab, add one route:
   - Subdomain: `*`
   - Domain: your `APP_DOMAIN` (e.g. `lab.yourdomain.com`)
   - Type: `HTTPS`
   - URL: `traefik:443`
   - Leave **HTTP Host Header** unset so Traefik still sees the real
     subdomain and can route by `Host()` rule.

   This single wildcard route covers every current and future stack.
3. Cloudflare cannot auto-create a DNS record for a wildcard (`*`) Public
   Hostname — the dashboard will warn "no DNS record will be created" when
   you save step 2. Save it anyway (it still configures the tunnel's
   routing), then add the record yourself: regular Cloudflare dashboard ->
   your zone -> **DNS -> Records -> Add record** -> Type `CNAME`, Name `*`
   (just the asterisk — Cloudflare appends the zone name itself; typing
   `*.yourdomain.com` here creates the broken `*.yourdomain.com.yourdomain.com`
   and silently doesn't work), Target `<TUNNEL_UUID>.cfargotunnel.com` (the
   UUID is on the tunnel's page in the Zero Trust dashboard — **not** the
   Connector ID shown in the same area, which is a different value and
   won't route), Proxy status **Proxied** (orange cloud — required,
   DNS-only won't route through the tunnel). No ports need to be open on
   your router/firewall at all.
4. On the same route, expand **Additional application settings -> TLS**
   and turn on **Match SNI to Host** (or, if your dashboard doesn't have
   that toggle, set **Origin Server Name** to any hostname under
   `APP_DOMAIN`, e.g. `traefik.${APP_DOMAIN}`). Without this, `cloudflared`
   sends no SNI when it connects to `https://traefik:443`, so Traefik can't
   match its real wildcard cert and falls back to its self-signed default
   — which `cloudflared` then refuses to verify. Symptom: `cloudflared`
   logs `tls: failed to verify certificate: ... valid for ...traefik.default,
   not traefik` and every request 502s, even though DNS and the tunnel
   connection are both fine.
5. Start the tunnel. `cloudflared` is not in the Makefile's default `STACKS`
   list, so start it on its own:

   ```bash
   make up STACKS=cloudflared
   ```

   It restarts on its own after a reboot (`restart: unless-stopped`), and
   `make down` stops it along with everything else. To start it with every
   `make up`, add `cloudflared` to the end of the `STACKS` line in the
   `Makefile`.
6. **Do this before telling anyone else the URL.** In **Access ->
   Applications**, add an application per hostname with a policy allowing
   only your own email — free for a handful of users on Cloudflare's Zero
   Trust free plan, and it gates the request before it ever reaches the
   container. Priority order, highest risk first:
   1. `traefik.<APP_DOMAIN>` — the dashboard has no login of its own in
      this repo's default setup.
   2. `grafana.<APP_DOMAIN>` — **check this one is not still on the
      default `admin`/`admin` login** (see the `GRAFANA_ADMIN_PASSWORD`
      note in the README) before leaving it reachable at all.
   3. `portainer.<APP_DOMAIN>` — full Docker daemon control once logged
      in; if you haven't completed Portainer's first-run admin setup yet,
      whoever reaches it first claims that account.
   4. `prometheus.<APP_DOMAIN>` — no login at all, exposes internal
      metrics and service topology.
   5. `n8n.<APP_DOMAIN>` — it has its own login, but is an automation surface
      and shouldn't be left open to credential-stuffing.

### Troubleshooting Mode D

- **`cloudflared` keeps restarting** and logs `"cloudflared tunnel run"
  requires the ID or name of the tunnel`: `CLOUDFLARE_TUNNEL_TOKEN` is empty
  in `.env`. Set it and run `make up STACKS=cloudflared` again.
- **Cloudflare error 1033** with a tunnel that's otherwise connected and
  healthy almost always means the DNS record's Target doesn't actually
  point at the tunnel serving your Public Hostname route — recheck the
  UUID in the record against `docker logs cloudflared | grep tunnelID`
  on your host, not just what you think you copied.
- **`cloudflared` logs show a config version that doesn't advance** after
  you save a dashboard change: `docker restart cloudflared` — it fetches
  the current config fresh on reconnect, sidestepping any stuck
  push-notification.
- If you created more than one tunnel while troubleshooting, make sure
  `CLOUDFLARE_TUNNEL_TOKEN` in `.env`, the DNS record's Target, and the
  Public Hostname route are all for the *same* tunnel ID — mixing an old
  token with a new tunnel's DNS record (or vice versa) produces 1033 with
  no other symptom.
