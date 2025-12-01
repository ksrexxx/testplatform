# Frontend Integration Guide

How to integrate the frontend with your existing backend.

## Overview

The frontend has been designed to work seamlessly with your existing backend API. All you need to do is:

1. Copy the `frontend/` directory to your project
2. Update the `docker-compose.yml` to include the frontend service
3. Start everything with `docker compose up -d`

## Quick Integration Steps

### 1. Copy Frontend Files

Copy the entire `frontend/` directory into your project root:

```bash
# Your project structure should look like:
exam-platform/
├── backend/           # Your existing backend
│   ├── app/
│   ├── alembic/
│   ├── docker/
│   └── ...
├── frontend/          # New frontend directory
│   ├── src/
│   ├── public/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   └── ...
└── docker-compose.yml # Updated compose file
```

### 2. Update docker-compose.yml

Replace your existing `docker-compose.yml` with the new one that includes the frontend service. The key addition is:

```yaml
services:
  # ... existing services (db, redis, api, celery-worker, celery-beat)
  
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - VITE_API_URL=http://localhost:8000
    depends_on:
      - api
    networks:
      - exam-network

networks:
  exam-network:
    driver: bridge
```

**Important**: All services must be on the same network (`exam-network`).

### 3. Update Backend CORS Settings

Ensure your backend allows requests from the frontend. In your `backend/.env`:

```env
CORS_ORIGINS=http://localhost:3000,http://frontend:3000,http://127.0.0.1:3000
```

This is already configured in the provided `docker-compose.yml`.

### 4. Start Everything

```bash
# Stop existing services (if running)
docker compose down

# Start all services including frontend
docker compose up -d

# Check status
docker compose ps
```

## Network Configuration

The frontend and backend communicate through:

1. **External Access** (from browser):
   - Browser → http://localhost:3000 → Frontend (Nginx)
   - Browser → http://localhost:8000 → Backend (FastAPI)

2. **Internal Docker Network** (between containers):
   - Frontend container can reach API at `http://api:8000`
   - API container can reach db at `db:5432`
   - All containers on `exam-network`

### Nginx Proxy Configuration

The frontend's `nginx.conf` includes a proxy for API requests:

```nginx
location /api {
    proxy_pass http://api:8000;
    # ... proxy headers
}
```

This allows the frontend to make requests to `/api/*` which get proxied to the backend.

## Frontend Environment Variables

The frontend uses environment variables set at build time:

**In docker-compose.yml:**
```yaml
environment:
  - VITE_API_URL=http://localhost:8000
```

**In frontend/.env:**
```env
VITE_API_URL=http://localhost:8000
```

Change `http://localhost:8000` to your API URL if different.

## API Integration Details

### Authentication Flow

1. User logs in at frontend
2. Frontend sends credentials to `/api/v1/auth/login`
3. Backend returns JWT token
4. Frontend stores token in `localStorage`
5. All subsequent requests include: `Authorization: Bearer <token>`

### Service Layer

All API calls go through service files:
- `src/services/auth.service.ts` - Authentication
- `src/services/admin.service.ts` - Admin functions
- `src/services/exam.service.ts` - Exam management
- `src/services/attempt.service.ts` - Taking exams
- `src/services/proctor.service.ts` - Proctoring
- `src/services/curator.service.ts` - Reports & progress

### Error Handling

The API client (`src/services/api.ts`) handles:
- 401 → Auto logout and redirect to login
- 403 → Show "Access denied" toast
- Other errors → Show error message toast

## Testing the Integration

### 1. Check Services

```bash
docker compose ps
```

All services should show "Up" status.

### 2. Test Backend

```bash
curl http://localhost:8000/health
```

Should return: `{"status":"healthy",...}`

### 3. Test Frontend

Open browser: http://localhost:3000

Should show login page.

### 4. Test API Connection

1. Login with `admin@exam.kz` / `admin123456`
2. You should be redirected to admin dashboard
3. Check browser console (F12) - no CORS errors

### 5. Test Full Flow

1. Upload question bank (Excel file)
2. Publish bank
3. Create exam template
4. Create exam instance
5. Register as student
6. Take exam
7. Check results

## Troubleshooting Integration

### CORS Errors in Browser Console

**Problem**: 
```
Access to XMLHttpRequest at 'http://localhost:8000' from origin 'http://localhost:3000' 
has been blocked by CORS policy
```

**Solution**:
1. Check `backend/.env`:
   ```env
   CORS_ORIGINS=http://localhost:3000,http://frontend:3000
   ```
2. Restart API: `docker compose restart api`

### Frontend Can't Reach API

**Problem**: Frontend shows "Network Error" or "Failed to fetch"

**Solution**:
1. Check if API is running: `docker compose ps api`
2. Check API logs: `docker compose logs api`
3. Verify VITE_API_URL in `frontend/.env`
4. Check if services are on same network:
   ```bash
   docker network inspect exam-platform_exam-network
   ```

### 401 Unauthorized Errors

**Problem**: All API requests return 401

**Solution**:
1. Clear browser localStorage
2. Login again
3. Check JWT SECRET_KEY in backend matches
4. Check token expiry time (default 30 min)

### Frontend Not Building

**Problem**: Frontend build fails in Docker

**Solution**:
1. Check Node.js version in Dockerfile (should be 18+)
2. Check npm errors in logs: `docker compose logs frontend`
3. Try rebuilding: `docker compose up -d --build frontend`
4. Check for TypeScript errors in console

### Database Connection Issues

**Problem**: Backend can't connect to database

**Solution**:
1. Check if database is healthy: `docker compose ps db`
2. Verify database credentials in `backend/.env`
3. Check if database is on same network
4. Restart database: `docker compose restart db`

## Development Mode

### Run Frontend Locally (without Docker)

```bash
cd frontend
npm install
npm run dev
```

Frontend runs on http://localhost:5173 with:
- Hot reload
- Source maps
- Better error messages

The `vite.config.ts` is already configured to proxy `/api` requests to `http://api:8000` (or `http://localhost:8000` locally).

### Run Backend Locally

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Backend runs on http://localhost:8000

### Use Both Locally

1. Start database and Redis in Docker:
   ```bash
   docker compose up -d db redis
   ```

2. Run backend locally (port 8000)

3. Run frontend locally (port 5173)

4. Frontend will automatically proxy API requests

## Production Considerations

For production deployment:

### 1. Environment Variables

**Backend:**
- Use strong SECRET_KEY
- Change database passwords
- Restrict CORS_ORIGINS to your domain

**Frontend:**
- Set VITE_API_URL to production API URL
- Use environment-specific builds

### 2. HTTPS Setup

Add SSL certificates to nginx:
```nginx
server {
    listen 443 ssl;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    # ... rest of config
}
```

### 3. Build Optimization

Frontend is already optimized with:
- Code splitting
- Tree shaking
- Minification
- Gzip compression

### 4. Monitoring

Add health check endpoints:
- Frontend: nginx status
- Backend: `/health`
- Database: connection test

## Architecture Diagram

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       │ HTTP (ports 3000, 8000)
       │
       ▼
┌─────────────────────────────────────┐
│       Docker Network (exam-network) │
│                                     │
│  ┌──────────┐      ┌─────────┐   │
│  │ Frontend │─────→│   API   │   │
│  │  :3000   │      │  :8000  │   │
│  │  Nginx   │      │ FastAPI │   │
│  └──────────┘      └────┬────┘   │
│                          │         │
│                  ┌───────┴────┐   │
│                  ▼            ▼   │
│            ┌─────────┐  ┌───────┐│
│            │   DB    │  │ Redis ││
│            │  :5432  │  │ :6379 ││
│            └─────────┘  └───────┘│
└─────────────────────────────────────┘
```

## File Checklist

Make sure you have these files:

```
✓ frontend/
  ✓ src/
    ✓ components/
    ✓ pages/
    ✓ services/
    ✓ store/
    ✓ hooks/
    ✓ types/
    ✓ utils/
    ✓ App.tsx
    ✓ main.tsx
    ✓ index.css
  ✓ public/
  ✓ Dockerfile
  ✓ nginx.conf
  ✓ package.json
  ✓ tsconfig.json
  ✓ vite.config.ts
  ✓ tailwind.config.js
  ✓ .env

✓ docker-compose.yml (updated with frontend service)
✓ README.md
✓ SETUP.md
```

## Support

If you encounter issues:

1. Check logs: `docker compose logs [service]`
2. Verify network: `docker network inspect exam-platform_exam-network`
3. Test API: `curl http://localhost:8000/health`
4. Test frontend: Open http://localhost:3000
5. Check browser console for errors (F12)

## Summary

The integration is designed to be plug-and-play:
1. Copy `frontend/` directory ✅
2. Update `docker-compose.yml` ✅
3. Run `docker compose up -d` ✅
4. Access http://localhost:3000 ✅

Everything should work out of the box! 🎉
