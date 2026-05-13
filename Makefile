SHELL  := /bin/bash
DOCKER := $(shell which docker)
DC     := $(DOCKER) compose

.PHONY: help start stop restart down destroy build logs shell db wp fix-permissions

# Default target
help:
	@echo ""
	@echo "  WordPress Docker — available commands:"
	@echo ""
	@echo "  make start      — first run (build + up)"
	@echo "  make up         — start without rebuild"
	@echo "  make stop       — stop containers (data preserved)"
	@echo "  make restart    — restart all containers"
	@echo "  make down       — stop + remove containers"
	@echo "  make destroy    — remove containers AND volumes (database!)"
	@echo "  make build      — rebuild WordPress/PHP image"
	@echo "  make logs       — follow logs of all services"
	@echo "  make shell      — shell in WordPress container"
	@echo "  make db         — MySQL client (root)"
	@echo "  make wp cmd=... — WP-CLI, e.g.: make wp cmd='plugin list'"
	@echo "  make fix-permissions — fix wordpress/ file ownership (run once)"
	@echo ""

## ─── Environment ────────────────────────────────────────────────────────────────

# First run: copy .env (if missing) and build images
start:
	@[ -f .env ] || (cp .env.example .env && echo "✓ Created .env from .env.example")
	$(DC) up -d --build

# Start without rebuild (faster for subsequent starts)
up:
	$(DC) up -d

# Stop containers — data in volumes is preserved
stop:
	$(DC) stop

# Restart all containers
restart:
	$(DC) restart

# Stop and remove containers (volumes preserved)
down:
	$(DC) down

# Remove everything including the database — IRREVERSIBLE
destroy:
	@echo "WARNING: this will remove containers, networks and volumes (database will be deleted)."
	@bash -c 'read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]'
	$(DC) down -v

## ─── Build ──────────────────────────────────────────────────────────────────────

# Rebuild PHP/WordPress image (after changes in docker/php/)
build:
	$(DC) up -d --build wordpress

## ─── Logs ───────────────────────────────────────────────────────────────────────

# Follow logs of all services (Ctrl+C to stop)
logs:
	$(DC) logs -f

## ─── Tools ──────────────────────────────────────────────────────────────────────

# Bash shell in WordPress container
shell:
	$(DC) exec wordpress bash

# MySQL client as root
db:
	$(DC) exec mysql mysql -u root -p"$$(grep -E '^DB_ROOT_PASSWORD=' .env | cut -d= -f2)"

# WP-CLI: make wp cmd="plugin list"
wp:
	@[ -n "$(cmd)" ] || (echo "ERROR: provide a command, e.g.: make wp cmd='plugin list'" && exit 1)
	$(DC) exec wordpress wp $(cmd) --allow-root

# Fix ownership of wordpress/ files — run once after first start
# or if files were created with wrong owner (UID 33 instead of host)
fix-permissions:
	sudo chown -R $(shell id -u):$(shell id -g) ./wordpress/
	@echo "✓ Ownership of wordpress/ changed to $(shell id -u):$(shell id -g)"
