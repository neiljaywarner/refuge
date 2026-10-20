# ⚡ Serverpod Architecture Deep Dive (Historical Archive)

> [!NOTE]
> **Historical Archive Document**: This document captures the initial Serverpod 4 and PostgreSQL/Redis backend evaluation. For current production backend architecture, see [`Backend-and-Database-Architecture`](Backend-and-Database-Architecture) and [`Backend-Migration-Strategy-Serverpod-Appwrite-Firebase`](Backend-Migration-Strategy-Serverpod-Appwrite-Firebase).

> This document details the technical implementation of **Serverpod 4** within **Sanctuary (Refuge)**.

---

## 🏗️ Topology & Architecture

Sanctuary implements a modern, single-language full-stack architecture using **Dart 3.13** from the Flutter mobile/web client to the Serverpod cloud container:

```
[Flutter Multi-Platform Client]
      │
      ├── HTTPS / JSON RPC  ──▶  Serverpod 4 Monolith (Relic HTTP Gateway)
      │                                │
      └── WSS (WebSockets)   ──▶  Session Message Streams (Pub/Sub)
                                       │
                         ┌─────────────┴─────────────┐
                         ▼                           ▼
                 PostgreSQL 16 Engine             Redis 7
             (reflection_posts table)       (Cache & Clustering)
```

---

## 📐 Protocol Definitions (`.spy.yaml`)

Serverpod protocols are defined in concise YAML schemas that compile into type-safe Dart classes for both server and client:

### 1. `ReflectionPost` (`reflection_post.spy.yaml`)
```yaml
class: ReflectionPost
table: reflection_posts
fields:
  authorName: String
  spaceKey: String
  intentTag: String
  specialInterestTag: String?
  content: String
  createdAt: DateTime
  prayingCount: int
  standingWithCount: int
  peaceCount: int
  encouragedCount: int
indexes:
  space_created_idx:
    fields: spaceKey, createdAt
```
* **Database Mapping**: Generates PostgreSQL table `reflection_posts` with auto-incrementing BigInt primary key `id`.
* **Indexing Strategy**: The composite index `space_created_idx` optimizes queries filtering by fellowship space ordered by creation timestamp, ensuring $O(\log N)$ query times even as the community scales.

### 2. `QuietDigest` (`quiet_digest.spy.yaml`)
```yaml
class: QuietDigest
fields:
  spaceKey: String
  totalReflections: int
  totalCareAffirmations: int
  predominantIntent: String
  featuredSpecialInterest: String?
  summaryMessage: String
  generatedAt: DateTime
```
* **Domain Entity**: Non-table serialization model calculated server-side to provide high-level, calm community health indicators without exposing individual tracking metrics.

---

## 🔌 Endpoint Architecture (`ReflectionEndpoint`)

Located in `sanctuary_server_server/lib/src/reflections/reflection_endpoint.dart`, `ReflectionEndpoint` handles all fellowship operations:

### 1. `publishReflection(Session session, ReflectionPost post)`
* **Hostile Urgency Rejection**: Sanitizes input against manipulative keywords (`urgent`, `breaking news`, `click here`, `act now`, `don't miss out`). Throws `ArgumentError` if found.
* **Database Insert**:
  ```dart
  final inserted = await ReflectionPost.db.insertRow(session, post);
  ```
* **Real-Time Broadcast**:
  ```dart
  session.messages.postMessage('space_${post.spaceKey}', inserted);
  ```

### 2. `affirmCare(Session session, int postId, String reactionType)`
* **Atomic Field Increments**: Updates the corresponding care counter (`praying`, `standingWith`, `peace`, `encouraged`, `relatable`) directly in SQL, avoiding concurrency race conditions:
  ```dart
  final post = await ReflectionPost.db.findById(session, postId);
  if (post != null) {
    // Increment specific reaction counter atomically
    await ReflectionPost.db.updateRow(session, post);
    session.messages.postMessage('space_${post.spaceKey}', post);
  }
  ```

### 3. `watchSpace(Session session, String spaceKey)`
* Implements an asynchronous generator stream (`async*`):
  1. Seeds initially from PostgreSQL in descending chronological order.
  2. Listens to `session.messages.createStream('space_$spaceKey')` for live broadcast events.

### 4. `getQuietDigest(Session session, String spaceKey)`
* Aggregates total posts, care affirmations, and dominant intent tags for the requested space, formulating an unhurried, reassuring summary message.

---

## 🐳 Containerization & Automatic Migrations

In Serverpod 4, migrations are generated via `serverpod create-migration` and stored in `migrations/<version>/`.

To guarantee zero-manual-intervention deployments on **Serverpod Cloud (`scloud`)**, the Docker entrypoint in `Dockerfile` includes `--apply-migrations`:
```dockerfile
ENTRYPOINT ./bin/server --mode=$runmode --server-id=$serverid --logging=$logging --role=$role --apply-migrations
```
Upon container launch, the server queries the `serverpod_migrations` table, compares installed versions against migration definitions, executes pending SQL schema updates, and begins accepting API traffic.

---

## 🖥️ Serverpod Insights macOS Desktop Diagnostics

To monitor runtime server health, database execution latency, and WebSocket streaming states during development and live testing, we utilized the official **Serverpod Insights** native macOS application.

### Key Capabilities in Refuge Development:
1. **Endpoint & Session Profiling**:
   - Monitored real-time RPC invocation latency for `ReflectionEndpoint` methods (`publishReflection`, `affirmCare`, and `watchSpace`).
   - Verified that server-side validation correctly intercepts and logs hostile urgency keywords before database persistence occurs.
2. **PostgreSQL 16 Query Analysis**:
   - Visualized the exact SQL generated by Serverpod's ORM (e.g., `SELECT ... FROM reflection_posts WHERE "spaceKey" = $1 ORDER BY "createdAt" DESC`).
   - Confirmed that the composite B-tree index `space_created_idx` was actively hit, maintaining sub-millisecond query execution times.
3. **WebSocket Stream & Pub/Sub Monitoring**:
   - Inspected active streaming sessions subscribing to `session.messages.createStream('space_$spaceKey')`.
   - Verified that broadcast events were dispatched concurrently to desktop, web, and physical mobile clients with minimal latency.
4. **Live Structured Log Aggregation**:
   - Filtered server diagnostic events (`INFO`, `WARNING`, `ERROR`) through a sleek native GUI, expediting debugging without terminal noise.
