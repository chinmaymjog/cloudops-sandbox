.PHONY: help gen-secrets setup up down status

help:
	@echo "CloudOps-Sandbox - Management Commands"
	@echo "================================================"
	@echo "gen-secrets - Fill in random values for any password/key still at its template default"
	@echo "setup    - Initialize network and generate .env files"
	@echo "up       - Start all lab stacks (Traefik, Postgres, Grafana, Prometheus, n8n)"
	@echo "down     - Stop all stacks and clean up"
	@echo "status   - Show status of running containers"

gen-secrets:
	@bash scripts/generate-secrets.sh

setup:
	@bash scripts/setup.sh

up:
	@bash scripts/stacks-up.sh

down:
	@bash scripts/stacks-down.sh

status:
	@docker ps --format '{{.Names}}\t{{.Status}}' \
		--filter name=traefik --filter name=postgresql \
		--filter name=n8n --filter name=grafana --filter name=prometheus

sync-dbs:
	@bash scripts/sync-dbs.sh
