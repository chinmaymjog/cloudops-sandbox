# Contributing & Testing Guidelines

Thank you for contributing to the **CloudOps-Sandbox**! This guide ensures that every new tool added to the stack is stable, secure, and well-integrated.

## 🛠️ Development Workflow

1.  **Fork and Clone**: Create a feature branch for your new tool.
2.  **Modular Implementation**: Follow the structure in the `stacks/` directory.
3.  **Local Validation**:
    *   [ ] Run `make setup` and verify the `.env` file is generated correctly.
    *   [ ] Run `make up` and check `docker ps` to ensure the container is healthy.
    *   [ ] Verify Traefik routing: Can you reach `https://<tool>.<domain>`?
    *   [ ] Check logs: `docker compose -f stacks/<tool>/docker-compose.yml logs -f`.

## 🧪 Testing Checklist

Before submitting a PR or deploying to production, verify the following:

### 1. Local Environment (macOS/Linux Desktop)
- [ ] stack starts without manual intervention.
- [ ] Persistent data is stored in a Named Volume (not a relative bind mount).
- [ ] stack respects the `control-plane` network.
- [ ] No hardcoded passwords in `docker-compose.yml` (use variables from `.env`).

### 2. Remote VM (Linux / Headless)
- [ ] Use `scripts/remote-sync.sh` to push changes to your test VM.
- [ ] Verify that `envsubst` is installed on the remote machine.
- [ ] Ensure the firewall (UFW/iptables) allows ports 80 and 443.
- [ ] Verify SSL certificates are correctly issued by Let's Encrypt (check Traefik logs).

## 📝 Documentation Requirements
- If the tool requires specific setup (e.g., manual database initialization), document it in a `README.md` within the stack directory.
- Add the tool to the **stack Catalog** in the root `README.md`.

---
*Questions? Reach out to Chinmay Jog.*
