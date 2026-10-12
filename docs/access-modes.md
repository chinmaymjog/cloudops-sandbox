# Access Modes

| Mode | Where | `APP_DOMAIN` | Certificate |
| :--- | :--- | :--- | :--- |
| A | Laptop (default) | `127.0.0.1.nip.io` | Self-signed |
| B | Remote VM | `<VM_PUBLIC_IP>.nip.io` | Self-signed |
| C | Your domain | `lab.yourdomain.com` | Real, via Cloudflare DNS |

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

Behind NAT with no open ports? Mode D (Cloudflare Tunnel) is on the
[`advanced`](https://github.com/chinmaymjog/cloudops-sandbox/tree/advanced) branch.
