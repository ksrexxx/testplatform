# Exam Platform Backend - Quick Start & Testing Guide

Полное руководство по запуску и тестированию платформы экзаменационного тестирования.

## 🚀 Быстрый старт

### Шаг 1: Запуск сервисов

```bash
cd backend

# Запустить все сервисы (PostgreSQL, Redis, API, Celery)
docker compose up -d

# Проверить статус сервисов
docker compose ps

# Просмотр логов
docker compose logs -f api
```

При первом запуске автоматически:
- Выполнятся миграции БД
- Создастся администратор (admin@exam.kz / admin123456)
- Создадутся специальности и предметы

### Шаг 2: Проверка работоспособности

```bash
# Health check
curl http://localhost:8000/health

# Должен вернуть:
# {"status":"healthy","app":"Exam Platform API","version":"1.0.0"}
```

### Шаг 3: OpenAPI документация

Откройте в браузере:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 📋 Полный сценарий тестирования

### 1. Аутентификация

#### Вход как администратор

```bash
# Логин
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@exam.kz",
    "password": "admin123456"
  }'

# Сохраните access_token из ответа
export ADMIN_TOKEN="<ваш_токен>"
```

#### Регистрация студента

```bash
# Регистрация
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@test.kz",
    "password": "student123",
    "full_name": "Test Student",
    "role": "student"
  }'

# Логин студента
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@test.kz",
    "password": "student123"
  }'

# Сохраните токен студента
export STUDENT_TOKEN="<токен_студента>"
```

#### Проверка текущего пользователя

```bash
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### 2. Справочники

#### Получение специальностей

```bash
curl http://localhost:8000/api/v1/references/specialties \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Ответ:
# [{"id":1,"code":"M120","title":"Маркшейдерлік іс"}]
```

#### Получение предметов

```bash
curl http://localhost:8000/api/v1/references/subjects \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Ответ содержит 4 предмета:
# - BASE-EN (Ағылшын тілі)
# - BASE-TGO (ТГО/ОДАТ)
# - PROF-GEODESY (Геодезия)
# - PROF-MARKSHEIDER (Маркшейдерлік істің жалпы курсы)
```

### 3. Импорт банка вопросов

#### Загрузка Excel файла

```bash
# Загрузка sample_bank.xlsx
curl -X POST http://localhost:8000/api/v1/admin/banks/upload \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "file=@sample_bank.xlsx"

# Ответ:
# {"task_id":"xxx-xxx-xxx","message":"Import task started..."}

# Сохраните task_id
export TASK_ID="<task_id_из_ответа>"
```

#### Проверка статуса импорта

```bash
# Проверяйте периодически (задача выполняется асинхронно)
curl http://localhost:8000/api/v1/admin/banks/task/$TASK_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Когда status = "SUCCESS", импорт завершен
```

#### Просмотр банков

```bash
curl http://localhost:8000/api/v1/admin/banks \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Ответ покажет созданные банки со статусом "draft"
```

#### Публикация банка

```bash
# Публикация банка (замените bank_id на реальный ID из предыдущего шага)
curl -X POST http://localhost:8000/api/v1/admin/banks/publish \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"bank_id": 1}'

# После публикации банк становится доступным для экзаменов
```

### 4. Создание экзамена

#### Создание шаблона экзамена

```bash
curl -X POST http://localhost:8000/api/v1/exams/templates \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "КТ M120 Тестовая сессия",
    "specialty_id": 1,
    "rules": {
      "sections": [
        {"name": "English", "subject_id": 1, "question_count": 2},
        {"name": "TGO", "subject_id": 2, "question_count": 2},
        {"name": "Geodesy", "subject_id": 3, "question_count": 2},
        {"name": "Marksheider", "subject_id": 4, "question_count": 2}
      ],
      "shuffle": true,
      "time_limit_minutes": 120
    }
  }'

# Сохраните template_id из ответа
export TEMPLATE_ID="<template_id>"
```

#### Создание инстанса экзамена

```bash
curl -X POST http://localhost:8000/api/v1/exams/instances \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": 1,
    "title": "КТ M120 - Зимняя сессия 2024",
    "start_time": "2024-01-01T09:00:00Z",
    "end_time": "2025-12-31T18:00:00Z",
    "is_proctored": true
  }'

# Сохраните instance_id
export INSTANCE_ID="<instance_id>"
```

#### Просмотр доступных экзаменов

```bash
curl http://localhost:8000/api/v1/exams/instances \
  -H "Authorization: Bearer $STUDENT_TOKEN"
```

### 5. Прохождение экзамена студентом

#### Старт попытки

```bash
curl -X POST http://localhost:8000/api/v1/attempts/start \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"instance_id": 1}'

# Ответ:
# {"attempt_id": 1, "resumed": false}

export ATTEMPT_ID="<attempt_id>"
```

#### Получение вопросов

```bash
curl http://localhost:8000/api/v1/attempts/$ATTEMPT_ID \
  -H "Authorization: Bearer $STUDENT_TOKEN"

# Ответ содержит все вопросы с перемешанными вариантами
# НО БЕЗ правильных ответов!
```

Пример ответа:
```json
{
  "id": 1,
  "instance_id": 1,
  "status": "in_progress",
  "items": [
    {
      "id": 1,
      "question_id": 5,
      "section_name": "English",
      "order_index": 0,
      "q_type": "single",
      "text": "What is the past tense of 'go'?",
      "options": [
        {"label": "A", "text": "went"},
        {"label": "B", "text": "goed"},
        {"label": "C", "text": "gone"},
        {"label": "D", "text": "going"}
      ],
      "answer_nonce": "abc123xyz",
      "selected_labels": null
    }
  ]
}
```

#### Отправка ответа на вопрос

```bash
# Используйте attempt_item_id и answer_nonce из предыдущего ответа
curl -X POST http://localhost:8000/api/v1/attempts/answer \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "attempt_item_id": 1,
    "answer_nonce": "abc123xyz",
    "selected_labels": ["A"]
  }'

# Ответ:
# {"message": "Answer saved successfully"}
```

#### Отправка прокторинг-событий

```bash
curl -X POST http://localhost:8000/api/v1/proctor/events \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "attempt_id": 1,
    "events": [
      {
        "event_type": "TAB_BLUR",
        "timestamp": "2024-12-01T10:15:30Z",
        "meta": {}
      },
      {
        "event_type": "TAB_FOCUS",
        "timestamp": "2024-12-01T10:15:45Z",
        "meta": {}
      },
      {
        "event_type": "PASTE",
        "timestamp": "2024-12-01T10:16:00Z",
        "meta": {"text": "some copied text"}
      }
    ]
  }'
```

#### Завершение попытки (Submit)

```bash
curl -X POST http://localhost:8000/api/v1/attempts/submit \
  -H "Authorization: Bearer $STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"attempt_id": 1}'

# Ответ содержит итоговый балл и статус
# {
#   "attempt_id": 1,
#   "score": 7.0,
#   "max_score": 8.0,
#   "status": "submitted",
#   "submitted_at": "2024-12-01T10:20:00Z"
# }
```

#### Просмотр итогов прокторинга

```bash
curl http://localhost:8000/api/v1/proctor/summary/$ATTEMPT_ID \
  -H "Authorization: Bearer $STUDENT_TOKEN"

# Ответ содержит статистику нарушений и итоговый уровень
# {
#   "blur_count": 1,
#   "blur_duration_seconds": 15,
#   "paste_count": 1,
#   "devtools_count": 0,
#   "proctoring_score": 80,
#   "proctoring_level": "low"
# }
```

### 6. Куратор - просмотр результатов

#### Регистрация куратора

```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "curator@test.kz",
    "password": "curator123",
    "full_name": "Test Curator",
    "role": "curator"
  }'

curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "curator@test.kz",
    "password": "curator123"
  }'

export CURATOR_TOKEN="<токен_куратора>"
```

#### Просмотр прогресса студентов

```bash
curl "http://localhost:8000/api/v1/curator/progress?instance_id=1&page=1&page_size=20" \
  -H "Authorization: Bearer $CURATOR_TOKEN"
```

#### Генерация отчета

```bash
# Запуск генерации отчета
curl -X POST http://localhost:8000/api/v1/curator/reports/generate \
  -H "Authorization: Bearer $CURATOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "instance_id": 1,
    "format": "xlsx"
  }'

# Ответ:
# {"task_id": "xxx", "message": "Report generation started"}

export REPORT_TASK_ID="<task_id>"

# Проверка статуса
curl http://localhost:8000/api/v1/curator/reports/task/$REPORT_TASK_ID \
  -H "Authorization: Bearer $CURATOR_TOKEN"
```

## 🧪 Запуск тестов

```bash
# Запуск всех тестов
docker compose exec api pytest

# С подробным выводом
docker compose exec api pytest -v

# С покрытием кода
docker compose exec api pytest --cov=app --cov-report=html

# Запуск конкретного теста
docker compose exec api pytest tests/test_comprehensive.py -v
```

## ✅ Проверка критических требований

### 1. Правильные ответы не попадают на клиент

```bash
# Получите вопросы попытки
curl http://localhost:8000/api/v1/attempts/$ATTEMPT_ID \
  -H "Authorization: Bearer $STUDENT_TOKEN"

# Проверьте ответ - НЕ должно быть:
# - correct_labels
# - is_correct
# - answer_key
# Только вопросы и варианты ответов!
```

### 2. Серверная перемешка вариантов

```bash
# Запустите две попытки разными студентами
# Варианты будут в разном порядке благодаря:
# - Уникальному seed для каждой попытки
# - Серверному shuffle_map в attempt_items
```

### 3. Идемпотентность ответов

```bash
# Отправьте один и тот же ответ дважды с одинаковым answer_nonce
# Второй запрос будет обработан корректно без дублирования
```

### 4. RBAC - контроль доступа

```bash
# Попытка студента получить доступ к админке
curl http://localhost:8000/api/v1/admin/banks \
  -H "Authorization: Bearer $STUDENT_TOKEN"

# Должен вернуть 403 Forbidden
```

### 5. Прокторинг без видео

```bash
# Отправка событий TAB_BLUR, TAB_FOCUS, PASTE, DEVTOOLS_OPEN
# Система вычисляет proctoring_score и proctoring_level
# Без использования камеры или аудио
```

## 🔍 Просмотр данных

### База данных PostgreSQL

```bash
docker compose exec db psql -U exam_user -d exam_platform

# Примеры запросов:
\dt                                    # Список таблиц
SELECT * FROM users;                   # Пользователи
SELECT * FROM question_banks;          # Банки вопросов
SELECT * FROM exam_attempts;           # Попытки экзаменов
SELECT * FROM proctor_events;          # События прокторинга
```

### Redis (кэш и очереди)

```bash
docker compose exec redis redis-cli

# Примеры команд:
KEYS *                                 # Все ключи
GET some_key                           # Получить значение
```

### Celery задачи

```bash
# Просмотр логов worker
docker compose logs -f celery-worker

# Просмотр логов beat (планировщик)
docker compose logs -f celery-beat
```

## 🐛 Отладка

### Логи API

```bash
docker compose logs -f api
```

### Логи всех сервисов

```bash
docker compose logs -f
```

### Перезапуск сервисов

```bash
# Перезапуск API
docker compose restart api

# Полный перезапуск
docker compose down
docker compose up -d
```

### Полная очистка и перезапуск

```bash
# Удаление всех данных
docker compose down -v

# Новый запуск
docker compose up -d
```

## 📊 Мониторинг

### Проверка здоровья сервисов

```bash
# API
curl http://localhost:8000/health

# PostgreSQL
docker compose exec db pg_isready -U exam_user

# Redis
docker compose exec redis redis-cli ping
```

## 🎯 Результаты тестирования

После выполнения всех шагов вы должны убедиться, что:

- ✅ Все сервисы запущены и работают
- ✅ Импорт Excel создает draft банк
- ✅ Публикация переводит банк в published
- ✅ Создание экзамена работает корректно
- ✅ Старт попытки генерирует вопросы с серверной перемешкой
- ✅ Правильные ответы НИКОГДА не попадают на клиент
- ✅ Ответы сохраняются идемпотентно
- ✅ Submit считает балл на сервере корректно
- ✅ Прокторинг-события учитываются в итоговом флаге
- ✅ Куратор может просматривать прогресс
- ✅ RBAC работает корректно для всех ролей
- ✅ Тесты проходят успешно

## 📝 Дополнительные заметки

- Токены живут 30 минут (настраивается в .env)
- Все времена в UTC
- Максимальный размер загружаемого файла: 10MB
- Celery задачи имеют таймаут 5 минут
- Логи в JSON формате для удобного парсинга
