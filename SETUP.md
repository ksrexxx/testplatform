# 🚀 Setup Instructions

Quick setup guide for the Exam Platform.

## Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine + Docker Compose (Linux)
- Git (optional, if cloning from repository)

## Step-by-Step Setup

### 1. Download or Clone Project

If you have the project as a zip file:
```bash
unzip exam-platform.zip
cd exam-platform
```

If cloning from repository:
```bash
git clone <repository-url>
cd exam-platform
```

### 2. Start All Services

```bash
docker compose up -d
```

This will:
- Download all required Docker images
- Build backend and frontend containers
- Start PostgreSQL, Redis, API, Celery, and Frontend
- Run database migrations automatically
- Create default admin user

**First start may take 5-10 minutes** to download and build images.

### 3. Verify Services Are Running

```bash
docker compose ps
```

You should see all services with "Up" status:
- db
- redis
- api
- celery-worker
- celery-beat
- frontend

### 4. Access the Application

Open your browser and go to:
- **Frontend**: http://localhost:3000
- **Backend API Docs**: http://localhost:8000/docs

### 5. Login with Default Admin

```
Email: admin@exam.kz
Password: admin123456
```

## What to Do Next

### As Administrator

1. **Upload Question Bank**
   - Go to Admin Dashboard → Question Banks tab
   - Click "Choose Excel File"
   - Select `backend/sample_bank.xlsx`
   - Wait for import to complete
   - Click "Publish" on the imported bank

2. **Create Exam Template**
   - Go to Exam Templates tab
   - Click "Create Template"
   - Fill in details (title, specialty, sections)
   - Save template

3. **Schedule Exam Instance**
   - Use the created template
   - Set start and end times
   - Enable proctoring if needed
   - Create instance

### As Student

1. **Register New Account**
   - Click "Register here" on login page
   - Fill in details
   - Choose "Student" role
   - Register and login

2. **Take Exam**
   - View available exams on dashboard
   - Click "Start Exam"
   - Answer questions
   - Submit before time expires

### As Curator

1. **Register Curator Account**
   - Register with "Curator" role

2. **View Progress**
   - Select exam instance
   - View student submissions
   - Generate reports

## Useful Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f frontend
docker compose logs -f api
```

### Restart Service
```bash
docker compose restart frontend
docker compose restart api
```

### Stop All Services
```bash
docker compose down
```

### Stop and Remove All Data
```bash
docker compose down -v
```

### Rebuild After Code Changes
```bash
docker compose up -d --build
```

## Troubleshooting

### Port Already in Use

If you see "port is already allocated" error:

**Option 1**: Stop the service using that port
```bash
# On Linux/Mac
lsof -i :3000  # Find process
kill -9 <PID>  # Kill process

# On Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

**Option 2**: Change port in `docker-compose.yml`
```yaml
frontend:
  ports:
    - "3001:3000"  # Change 3000 to 3001
```

### Services Not Starting

1. Check if Docker is running
2. Check available disk space
3. Try rebuilding:
```bash
docker compose down -v
docker compose up -d --build
```

### Database Connection Error

```bash
# Check database status
docker compose ps db

# Restart database
docker compose restart db

# Check logs
docker compose logs db
```

### Frontend Not Loading

```bash
# Check frontend logs
docker compose logs frontend

# Rebuild frontend
docker compose up -d --build frontend
```

### Clear Everything and Start Fresh

```bash
# Stop all services
docker compose down -v

# Remove all containers and images (optional)
docker system prune -a

# Start fresh
docker compose up -d
```

## Network Issues

If services can't communicate:

1. Check if all services are in the same network:
```bash
docker network ls
docker network inspect exam-platform_exam-network
```

2. Restart all services:
```bash
docker compose down
docker compose up -d
```

## Performance Issues

If services are slow:

1. **Increase Docker Resources**
   - Docker Desktop → Settings → Resources
   - Increase CPU and Memory limits

2. **Check Resource Usage**
```bash
docker stats
```

3. **Reduce Running Services** (for development)
```bash
# Run only essential services
docker compose up -d db redis api frontend
```

## Database Access

Access PostgreSQL directly:
```bash
docker compose exec db psql -U exam_user -d exam_platform

# Example queries:
# \dt                    # List tables
# SELECT * FROM users;   # View users
# \q                     # Quit
```

Access Redis:
```bash
docker compose exec redis redis-cli

# Example commands:
# KEYS *          # List all keys
# GET some_key    # Get value
# exit            # Quit
```

## Development Mode

### Frontend Development (Hot Reload)

```bash
cd frontend
npm install
npm run dev
```

Frontend will run on http://localhost:5173 with hot reload.
API proxy is configured in `vite.config.ts`.

### Backend Development

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Run API
uvicorn app.main:app --reload

# Run Celery Worker (in another terminal)
celery -A app.tasks.celery_app worker --loglevel=info
```

## Production Deployment

For production:

1. **Update Environment Variables**
   - Change all passwords in `backend/.env`
   - Use strong SECRET_KEY
   - Update CORS_ORIGINS

2. **Use Production Database**
   - External PostgreSQL instance
   - Configure backups

3. **Enable HTTPS**
   - Add SSL certificates
   - Configure nginx for HTTPS

4. **Set Up Monitoring**
   - Prometheus + Grafana
   - Error tracking (Sentry)
   - Log aggregation (ELK)

5. **Use Docker Swarm or Kubernetes**
   - For high availability
   - Load balancing
   - Auto-scaling

## Need Help?

1. Check logs first: `docker compose logs [service]`
2. Review documentation in README.md
3. Check API documentation at http://localhost:8000/docs
4. Ensure all prerequisites are met
5. Try rebuilding: `docker compose up -d --build`

---

**That's it!** You should now have a fully working exam platform. 🎉

If everything is working:
- Frontend: http://localhost:3000 ✅
- API: http://localhost:8000 ✅
- API Docs: http://localhost:8000/docs ✅
