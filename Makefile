.PHONY: help up down logs restart build clean frontend-logs backend-logs db-shell redis-shell test

help:
	@echo "Exam Platform - Available commands:"
	@echo ""
	@echo "  make up              - Start all services (frontend + backend)"
	@echo "  make down            - Stop all services"
	@echo "  make restart         - Restart all services"
	@echo "  make logs            - View all logs"
	@echo "  make build           - Build all Docker images"
	@echo "  make clean           - Stop and remove all containers and volumes"
	@echo ""
	@echo "  make frontend-logs   - View frontend logs only"
	@echo "  make backend-logs    - View backend API logs only"
	@echo "  make db-shell        - Open PostgreSQL shell"
	@echo "  make redis-shell     - Open Redis CLI"
	@echo ""
	@echo "  make test            - Run backend tests"
	@echo "  make seed            - Run database seed"
	@echo ""

up:
	@echo "Starting all services..."
	docker compose up -d
	@echo ""
	@echo "✅ All services started!"
	@echo ""
	@echo "Frontend:  http://localhost:3000"
	@echo "Backend:   http://localhost:8000"
	@echo "API Docs:  http://localhost:8000/docs"
	@echo ""
	@echo "Default admin credentials:"
	@echo "Email:     admin@exam.kz"
	@echo "Password:  admin123456"

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

frontend-logs:
	docker compose logs -f frontend

backend-logs:
	docker compose logs -f api

build:
	docker compose build --no-cache

clean:
	@echo "WARNING: This will remove all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "All containers and volumes removed."; \
	fi

db-shell:
	docker compose exec db psql -U exam_user -d exam_platform

redis-shell:
	docker compose exec redis redis-cli

test:
	docker compose exec api pytest -v

seed:
	docker compose exec api python scripts/seed.py

# Frontend specific
frontend-build:
	docker compose build frontend

frontend-restart:
	docker compose restart frontend

# Backend specific
backend-build:
	docker compose build api celery-worker celery-beat

backend-restart:
	docker compose restart api celery-worker celery-beat

# Health checks
health:
	@echo "Checking services health..."
	@curl -s http://localhost:8000/health | jq . || echo "❌ API is not responding"
	@curl -s http://localhost:3000 > /dev/null && echo "✅ Frontend is running" || echo "❌ Frontend is not running"
	@docker compose exec db pg_isready -U exam_user > /dev/null && echo "✅ PostgreSQL is running" || echo "❌ PostgreSQL is not running"
	@docker compose exec redis redis-cli ping > /dev/null && echo "✅ Redis is running" || echo "❌ Redis is not running"

# Status
status:
	@echo "Services status:"
	@docker compose ps
