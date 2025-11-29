# Exam Platform Backend

Полнофункциональный backend для платформы сдачи пробных и экзаменационных тестов (КТ/магистратура в Казахстане).

## Архитектура

- **FastAPI** - современный асинхронный веб-фреймворк
- **PostgreSQL** - основная база данных
- **Redis** - кэш и брокер для Celery
- **Celery** - асинхронная обработка задач (импорт, отчёты)
- **SQLAlchemy 2.0** - ORM с полной поддержкой типизации
- **Alembic** - миграции базы данных
- **Pydantic v2** - валидация данных
- **JWT** - аутентификация с токенами

## Особенности

### Безопасность
- ✅ Правильные ответы **никогда** не отправляются на клиент
- ✅ Серверная перемешка вариантов ответов
- ✅ JWT-аутентификация с коротким временем жизни токенов
- ✅ RBAC (Role-Based Access Control) для admin/curator/student
- ✅ Валидация всех входных данных через Pydantic
- ✅ Защита от SQL-инъекций через SQLAlchemy ORM
- ✅ Audit log для критичных операций

### Прокторинг
- События: TAB_BLUR, TAB_FOCUS, PASTE, DEVTOOLS_OPEN
- Автоматический подсчёт: количество нарушений, время вне фокуса
- Уровни: LOW (66-100), MEDIUM (31-65), HIGH (0-30)
- Результаты видны только curator и admin

### Импорт вопросов
- Загрузка Excel (.xlsx) через админ-панель
- Асинхронная обработка через Celery
- Валидация структуры и данных
- Дедупликация по checksum
- Версионирование банков (draft → published)

### Движок экзаменов
- Генерация попыток с серверным seed для воспроизводимости
- Стратифицированная выборка вопросов по секциям
- Идемпотентная отправка ответов (answer_nonce)
- Подсчёт баллов на сервере после submit
- Поддержка типов вопросов: single, multi, short, open

## Быстрый старт

### Требования
- Docker и Docker Compose
- Git

### 1. Клонирование и настройка

```bash
cd backend
cp .env.example .env
# Отредактируйте .env при необходимости
```

### 2. Запуск всех сервисов

```bash
docker-compose up -d
```

Это запустит:
- PostgreSQL (порт 5432)
- Redis (порт 6379)
- API (порт 8000)
- Celery Worker
- Celery Beat

Миграции и seed-данные выполняются автоматически при старте API.

### 3. Проверка работоспособности

```bash
curl http://localhost:8000/health
```

Ожидаемый ответ:
```json
{
  "status": "healthy",
  "app": "Exam Platform API",
  "version": "1.0.0"
}
```

### 4. Просмотр логов

```bash
docker-compose logs -f api
docker-compose logs -f celery-worker
```

## Начальные данные (Seeds)

При первом запуске создаются:

**Администратор:**
- Email: `admin@exam.kz`
- Password: `admin123456`

**Специальность:**
- M120 - Маркшейдерлік іс

**Предметы:**
- BASE-EN - Ағылшын тілі (базовый)
- BASE-TGO - ТГО/ОДАТ (базовый)
- PROF-GEODESY - Геодезия (профильный)
- PROF-MARKSHEIDER - Маркшейдерлік істің жалпы курсы (профильный)

## API Endpoints

### Аутентификация
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

# Вход
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@exam.kz",
    "password": "admin123456"
  }'

# Получение текущего пользователя
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Администрирование - Импорт банка вопросов
```bash
# Загрузка файла Excel
curl -X POST http://localhost:8000/api/v1/admin/banks/upload \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -F "file=@sample_bank.xlsx"

# Ответ: {"task_id": "xxx", "message": "..."}

# Проверка статуса задачи
curl http://localhost:8000/api/v1/admin/banks/task/TASK_ID \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Список банков
curl http://localhost:8000/api/v1/admin/banks \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Публикация банка
curl -X POST http://localhost:8000/api/v1/admin/banks/publish \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"bank_id": 1}'
```

### Справочники
```bash
# Список специальностей
curl http://localhost:8000/api/v1/references/specialties \
  -H "Authorization: Bearer TOKEN"

# Список предметов
curl http://localhost:8000/api/v1/references/subjects \
  -H "Authorization: Bearer TOKEN"
```

### Экзамены
```bash
# Создание шаблона экзамена
curl -X POST http://localhost:8000/api/v1/exams/templates \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "КТ M120 Зима 2024",
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

# Создание инстанса экзамена
curl -X POST http://localhost:8000/api/v1/exams/instances \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": 1,
    "title": "КТ M120 - Зимняя сессия 2024",
    "start_time": "2024-12-01T09:00:00Z",
    "end_time": "2024-12-01T18:00:00Z",
    "is_proctored": true
  }'

# Список доступных экзаменов
curl http://localhost:8000/api/v1/exams/instances \
  -H "Authorization: Bearer TOKEN"
```

### Попытки экзамена
```bash
# Старт попытки
curl -X POST http://localhost:8000/api/v1/attempts/start \
  -H "Authorization: Bearer STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"instance_id": 1}'

# Получение вопросов попытки
curl http://localhost:8000/api/v1/attempts/1 \
  -H "Authorization: Bearer STUDENT_TOKEN"

# Отправка ответа
curl -X POST http://localhost:8000/api/v1/attempts/answer \
  -H "Authorization: Bearer STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "attempt_item_id": 1,
    "answer_nonce": "nonce_from_question",
    "selected_labels": ["A"]
  }'

# Завершение попытки
curl -X POST http://localhost:8000/api/v1/attempts/submit \
  -H "Authorization: Bearer STUDENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"attempt_id": 1}'
```

### Прокторинг
```bash
# Отправка событий прокторинга
curl -X POST http://localhost:8000/api/v1/proctor/events \
  -H "Authorization: Bearer STUDENT_TOKEN" \
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
      }
    ]
  }'

# Получение итогов прокторинга
curl http://localhost:8000/api/v1/proctor/summary/1 \
  -H "Authorization: Bearer STUDENT_TOKEN"
```

### Куратор
```bash
# Прогресс студентов
curl "http://localhost:8000/api/v1/curator/progress?instance_id=1&page=1&page_size=20" \
  -H "Authorization: Bearer CURATOR_TOKEN"

# Генерация отчёта
curl -X POST http://localhost:8000/api/v1/curator/reports/generate \
  -H "Authorization: Bearer CURATOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "instance_id": 1,
    "format": "xlsx"
  }'

# Проверка статуса отчёта
curl http://localhost:8000/api/v1/curator/reports/task/TASK_ID \
  -H "Authorization: Bearer CURATOR_TOKEN"
```

## Формат Excel для импорта

Файл `sample_bank.xlsx` содержит пример правильного формата:

| Колонка | Описание | Пример |
|---------|----------|--------|
| subject_code | Код предмета | BASE-EN, PROF-GEODESY |
| theme | Тема вопроса | Grammar, История |
| q_type | Тип вопроса | single, multi |
| lang | Язык | kz, ru |
| q_text | Текст вопроса | What is...? |
| opt_A | Вариант A | First option |
| opt_B | Вариант B | Second option |
| opt_C | Вариант C | Third option |
| opt_D | Вариант D | Fourth option |
| correct | Правильный ответ | A (для single), A;C (для multi) |
| difficulty | Сложность 1-5 | 3 |
| tags | Теги через запятую | grammar,basic |

## Тестирование

```bash
# Запуск тестов
docker-compose exec api pytest

# С покрытием
docker-compose exec api pytest --cov=app --cov-report=html
```

## Разработка

### Создание новой миграции
```bash
docker-compose exec api alembic revision --autogenerate -m "description"
```

### Применение миграций
```bash
docker-compose exec api alembic upgrade head
```

### Откат миграции
```bash
docker-compose exec api alembic downgrade -1
```

### Доступ к базе данных
```bash
docker-compose exec db psql -U exam_user -d exam_platform
```

### Доступ к Redis
```bash
docker-compose exec redis redis-cli
```

## Структура проекта

```
backend/
├── app/
│   ├── api/v1/routers/      # API эндпоинты
│   ├── core/                # Конфигурация, безопасность, RBAC
│   ├── db/                  # База данных
│   ├── models/              # SQLAlchemy модели
│   ├── schemas/             # Pydantic схемы
│   ├── services/            # Бизнес-логика
│   ├── tasks/               # Celery задачи
│   └── main.py             # FastAPI приложение
├── alembic/                 # Миграции БД
├── docker/                  # Dockerfiles
├── scripts/                 # Утилитные скрипты
├── tests/                   # Тесты
├── docker-compose.yml       # Docker Compose конфигурация
├── requirements.txt         # Python зависимости
├── sample_bank.xlsx         # Пример файла для импорта
└── README.md               # Этот файл
```

## API Documentation

После запуска доступна интерактивная документация:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Остановка и очистка

```bash
# Остановка сервисов
docker-compose down

# Остановка с удалением volumes (БД, uploads, reports)
docker-compose down -v

# Полная очистка (включая образы)
docker-compose down -v --rmi all
```

## Troubleshooting

### Порты заняты
Если порты 5432, 6379 или 8000 заняты, измените их в `docker-compose.yml`.

### Проблемы с миграциями
```bash
docker-compose down -v
docker-compose up -d
```

### Логи сервисов
```bash
docker-compose logs api
docker-compose logs celery-worker
docker-compose logs db
```

## Безопасность в продакшене

Перед развёртыванием в продакшене:

1. Смените `SECRET_KEY` на сложный случайный ключ
2. Используйте сильные пароли для БД
3. Настройте CORS только для доверенных доменов
4. Включите HTTPS
5. Настройте rate limiting
6. Регулярно обновляйте зависимости
7. Настройте мониторинг и алерты

## Лицензия

Proprietary - для внутреннего использования

## Поддержка

По вопросам обращайтесь к команде разработки.
