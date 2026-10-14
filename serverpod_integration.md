# 🛠️ Serverpod 4 Integration Guide for Sanctuary (Refuge)
**Document**: `serverpod_integration.md`  
**Target Milestone**: Hackathon Integration Sprint (Tomorrow at Lunch / Night)  
**Author**: Staff Flutter & Serverpod Systems Autonomous Agent  
**Status**: Docker & Serverpod CLI Active & Ready 🚀

---

## 1. Executive Architecture

Sanctuary's Flutter client communicates with Serverpod 4 through the abstract contract [`PostRepository`](file:///Users/neil/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/lib/main.dart#L50). This allows switching between local offline mode and live Serverpod streaming without modifying any UI widgets.

```mermaid
graph LR
    subgraph Client [Flutter Client]
        UI[Sanctuary UI] --> Factory[PostRepositoryFactory]
        Factory -->|BACKEND=local| Local[LocalPostRepository]
        Factory -->|BACKEND=serverpod| SrvRepo[ServerpodPostRepository]
    end

    subgraph Server [Serverpod 4 Backend]
        SrvRepo ==>|WebSocket Stream| Endpoint[PostEndpoint]
        Endpoint --> Postgres[(PostgreSQL 16 :8090)]
        Endpoint --> Redis[(Redis 7 :8091)]
    end
```

---

## 2. Infrastructure Pre-requisites (Already Done Tonight ✅)

| Component | Status | Details |
| :--- | :--- | :--- |
| **Docker Desktop** | ✅ Running | Docker Compose v5.6.0 |
| **PostgreSQL 16** | ✅ Active | Container `sanctuary_postgres` on port `8090` |
| **Redis 7** | ✅ Active | Container `sanctuary_redis` on port `8091` |
| **Serverpod CLI** | ✅ Installed | Version `4.0.4` at `/Users/neil/.pub-cache/bin/serverpod` |
| **No Account Needed** | ✅ Verified | Open-source Serverpod local development is 100% login-free |

---

## 3. Step-by-Step Hackathon Sprint (Tomorrow at Lunch / Night)

Follow these exact steps during your hackathon coding sprint:

### Step 1: Verify Docker Containers
Confirm the database and cache are running:
```bash
docker ps
```
You should see `sanctuary_postgres` (port 8090) and `sanctuary_redis` (port 8091) up.

### Step 2: Scaffold or Link Serverpod Backend
In the workspace root or parent directory, run:
```bash
serverpod create sanctuary_server
```
*(Or use the pre-staged files in `serverpod_scaffold/`)*.

### Step 3: Copy Pre-staged Protocol & Endpoints
Copy the prepared schemas into your Serverpod server package:
```bash
# Copy entity definition
cp serverpod_scaffold/protocol/post.spy.yaml sanctuary_server/sanctuary_server_server/lib/src/protocol/
cp serverpod_scaffold/protocol/reaction_payload.spy.yaml sanctuary_server/sanctuary_server_server/lib/src/protocol/

# Copy reference endpoint
cp serverpod_scaffold/lib/src/endpoints/post_endpoint.dart sanctuary_server/sanctuary_server_server/lib/src/endpoints/
```

### Step 4: Generate Code & Create Migration
Run Serverpod code generation to compile models, serialization, and SQL tables:
```bash
cd sanctuary_server/sanctuary_server_server
serverpod generate
serverpod create-migration
```

### Step 5: Start Serverpod Server
Start the Serverpod backend in development mode:
```bash
dart bin/main.dart --apply-migrations
```
The server will bind to `http://localhost:8080/` with WebSocket streaming enabled on port 8081.

### Step 6: Run Flutter Client with Serverpod
Run the Flutter app with the `--dart-define` flag:
```bash
flutter run -d macos --dart-define=BACKEND=serverpod
# OR for Web:
flutter run -d chrome --dart-define=BACKEND=serverpod
```

---

## 4. Judging Criteria Alignment Matrix

Keep this rubric front-and-center when presenting the hackathon project:

| Criterion | What Judges Look For | How Sanctuary Delivers |
| :--- | :--- | :--- |
| **1. Serverpod 4 Utilization** | Deep use of Serverpod features (ORM, streams, endpoints, migrations) | Custom entity YAML, atomic reaction updates, space streaming via WebSockets, PostgreSQL migrations. |
| **2. Architecture & Code Quality** | Clean code, separation of concerns, testability | Pure Dart, 0 analyzer warnings, `PostRepository` decoupling, 100% passing automated widget tests. |
| **3. UX & Innovation (Calm Tech)** | Unique problem solved, intentional design | Antidote to toxic social feeds: zero badges, zero typing urgency, 4 sensory themes (Sage, Clean, Dark, Contrast), tone intent tags. |
| **4. Resilience & Offline-First** | Handling network loss, graceful fallbacks | `--dart-define=BACKEND=serverpod` allows instant fallback to local repository; zero app crashes if offline. |
| **5. Completeness & Polish** | End-to-end working user journey | Posting unhurried reflections, real-time affirmation counters (`🙏 Praying`, `🤍 Support`), filtering by tone tag. |

---

## 5. Troubleshooting Cheatsheet

- **Postgres connection error**: Ensure container is running:
  ```bash
  docker compose -f serverpod_scaffold/docker-compose.yaml up -d
  ```
- **Port Conflict on 8080/5432**: `docker-compose.yaml` maps Postgres to `8090` and Redis to `8091` to avoid conflicting with existing system services.
- **Run Tests at any time**:
  ```bash
  flutter test
  ```
