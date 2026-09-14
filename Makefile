.PHONY: help setup up down status

help:
	@echo "CloudOps-Sandbox - Management Commands"
	@echo "================================================"
	@echo "setup    - Initialize network and generate .env files"
	@echo "up       - Start all lab stacks (Traefik, DBs, Apps)"
	@echo "down     - Stop all stacks and clean up"
	@echo "status   - Show status of running containers"

setup:
	@bash scripts/setup.sh

up:
	@bash scripts/stacks-up.sh

down:
	@bash scripts/stacks-down.sh

status:
	@docker ps --format '{{.Names}}\t{{.Status}}' \
		--filter name=traefik --filter name=cloudflared \
		--filter name=postgresql --filter name=mysql \
		--filter name=keycloak --filter name=n8n --filter name=grafana --filter name=prometheus \
		--filter name=portainer --filter name=adminer --filter name=phpmyadmin --filter name=wud

sync-dbs:
	@bash scripts/sync-dbs.sh
