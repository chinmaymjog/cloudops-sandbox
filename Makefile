.PHONY: help setup up down status

help:
	@echo "CloudOps-Sandbox - Management Commands"
	@echo "================================================"
	@echo "setup    - Initialize network and generate .env files"
	@echo "up       - Start all lab stacks (Traefik, DBs, Apps)"
	@echo "down     - Stop all stacks and clean up"
	@echo "status   - Show status of running containers"
	@echo "test-db-onboarding - Validate DB onboarding env wiring behavior"

setup:
	@bash scripts/setup.sh

up:
	@bash scripts/stacks-up.sh

down:
	@bash scripts/stacks-down.sh

status:
	@docker ps --filter name=traefik --filter name=postgresql --filter name=mysql --filter name=n8n --filter name=grafana

sync-dbs:
	@bash scripts/sync-dbs.sh

test-db-onboarding:
	@bash scripts/test-db-onboarding-env-wiring.sh
