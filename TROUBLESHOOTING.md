# Troubleshooting - Docker Build Issues

## Проблема: Failed to install requirements

Если при запуске `docker compose up -d` возникает ошибка:
```
failed to solve: process "/bin/sh -c pip install --no-cache-dir -r requirements.txt" did not complete successfully: exit code: 1
```

### Решение 1: Обновленные Dockerfiles (рекомендуется)

Dockerfiles уже обновлены с дополнительными системными зависимостями:
- `gcc`, `g++`, `make` - для компиляции C-расширений
- `libpq-dev` - для psycopg2
- `libffi-dev`, `libssl-dev` - для криптографических библиотек

Просто запустите заново:
```bash
# Пересобрать образы
docker compose build --no-cache

# Запустить
docker compose up -d
```

### Решение 2: Использовать полный образ Python

Если проблема сохраняется, используйте альтернативный Dockerfile:

```bash
# Переименовать файлы
mv docker/Dockerfile.worker docker/Dockerfile.worker.slim
mv docker/Dockerfile.worker.full docker/Dockerfile.worker

mv docker/Dockerfile.api docker/Dockerfile.api.slim  
mv docker/Dockerfile.api.full docker/Dockerfile.api

# Пересобрать
docker compose build --no-cache
docker compose up -d
```

Полный образ `python:3.11` (без `-slim`) уже содержит все необходимые инструменты для сборки.

### Решение 3: Установка зависимостей по отдельности

Если ошибка связана с конкретным пакетом, можно попробовать:

```bash
# Войти в контейнер
docker run -it --rm python:3.11-slim /bin/bash

# Установить системные зависимости
apt-get update && apt-get install -y gcc g++ make libpq-dev libffi-dev libssl-dev

# Попробовать установить проблемный пакет
pip install psycopg2-binary
pip install cryptography
pip install bcrypt
```

### Решение 4: Локальная установка без Docker

Если Docker вызывает проблемы, можно запустить локально:

```bash
# Установить PostgreSQL и Redis локально
# Ubuntu/Debian:
sudo apt-get install postgresql redis-server

# macOS:
brew install postgresql redis

# Создать виртуальное окружение
python3.11 -m venv venv
source venv/bin/activate  # Linux/macOS
# или venv\Scripts\activate  # Windows

# Установить зависимости
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# Настроить .env для локального подключения
cp .env.example .env
# Отредактировать .env:
# POSTGRES_HOST=localhost
# REDIS_HOST=localhost

# Запустить миграции
alembic upgrade head

# Запустить seed
python scripts/seed.py

# Запустить API
uvicorn app.main:app --reload

# В другом терминале - Celery worker
celery -A app.tasks.celery_app worker --loglevel=info

# В третьем терминале - Celery beat
celery -A app.tasks.celery_app beat --loglevel=info
```

### Решение 5: Проверка версий Python

Убедитесь, что используется Python 3.11+:

```bash
python --version
# Должно быть: Python 3.11.x или выше
```

### Решение 6: Очистка Docker cache

```bash
# Полная очистка Docker
docker compose down -v
docker system prune -a --volumes

# Пересборка с нуля
docker compose build --no-cache
docker compose up -d
```

### Решение 7: Проблемы на Apple Silicon (M1/M2)

Если используете Mac с Apple Silicon:

```bash
# Добавить platform в docker-compose.yml
services:
  api:
    platform: linux/amd64
    build: ...
  celery-worker:
    platform: linux/amd64
    build: ...
```

Или использовать:
```bash
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose up -d
```

### Логи для диагностики

```bash
# Подробные логи сборки
docker compose build --progress=plain

# Логи контейнеров
docker compose logs api
docker compose logs celery-worker
```

### Известные проблемы

1. **bcrypt/cryptography** - требуют компиляторы C/C++
   - Решение: установить `gcc`, `g++`, `make`, `libffi-dev`, `libssl-dev`

2. **psycopg2** - требует PostgreSQL dev библиотеки
   - Решение: установить `libpq-dev` или использовать `psycopg2-binary`

3. **pandas/numpy** - требуют дополнительную память при компиляции
   - Решение: использовать предкомпилированные wheel или увеличить память Docker

### Проверка после исправления

```bash
# Проверить что контейнеры запущены
docker compose ps

# Проверить логи
docker compose logs -f

# Проверить API
curl http://localhost:8000/health

# Запустить тесты
docker compose exec api pytest -v
```

## Дополнительная помощь

Если проблема сохраняется:

1. Сохраните полный лог ошибки: `docker compose build > build.log 2>&1`
2. Проверьте версии: `docker --version`, `docker compose version`
3. Проверьте доступную память Docker (должно быть минимум 4GB)
4. Попробуйте на другой машине или в облаке

## Быстрое решение (если совсем не работает)

Используйте готовый образ Python с предустановленными зависимостями:

```dockerfile
# В Dockerfile.worker и Dockerfile.api
FROM python:3.11
# Вместо python:3.11-slim
```

Это увеличит размер образа, но гарантированно будет работать.
