# Contact Portal — Express + Flask Full Stack App

A full-stack contact portal built for Assignment 3. The **Express (Node.js)** frontend serves a modern UI and sends form data to a **Flask** backend API. The backend reuses the logic from [`first_app`](../first_app) (search JSON records, submit Name/Email/Message to MongoDB).

## Features

- Search records from `data.json` (same data as Flask Assignment 2)
- Submit contact form to MongoDB via Flask REST API
- Separate `frontend/` and `backend/` folders
- Dockerfiles for both services + `docker-compose.yaml`
- Health checks and shared Docker network

## Project Structure

```
fullstack-app/
├── backend/          # Flask API
├── frontend/         # Express UI
├── docs/             # HLD & LLD
├── docker-compose.yaml
└── README.md
```

## Prerequisites

- **Node.js** 18+ and **npm**
- **Python** 3.11+
- **Docker** & **Docker Compose** (for containerized run)
- **MongoDB** — local via Docker Compose, or [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)

---

## Option A — Run Locally (without Docker)

### 1. Backend (Flask)

```powershell
cd d:\Chandan\ERPWORK\fullstack-app\backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Copy environment file and set your MongoDB URI:

```powershell
copy .env.example .env
```

Copy the example env and add your MongoDB Atlas URI locally (same values as `first_app/.env`):

```powershell
copy .env.example .env
```

```env
MONGODB_URI=mongodb+srv://<user>:<password>@<cluster>.mongodb.net/?appName=<appName>
MONGODB_DATABASE=first_project
MONGODB_COLLECTION=submissions
CORS_ORIGINS=http://localhost:3000
```

**Do not commit `.env` to Git** — it is listed in `.gitignore`. Submissions from both `first_app` and this app use the same `first_project.submissions` collection when configured identically.

Start Flask:

```powershell
python app.py
```

Backend runs at **http://localhost:5000**

### 2. Frontend (Express)

Open a new terminal:

```powershell
cd d:\Chandan\ERPWORK\fullstack-app\frontend
npm install
copy .env.example .env
npm start
```

Frontend runs at **http://localhost:3000**

Open the browser → search records → submit the form.

---

## Option B — Run with Docker Compose (recommended)

### 1. Configure environment

```powershell
cd d:\Chandan\ERPWORK\fullstack-app
copy .env.example .env
```

Edit `.env` and set `DOCKERHUB_USERNAME` when pushing images.

### 2. Build and start all services

```powershell
docker compose up --build
```

| Service | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:5000 |
| MongoDB | MongoDB Atlas (`first_project` — same as `first_app`) |

Stop containers:

```powershell
docker compose down
```

---

## Push Images to Docker Hub

Replace `your-dockerhub-username` with your Docker Hub username.

### 1. Log in

```powershell
docker login
```

### 2. Build and tag images

```powershell
cd d:\Chandan\ERPWORK\fullstack-app

docker build -t your-dockerhub-username/contact-app-backend:latest ./backend
docker build -t your-dockerhub-username/contact-app-frontend:latest ./frontend
```

### 3. Push to Docker Hub

```powershell
docker push your-dockerhub-username/contact-app-backend:latest
docker push your-dockerhub-username/contact-app-frontend:latest
```

Update `DOCKERHUB_USERNAME` in `.env` so `docker-compose.yaml` uses your tagged images.

---

## Before Pushing to GitHub (important)

Remove or never stage secret files. Only commit `.env.example` templates, not real `.env` files:

```powershell
# Verify these are NOT listed before commit:
git status

# Safe to commit: .env.example, backend/.env.example, frontend/.env.example
# Never commit: .env, backend/.env, frontend/.env
```

If credentials were ever committed, rotate your MongoDB Atlas password before pushing.

---

## Push Code to GitHub

### 1. Initialize repository (if not already)

```powershell
cd d:\Chandan\ERPWORK\fullstack-app
git init
git add .
git status
git commit -m "Add Express + Flask full stack contact portal with Docker"
```

### 2. Create repo on GitHub and push

```powershell
git remote add origin https://github.com/<your-username>/<repo-name>.git
git branch -M main
git push -u origin main
```

`.gitignore` already excludes `node_modules/`, `.vscode/`, `.env`, `venv/`, and other non-essential files.

---

## API Endpoints (Flask Backend)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/records?q=` | Search JSON records |
| POST | `/api/submit` | Submit form (JSON body) |
| GET | `/api` | Raw JSON data |

### Example submit request

```bash
curl -X POST http://localhost:5000/api/submit \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Alice\",\"email\":\"alice@example.com\",\"message\":\"Hello\"}"
```

---

## Documentation

- [High-Level Design (HLD)](docs/HLD.md)
- [Low-Level Design (LLD)](docs/LLD.md)

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Backend offline" in UI | Ensure Flask is running on port 5000 and `BACKEND_URL` is correct |
| CORS error in browser | Set `CORS_ORIGINS=http://localhost:3000` in backend `.env` |
| MongoDB connection failed | Check `MONGODB_URI` in local `.env` only; verify Atlas cluster is running |
| SSL handshake failed | In Atlas → **Network Access**, add your IP or `0.0.0.0/0` (dev only); wait 1–2 min after cluster restart |
| Credentials in Git | Never commit `.env`; use `.env.example` placeholders only |
| Port already in use | Change ports in `docker-compose.yaml` or stop conflicting services |

---

## Reference

This project extends the Flask app in [`first_app`](../first_app) by moving the UI to Express and exposing Flask as a JSON API.
