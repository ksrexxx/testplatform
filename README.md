# Exam Platform - Full Stack Application

Complete exam management system with backend API and modern frontend interface.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### One-Command Start

```bash
# Clone the repository (if not already cloned)
# git clone <repository-url>

# Start all services
docker compose up -d

# Check service status
docker compose ps
```

That's it! The application will be available at:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

### Default Credentials

**Administrator:**
- Email: `admin@exam.kz`
- Password: `admin123456`

## 📦 What Gets Started

The `docker compose up` command starts:

1. **PostgreSQL** - Database (port 5432)
2. **Redis** - Cache and task queue (port 6379)
3. **API Server** - FastAPI backend (port 8000)
4. **Celery Worker** - Async task processor
5. **Celery Beat** - Task scheduler
6. **Frontend** - React app with Nginx (port 3000)

All services are connected in a Docker network and configured to work together.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Frontend (React)                    │
│                    http://localhost:3000                 │
└────────────────────────┬────────────────────────────────┘
                         │
                         │ HTTP/REST
                         │
┌────────────────────────▼────────────────────────────────┐
│                   API Server (FastAPI)                   │
│                    http://localhost:8000                 │
└─────┬──────────────────┬──────────────────┬─────────────┘
      │                  │                  │
      │                  │                  │
      ▼                  ▼                  ▼
┌──────────┐     ┌──────────────┐    ┌──────────┐
│PostgreSQL│     │     Redis    │    │  Celery  │
│          │     │              │    │  Workers │
│  Database│     │Cache/Queue   │    │          │
└──────────┘     └──────────────┘    └──────────┘
```

## 👥 User Roles

### Student
- View available exams
- Take exams with timer
- Monitored by proctoring system
- View results

### Curator
- Monitor student progress
- Generate reports
- View proctoring flags

### Administrator
- Upload question banks (Excel)
- Manage question banks
- Create exam templates
- Schedule exam instances
- Full system access

## 📚 Features

### Backend (FastAPI)
- ✅ JWT Authentication
- ✅ Role-based access control
- ✅ Question bank management
- ✅ Excel import with validation
- ✅ Exam template system
- ✅ Proctoring without video/audio
- ✅ Async report generation
- ✅ Answer security (server-side shuffle)
- ✅ OpenAPI documentation

### Frontend (React)
- ✅ Modern, responsive UI
- ✅ Real-time exam timer
- ✅ Auto-save answers
- ✅ Proctoring detection
- ✅ Progress tracking
- ✅ Report generation
- ✅ Excel download
- ✅ Role-based dashboards

## 🛠️ Development

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f frontend
docker compose logs -f api
docker compose logs -f celery-worker
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart frontend
docker compose restart api
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (database data)
docker compose down -v
```

### Database Access

```bash
# Access PostgreSQL
docker compose exec db psql -U exam_user -d exam_platform

# Redis CLI
docker compose exec redis redis-cli
```

## 📖 API Documentation

Once the backend is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🔧 Configuration

### Environment Variables

Backend configuration is in `backend/.env`:
```env
# Database
POSTGRES_HOST=db
POSTGRES_PORT=5432
POSTGRES_DB=exam_platform
POSTGRES_USER=exam_user
POSTGRES_PASSWORD=exam_password_2024

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# JWT
SECRET_KEY=your-secret-key-change-in-production-min-32-chars
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS
CORS_ORIGINS=http://localhost:3000,http://frontend:3000
```

Frontend configuration is in `frontend/.env`:
```env
VITE_API_URL=http://localhost:8000
```

## 📝 Usage Flow

### For Administrators

1. **Login** at http://localhost:3000/login
2. **Upload Question Bank**:
   - Go to Admin Dashboard
   - Click "Choose Excel File"
   - Wait for import to complete
   - Click "Publish" on the bank
3. **Create Exam Template**:
   - Define sections and question counts
   - Set time limits
   - Save template
4. **Schedule Exam Instance**:
   - Choose template
   - Set start/end times
   - Enable proctoring if needed
   - Create instance

### For Students

1. **Register** at http://localhost:3000/register
2. **Login** at http://localhost:3000/login
3. **Take Exam**:
   - View available exams
   - Click "Start Exam"
   - Answer questions
   - Navigate using numbered buttons
   - Submit before time runs out
4. **View Results**:
   - See score immediately
   - Review proctoring summary

### For Curators

1. **Login** with curator account
2. **Monitor Progress**:
   - Select exam instance
   - View student list
   - Check submission status
   - Review scores and proctoring levels
3. **Generate Reports**:
   - Click "Generate Report"
   - Wait for generation
   - Download Excel file

## 🧪 Testing

### Backend Tests
```bash
docker compose exec api pytest
docker compose exec api pytest -v --cov=app
```

### Manual API Testing
```bash
# Health check
curl http://localhost:8000/health

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@exam.kz","password":"admin123456"}'
```

## 📂 Project Structure

```
.
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── api/v1/routers/ # API endpoints
│   │   ├── core/           # Config, security
│   │   ├── models/         # Database models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   └── tasks/          # Celery tasks
│   ├── alembic/            # Database migrations
│   ├── docker/             # Dockerfiles
│   └── tests/              # Tests
├── frontend/               # React frontend
│   ├── src/
│   │   ├── components/    # UI components
│   │   ├── pages/         # Page components
│   │   ├── services/      # API services
│   │   ├── store/         # State management
│   │   └── hooks/         # Custom hooks
│   ├── Dockerfile
│   └── nginx.conf
└── docker-compose.yml     # Docker Compose config
```

## 🔒 Security

- JWT authentication with short token expiry
- Password hashing with bcrypt
- RBAC for all endpoints
- Correct answers never sent to client
- Server-side answer validation
- CORS configured properly
- SQL injection protection (ORM)
- XSS protection headers
- Proctoring event tracking

## 🚀 Production Deployment

For production deployment:

1. Change all default passwords in `.env`
2. Use strong `SECRET_KEY` (32+ characters)
3. Enable HTTPS with SSL certificates
4. Configure proper CORS origins
5. Set up database backups
6. Configure monitoring and logging
7. Use production-grade PostgreSQL
8. Consider Redis Cluster for scale
9. Set up CI/CD pipeline
10. Enable rate limiting

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Check what's using the port
lsof -i :3000  # or :8000, :5432, etc.

# Kill the process or change ports in docker-compose.yml
```

### Database Connection Issues
```bash
# Check if database is healthy
docker compose ps db

# View database logs
docker compose logs db

# Restart database
docker compose restart db
```

### Frontend Not Loading
```bash
# Check frontend logs
docker compose logs frontend

# Rebuild frontend
docker compose up -d --build frontend
```

### API Errors
```bash
# Check API logs
docker compose logs api

# Check if migrations ran
docker compose exec api alembic current

# Rerun migrations
docker compose exec api alembic upgrade head
```

## 📞 Support

For issues or questions:
1. Check logs: `docker compose logs [service-name]`
2. Review documentation in `/backend/` and `/frontend/`
3. Check API docs at http://localhost:8000/docs

## 📄 License

Proprietary - Internal use only

---

**Ready to start?** Just run `docker compose up -d` and open http://localhost:3000! 🎉
