# IntelliStock Deployment Guide

This guide provides end-to-end instructions for deploying the **IntelliStock** full-stack platform.

The system consists of 4 components:
1. **Frontend**: React 18 + Vite SPA (`client/`)
2. **Backend API**: Node.js + Express + PostgreSQL (`server/`)
3. **ML Service**: Python FastAPI + Scikit-Learn (`ml-service/`)
4. **Database**: PostgreSQL 13+ (`server/db/schema.sql`)

---

## Deployment Options at a Glance

| Deployment Target | Best For | Complexity | Cost |
| :--- | :--- | :--- | :--- |
| **Option 1: Render (Blueprint)** | Easiest cloud deployment directly connected to GitHub | ⭐ Low (1-Click) | Free tier available |
| **Option 2: Docker Compose** | VPS (AWS EC2, DigitalOcean, Hetzner, Linode) or local prod | ⭐⭐ Moderate | Server cost ($4–10/mo) |
| **Option 3: Split Cloud (Vercel + Render + Neon)** | Highest frontend performance via CDN + serverless database | ⭐⭐ Moderate | Free tiers available |
| **Option 4: Railway** | Fast cloud PaaS with managed services | ⭐ Low | Usage-based |

---

## Option 1: Render.com (Recommended Cloud Deployment)

IntelliStock includes a ready-to-use `render.yaml` Blueprint file configured for one-click deployment.

### Steps to Deploy on Render:

1. **Push your changes to GitHub**:
   ```bash
   git add .
   git commit -m "Add production deployment configurations"
   git push origin main
   ```

2. **Open Render Dashboard**:
   - Go to [dashboard.render.com](https://dashboard.render.com) and log in.
   - Click **New +** in the top right and select **Blueprint**.
   - Connect your GitHub repository: `https://github.com/manikantagadamalla/SESD-Project`.

3. **Render will automatically detect `render.yaml`** and create:
   - **`intellistock-db`**: Managed PostgreSQL database.
   - **`intellistock-ml`**: FastAPI Python Web Service.
   - **`intellistock-api`**: Node.js Express API Web Service.
   - **`intellistock-client`**: Vite React Static Site.

4. **Set Frontend API URL**:
   - Once `intellistock-api` is deployed, copy its URL (e.g., `https://intellistock-api.onrender.com`).
   - In Render, navigate to **`intellistock-client`** -> **Environment**.
   - Set:
     - `VITE_API_URL` = `https://intellistock-api.onrender.com/api`
   - Trigger a redeploy of the client so the build uses this URL.

5. **Done!** Access your application via the `intellistock-client` URL.

---

## Option 2: Docker & Docker Compose (Self-Hosted / VPS)

Use this method to run the entire stack on any Linux VPS (Ubuntu, Debian, CentOS), cloud instance (AWS EC2, DigitalOcean Droplet, Linode), or locally.

### Prerequisites:
- Docker Engine 24+ and Docker Compose v2 installed.

### Steps:

1. **Clone repository on your server**:
   ```bash
   git clone https://github.com/manikantagadamalla/SESD-Project.git
   cd SESD-Project
   ```

2. **(Optional) Configure environment variables**:
   Create a `.env` file in the project root if you wish to override default passwords:
   ```env
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=your_secure_password
   POSTGRES_DB=intellistock
   ML_API_KEY=your_secure_ml_api_key
   JWT_SECRET=your_secure_jwt_secret
   CORS_ORIGIN=*
   ```

3. **Build and start all containers**:
   ```bash
   docker compose up -d --build
   ```

4. **Verify running containers**:
   ```bash
   docker compose ps
   ```
   You should see:
   - `intellistock-postgres` (PostgreSQL on port 5432)
   - `intellistock-ml` (FastAPI on port 8000)
   - `intellistock-server` (Express API on port 5000)
   - `intellistock-client` (Nginx + React frontend on port 80 / 5173)

5. **Access the application**:
   - **Frontend**: `http://<your-server-ip>` or `http://localhost`
   - **Backend API**: `http://<your-server-ip>:5000`
   - **API Docs (Swagger)**: `http://<your-server-ip>:5000/api-docs`
   - **ML Service**: `http://<your-server-ip>:8000`

---

## Option 3: Split Deployment (Vercel + Render/Railway + Neon)

For maximum frontend speed and CDN caching, host the static React build on Vercel while running the backend and ML services on Render or Railway.

### 1. Database (Neon / Supabase / Aiven):
1. Create a free PostgreSQL instance on [neon.tech](https://neon.tech) or [supabase.com](https://supabase.com).
2. Copy the PostgreSQL connection string (`DATABASE_URL`).
3. Run the schema migrations:
   - Connect via `psql` or SQL editor in the dashboard and run `server/db/schema.sql` followed by `server/db/add-shop-and-customers.sql`.
   *(Note: The server also auto-creates missing tables on startup).*

### 2. ML Service & Backend (Render or Railway):
- **ML Service**:
  - Root directory: `ml-service`
  - Build command: `pip install -r requirements.txt`
  - Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
  - Environment variables:
    - `DATABASE_URL` = `<your-postgres-connection-string>`
    - `ML_API_KEY` = `<secure-random-key>`

- **Backend API**:
  - Root directory: `server`
  - Build command: `npm install`
  - Start command: `node server.js`
  - Environment variables:
    - `PORT` = `5000`
    - `NODE_ENV` = `production`
    - `DATABASE_URL` = `<your-postgres-connection-string>`
    - `ML_SERVICE_URL` = `https://<your-ml-service-url>`
    - `ML_API_KEY` = `<matching-secure-key>`
    - `JWT_SECRET` = `<secure-jwt-secret>`
    - `CORS_ORIGIN` = `https://<your-vercel-domain>.vercel.app`

### 3. Frontend (Vercel):
1. Import repository on [vercel.com](https://vercel.com).
2. Set **Root Directory** to `client`.
3. Set **Framework Preset** to `Vite`.
4. Add Environment Variable:
   - `VITE_API_URL` = `https://<your-backend-api-url>/api`
5. Deploy. The included `client/vercel.json` ensures client-side routing works smoothly without 404s on page reload.

---

## Environment Variables Reference

### Backend (`server/.env`)
| Variable | Description | Example / Default |
| :--- | :--- | :--- |
| `PORT` | HTTP port for Express | `5000` |
| `NODE_ENV` | Environment mode | `production` |
| `DATABASE_URL` | PostgreSQL connection URL | `postgresql://user:pass@host:5432/dbname` |
| `ML_SERVICE_URL` | Base URL of Python ML service | `http://ml-service:8000` |
| `ML_API_KEY` | Shared secret key for ML auth | `strong_random_key` |
| `JWT_SECRET` | Secret key for signing JWT auth tokens | `strong_random_key` |
| `CORS_ORIGIN` | Allowed origins (comma separated or `*`) | `https://yourdomain.com` |

### ML Service (`ml-service/.env`)
| Variable | Description | Example / Default |
| :--- | :--- | :--- |
| `DATABASE_URL` | PostgreSQL connection URL | `postgresql://user:pass@host:5432/dbname` |
| `ML_API_KEY` | Must match backend `ML_API_KEY` | `strong_random_key` |

### Frontend (`client/.env.production` or platform env vars)
| Variable | Description | Example / Default |
| :--- | :--- | :--- |
| `VITE_API_URL` | Base endpoint of backend API | `https://api.yourdomain.com/api` |

---

## Default User Accounts

When the server starts with database access, default demo accounts are seeded automatically if they don't already exist:

| Role | Email | Password |
| :--- | :--- | :--- |
| **Admin** | `admin@example.com` | `password123` |
| **Staff** | `staff@example.com` | `password123` |
| **Client** | `client@example.com` | `password123` |

> [!WARNING]
> For production deployments, change these passwords immediately after initial login or create dedicated administrative credentials.
