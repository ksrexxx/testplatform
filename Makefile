.PHONY: help build up down logs shell migrate seed test clean

help:
	@echo "Exam Platform Backend - Available commands:"
	@echo ""
	@echo "  make build       - Build Docker images"
	@echo "  make up          - Start all services"
	@echo "  make down        - Stop all services"
	@echo "  make logs        - View logs"
	@echo "  make shell       - Open shell in API container"
	@echo "  make migrate     - Run database migrations"
	@echo "  make seed        - Run seed data"
	@echo "  make test        - Run tests"
	@echo "  make clean       - Remove all containers and volumes"
	@echo ""

build:
	docker compose build

up:
	docker compose up -d
	@echo "Services started. API available at http://localhost:8000"
	@echo "API docs at http://localhost:8000/docs"

down:
	docker compose down

logs:
	docker compose logs -f

logs-api:
	docker compose logs -f api

logs-worker:
	docker compose logs -f celery-worker

shell:
	docker compose exec api /bin/bash

migrate:
	docker compose exec api alembic upgrade head

seed:
	docker compose exec api python scripts/seed.py

test:
	docker compose exec api pytest

test-cov:
	docker compose exec api pytest --cov=app --cov-report=html

clean:
	docker compose down -v
	rm -rf __pycache__ .pytest_cache .coverage htmlcov

db-shell:
	docker compose exec db psql -U exam_user -d exam_platform

redis-shell:
	docker compose exec redis redis-cli

# Local development without Docker
local-setup:
	./scripts/setup_local.sh

local-run:
	source venv/bin/activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

local-worker:
	source venv/bin/activate && celery -A app.tasks.celery_app worker --loglevel=info

local-beat:
	source venv/bin/activate && celery -A app.tasks.celery_app beat --loglevel=info
