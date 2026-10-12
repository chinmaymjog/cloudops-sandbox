# Access Modes

How you reach the lab depends on where it runs and whether you want real
certificates. Mode A is the default and needs nothing beyond the README's
Quick Start.

| Mode | Where it runs | Certificates | Extra setup |
| :--- | :--- | :--- | :--- |
| A | Local laptop, `127.0.0.1.nip.io` | Self-signed (browser warning) | None |
| B | Remote VM, `<VM_PUBLIC_IP>.nip.io` | Self-signed (browser warning) | Open ports 80/443 |
| C | Your own domain | Real wildcard cert via Cloudflare DNS | Cloudflare API token, DNS record |

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

## Mode D: Cloudflare Tunnel

Running behind NAT/CGNAT and don't want to open ports on your router? Mode D
puts a Cloudflare Tunnel in front of Traefik. It needs the `cloudflared`
stack, which lives on the [`advanced`
branch](https://github.com/chinmaymjog/cloudops-sandbox/tree/advanced) along
with its full setup guide.
