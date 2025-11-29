# API Reference

## Базовые концепции

### Аутентификация
Все защищённые эндпоинты требуют JWT токен в заголовке:
```
Authorization: Bearer <token>
```

### Роли пользователей
- **admin** - полный доступ ко всем функциям
- **curator** - просмотр результатов, генерация отчётов
- **student** - прохождение экзаменов

### Формат ответов

Успешный ответ:
```json
{
  "data": {...},
  "message": "Success"
}
```

Ошибка:
```json
{
  "detail": "Error message",
  "error_code": "ERROR_CODE"
}
```

## Authentication API

### POST /api/v1/auth/register
Регистрация нового пользователя.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "full_name": "John Doe",
  "role": "student"
}
```

**Response (201):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "student",
  "is_active": true,
  "created_at": "2024-12-01T10:00:00Z"
}
```

### POST /api/v1/auth/login
Вход в систему.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "student",
    "is_active": true,
    "created_at": "2024-12-01T10:00:00Z"
  }
}
```

### GET /api/v1/auth/me
Получение информации о текущем пользователе.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "full_name": "John Doe",
  "role": "student",
  "is_active": true,
  "created_at": "2024-12-01T10:00:00Z"
}
```

## Admin API - Question Banks

### POST /api/v1/admin/banks/upload
Загрузка файла Excel с вопросами.

**Required Role:** admin

**Request:**
```
Content-Type: multipart/form-data

file: sample_bank.xlsx
```

**Response (200):**
```json
{
  "task_id": "abc123-def456",
  "message": "Import task started. Check task status to monitor progress."
}
```

### GET /api/v1/admin/banks/task/{task_id}
Проверка статуса задачи импорта.

**Required Role:** admin

**Response (200):**
```json
{
  "task_id": "abc123-def456",
  "status": "SUCCESS",
  "result": {
    "status": "completed",
    "result": {
      "success": true,
      "banks_created": {
        "BASE-EN": 1,
        "PROF-GEODESY": 2
      },
      "total_rows": 8
    }
  }
}
```

### GET /api/v1/admin/banks
Список всех банков вопросов.

**Required Role:** admin

**Query Parameters:**
- `page` (int, default=1)
- `page_size` (int, default=20)
- `subject_id` (int, optional)
- `status_filter` (string: "draft" | "published", optional)

**Response (200):**
```json
{
  "items": [
    {
      "id": 1,
      "subject_id": 1,
      "version": 1,
      "status": "draft",
      "filename": "sample_bank.xlsx",
      "total_questions": 4,
      "created_at": "2024-12-01T10:00:00Z",
      "published_at": null
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 20,
  "total_pages": 1
}
```

### POST /api/v1/admin/banks/publish
Публикация банка вопросов.

**Required Role:** admin

**Request:**
```json
{
  "bank_id": 1
}
```

**Response (200):**
```json
{
  "message": "Bank published successfully",
  "bank_id": 1
}
```

## References API

### GET /api/v1/references/specialties
Список специальностей.

**Response (200):**
```json
[
  {
    "id": 1,
    "code": "M120",
    "title": "Маркшейдерлік іс",
    "created_at": "2024-12-01T10:00:00Z"
  }
]
```

### GET /api/v1/references/subjects
Список предметов.

**Response (200):**
```json
[
  {
    "id": 1,
    "code": "BASE-EN",
    "title": "Ағылшын тілі",
    "subject_type": "base",
    "created_at": "2024-12-01T10:00:00Z"
  }
]
```

## Exams API

### POST /api/v1/exams/templates
Создание шаблона экзамена.

**Required Role:** admin

**Request:**
```json
{
  "title": "КТ M120 Зима 2024",
  "specialty_id": 1,
  "rules": {
    "sections": [
      {
        "name": "English",
        "subject_id": 1,
        "question_count": 10
      },
      {
        "name": "Geodesy",
        "subject_id": 3,
        "question_count": 15
      }
    ],
    "shuffle": true,
    "time_limit_minutes": 120
  }
}
```

**Response (201):**
```json
{
  "id": 1,
  "title": "КТ M120 Зима 2024",
  "specialty_id": 1,
  "rules": {...},
  "created_at": "2024-12-01T10:00:00Z"
}
```

### POST /api/v1/exams/instances
Создание инстанса экзамена.

**Required Role:** admin

**Request:**
```json
{
  "template_id": 1,
  "title": "КТ M120 - Зимняя сессия 2024",
  "start_time": "2024-12-15T09:00:00Z",
  "end_time": "2024-12-15T18:00:00Z",
  "is_proctored": true
}
```

**Response (201):**
```json
{
  "id": 1,
  "template_id": 1,
  "title": "КТ M120 - Зимняя сессия 2024",
  "start_time": "2024-12-15T09:00:00Z",
  "end_time": "2024-12-15T18:00:00Z",
  "is_proctored": true,
  "is_active": true,
  "created_at": "2024-12-01T10:00:00Z"
}
```

### GET /api/v1/exams/instances
Список активных экзаменов.

**Response (200):**
```json
[
  {
    "id": 1,
    "template_id": 1,
    "title": "КТ M120 - Зимняя сессия 2024",
    "start_time": "2024-12-15T09:00:00Z",
    "end_time": "2024-12-15T18:00:00Z",
    "is_proctored": true,
    "is_active": true,
    "created_at": "2024-12-01T10:00:00Z"
  }
]
```

## Attempts API

### POST /api/v1/attempts/start
Начало попытки экзамена.

**Required Role:** student

**Request:**
```json
{
  "instance_id": 1
}
```

**Response (200):**
```json
{
  "attempt_id": 1,
  "resumed": false
}
```

### GET /api/v1/attempts/{attempt_id}
Получение вопросов попытки.

**Required Role:** student

**Response (200):**
```json
{
  "id": 1,
  "instance_id": 1,
  "status": "in_progress",
  "started_at": "2024-12-15T09:30:00Z",
  "submitted_at": null,
  "time_spent_seconds": null,
  "score": null,
  "max_score": null,
  "items": [
    {
      "id": 1,
      "question_id": 5,
      "section_name": "English",
      "order_index": 0,
      "q_type": "single",
      "text": "Which sentence is grammatically correct?",
      "options": [
        {"label": "A", "text": "I am going to school"},
        {"label": "B", "text": "I going to school"},
        {"label": "C", "text": "I goes to school"},
        {"label": "D", "text": "I is going to school"}
      ],
      "answer_nonce": "nonce_abc123",
      "selected_labels": null,
      "time_spent_seconds": null
    }
  ]
}
```

**Важно:** Варианты ответов уже перемешаны на сервере, правильность не передаётся!

### POST /api/v1/attempts/answer
Сохранение ответа на вопрос.

**Required Role:** student

**Request:**
```json
{
  "attempt_item_id": 1,
  "answer_nonce": "nonce_abc123",
  "selected_labels": ["A"]
}
```

**Response (200):**
```json
{
  "message": "Answer saved successfully"
}
```

### POST /api/v1/attempts/submit
Завершение попытки и подсчёт баллов.

**Required Role:** student

**Request:**
```json
{
  "attempt_id": 1
}
```

**Response (200):**
```json
{
  "attempt_id": 1,
  "status": "submitted",
  "score": 7.0,
  "max_score": 10.0,
  "submitted_at": "2024-12-15T11:30:00Z"
}
```

## Proctoring API

### POST /api/v1/proctor/events
Отправка событий прокторинга (bulk).

**Required Role:** student

**Request:**
```json
{
  "attempt_id": 1,
  "events": [
    {
      "event_type": "TAB_BLUR",
      "timestamp": "2024-12-15T09:35:00Z",
      "meta": {}
    },
    {
      "event_type": "TAB_FOCUS",
      "timestamp": "2024-12-15T09:35:15Z",
      "meta": {}
    },
    {
      "event_type": "PASTE",
      "timestamp": "2024-12-15T09:40:00Z",
      "meta": {"text_length": 50}
    }
  ]
}
```

**Response (200):**
```json
{
  "message": "Saved 3 events successfully"
}
```

### GET /api/v1/proctor/summary/{attempt_id}
Получение итогов прокторинга.

**Required Role:** student

**Response (200):**
```json
{
  "attempt_id": 1,
  "total_events": 15,
  "blur_count": 3,
  "blur_duration_seconds": 45,
  "paste_count": 1,
  "devtools_count": 0,
  "proctoring_score": 72,
  "proctoring_level": "low"
}
```

## Curator API

### GET /api/v1/curator/progress
Просмотр прогресса студентов.

**Required Role:** curator or admin

**Query Parameters:**
- `instance_id` (int, optional)
- `page` (int, default=1)
- `page_size` (int, default=20)

**Response (200):**
```json
{
  "items": [
    {
      "user_id": 2,
      "full_name": "John Doe",
      "email": "student@test.kz",
      "attempt_id": 1,
      "instance_id": 1,
      "instance_title": "КТ M120 - Зимняя сессия 2024",
      "status": "submitted",
      "started_at": "2024-12-15T09:30:00Z",
      "submitted_at": "2024-12-15T11:30:00Z",
      "score": 7.0,
      "max_score": 10.0,
      "proctoring_level": "low"
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 20,
  "total_pages": 1
}
```

### POST /api/v1/curator/reports/generate
Генерация отчёта по экзамену.

**Required Role:** curator or admin

**Request:**
```json
{
  "instance_id": 1,
  "format": "xlsx"
}
```

**Response (200):**
```json
{
  "task_id": "xyz789-abc123",
  "message": "Report generation started. Check task status to get download link."
}
```

### GET /api/v1/curator/reports/task/{task_id}
Проверка статуса генерации отчёта.

**Required Role:** curator or admin

**Response (200):**
```json
{
  "task_id": "xyz789-abc123",
  "status": "SUCCESS",
  "download_url": "/api/v1/curator/reports/download/report_1_1234567890.xlsx",
  "result": {
    "status": "completed",
    "result": {
      "success": true,
      "file_path": "/tmp/reports/report_1_1234567890.xlsx",
      "total_attempts": 1
    }
  }
}
```

## Типы событий прокторинга

- **TAB_BLUR** - потеря фокуса вкладки
- **TAB_FOCUS** - возврат фокуса на вкладку
- **PASTE** - вставка текста из буфера обмена
- **DEVTOOLS_OPEN** - попытка открытия инструментов разработчика

## Уровни прокторинга

- **LOW** (66-100 баллов) - минимальные нарушения
- **MEDIUM** (31-65 баллов) - средний уровень нарушений
- **HIGH** (0-30 баллов) - серьёзные нарушения

Расчёт баллов:
- Старт: 100 баллов
- -5 за каждую потерю фокуса (макс -30)
- -1 за каждые 10 секунд вне фокуса (макс -20)
- -10 за каждую вставку (макс -30)
- -15 за каждое открытие devtools (макс -20)
