# CivilOS — Construction Business Operating System

Welcome to the **CivilOS** monorepos root workspace! CivilOS is a SaaS platform designed for Civil Contractors to digitize daily operations, project tracking, Bills of Quantities (BOQ), and labor operations.

This repository is structured into two main subdirectories:
- `backend/`: REST API server developed in **Go** utilizing the **Fiber Framework**, **GORM**, and **SQLite** (switchable to PostgreSQL). It handles JWT sessions, tenant isolation, and role-based access controls.
- `frontend/`: Multi-platform application developed in **Flutter** targeting Web, iOS, and Android. It features a slate-dark UI, dynamic dashboard metric visualizations (`fl_chart`), and tenant feature toggles.

---

## Directory Structure

```text
civilos/
├── backend/                  # Go REST API Server
│   ├── cmd/server/           # App entry point
│   ├── internal/             # Main modules (models, db migrations, middlewares, handlers)
│   └── .env.example          # Sample environment settings
└── frontend/                 # Flutter Application
    ├── lib/                  # App screens and provider state logic
    └── test/                 # Smoke unit tests
```

---

## How to Get Started Locally

### Prerequisite Checklist
- **Go** (v1.22+ or v1.26+)
- **Flutter SDK** (v3.22+ or v3.27+)

### Step 1: Run the Go API Server
1. Navigate to the backend folder:
   ```bash
   cd backend
   ```
2. Run the application:
   ```bash
   go run cmd/server/main.go
   ```
   *The server starts listening on `http://localhost:8080` and creates an embedded SQLite database `civilos.db` automatically populated with mock tenant accounts and project entries.*

### Step 2: Run the Flutter Client
1. Open a new terminal session and navigate to the frontend folder:
   ```bash
   cd frontend
   ```
2. Pull Dart packages:
   ```bash
   flutter pub get
   ```
3. Run the client on Chrome (Web):
   ```bash
   flutter run -d chrome
   ```
4. Or run on an emulator/physical device:
   ```bash
   flutter run
   ```

---

## Pre-seeded Credentials

When the backend runs for the first time, it seeds three user accounts for immediate testing:

| Role | Email | Password | Scope / Description |
|---|---|---|---|
| **Super Admin** | `superadmin@civilos.com` | `Password123` | Platform level, toggles feature flags for tenants. |
| **Contractor Owner** | `owner@acme.com` | `Password123` | Full visibility over Acme Construction projects. |
| **Site Engineer** | `engineer@acme.com` | `Password123` | Acme Engineer who files Daily Site Diaries. |

---

## Key Scenarios to Test
1. **Tenant Isolation:** Log in as `engineer@acme.com`. When adding daily reports or querying projects, GORM queries are strictly bounded to Acme's tenant ID claims, preventing any cross-tenant data leaks.
2. **SaaS Feature Flag Controls:** 
   - Log in as `superadmin@civilos.com`, navigate to the **Super Admin** view, and toggle off the "Daily Site Diary" module for Acme Construction.
   - Log out and sign in as `engineer@acme.com`. The **Daily Diary** screen will detect the configuration modification and present a "Module Deactivated" screen.
3. **Responsive UI:** Drag the browser window margins on the Web client to see the layout switch between a Left Sidebar (desktop view) and a Bottom Navigation Bar (mobile view) smoothly.
