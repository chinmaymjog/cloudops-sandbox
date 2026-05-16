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
	@docker ps --filter name=devops-lab
