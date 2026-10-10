.PHONY: help gen-secrets setup up down status

help:
	@echo "CloudOps-Sandbox - Management Commands"
	@echo "================================================"
	@echo "gen-secrets - Fill in random values for any password/key still at its template default"
	@echo "setup    - Initialize network and generate .env files"
	@echo "up       - Start core stacks (Traefik, Cloudflared, Postgres, n8n, monitoring)"
	@echo "           Add optional groups with PROFILE=<group1,group2,...> or PROFILE=all:"
	@echo "             database - Postgres, MySQL"
	@echo "             management - Keycloak, Portainer, WUD, n8n"
	@echo "             monitoring - Grafana, Prometheus"
	@echo "           e.g. make up PROFILE=database,management"
	@echo "down     - Stop all stacks (core and optional) and clean up"
	@echo "status   - Show status of running containers"

gen-secrets:
	@bash scripts/generate-secrets.sh

setup:
	@bash scripts/setup.sh

up:
	@PROFILE=$(PROFILE) bash scripts/stacks-up.sh

down:
	@bash scripts/stacks-down.sh

status:
	@docker ps --format '{{.Names}}\t{{.Status}}' \
		--filter name=traefik --filter name=cloudflared \
		--filter name=postgresql --filter name=mysql \
		--filter name=keycloak --filter name=n8n --filter name=grafana --filter name=prometheus \
		--filter name=portainer --filter name=wud

sync-dbs:
	@bash scripts/sync-dbs.sh
