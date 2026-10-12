# CloudOps-Sandbox
#
# `make up` starts the stacks listed in STACKS, in order. For each one it runs
#   docker compose --env-file .env -f stacks/<name>/docker-compose.yml up -d
# so you can always run that command by hand instead.
#
# Added a new service? Put its folder name on the STACKS line below.
# Start a subset, or a stack that isn't on the list, without editing:
#   make up STACKS=pgsql
#   make up STACKS=n8n

STACKS ?= pgsql traefik prometheus grafana n8n

.PHONY: help up down status

help:
	@echo "make up      start: $(STACKS)"
	@echo "make down    stop every stack under stacks/ (data volumes are kept)"
	@echo "make status  list running containers"

up:
	@docker network inspect control-plane >/dev/null 2>&1 || docker network create control-plane
	@for s in $(STACKS); do \
		echo "==> $$s"; \
		docker compose --env-file .env -f stacks/$$s/docker-compose.yml up -d || exit 1; \
	done

down:
	@for s in $(notdir $(wildcard stacks/*)); do \
		echo "==> $$s"; \
		docker compose --env-file .env -f stacks/$$s/docker-compose.yml down || exit 1; \
	done

status:
	@docker ps --format 'table {{.Names}}\t{{.Status}}'
