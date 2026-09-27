# Deployment Guide — RetinaAI Tele-Ophthalmology System

This guide outlines how to run and deploy both the **Backend API** and the **Frontend Web App**.

---

## Architecture Overview

- **Backend (`server/`)**: FastAPI serving the 5-Stage Diabetic Retinopathy screening pipeline, discrete-event clinic simulator, and sample dataset manager.
- **Frontend (`frontend/`)**: React 19 + TypeScript + Vite + Vanilla CSS design system.
- **Core MATLAB Pipeline (`+quality`, `+preprocess`, `+segment`, `+classify`, `+explain`, `+routing`)**: Standalone MATLAB packages complying with MathWorks SIH 26038 problem statement.

---

## 1. Quick Local Execution (Development Mode)

### Step 1: Start Backend API (FastAPI)
From the project root:
```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Run backend server on port 8000
uvicorn server.app:app --reload --port 8000
```
Backend will be live at `http://localhost:8000` with Swagger docs at `http://localhost:8000/docs`.

### Step 2: Start Frontend (React + Vite)
In a new terminal window:
```bash
# 1. Navigate to frontend
cd frontend

# 2. Install node dependencies
npm install

# 3. Start dev server
npm run dev
```
Frontend will be live at `http://localhost:3000` (proxied to port 8000 for all `/api/*` endpoints).

---

## 2. One-Command Production Deployment (Docker Compose)

Deploy both frontend (Nginx reverse-proxy SPA) and backend (FastAPI production worker) with a single command:

```bash
docker-compose up --build -d
```

- **Frontend Application**: `http://localhost:3000`
- **Backend API**: `http://localhost:8000`

To stop:
```bash
docker-compose down
```

---

## 3. Cloud / VPS Deployment (Linux / Ubuntu)

### Backend (Systemd Service)
Create `/etc/systemd/system/retinaai-backend.service`:
```ini
[Unit]
Description=RetinaAI Tele-Ophthalmology Screening API
After=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/SIH_26
ExecStart=/var/www/SIH_26/.venv/bin/uvicorn server.app:app --host 127.0.0.1 --port 8000 --workers 4
Restart=always

[Install]
WantedBy=multi-user.target
```
Enable and start:
```bash
sudo systemctl enable --now retinaai-backend
```

### Frontend (Static Build)
```bash
cd frontend
npm run build
```
Copy `frontend/dist/` to your web server directory (e.g., `/var/www/html/`) and serve with Nginx.
