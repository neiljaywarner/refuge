# ⚡ Serverpod Architecture Deep Dive (Historical Archive)

> [!NOTE]
> **Historical Archive Document**: This document captures the initial Serverpod 4 and PostgreSQL/Redis backend evaluation. For the 20-day teardown and \$0/mo cost-saving plan, see [`Serverpod-Deprecation-and-Teardown-Guide`](Serverpod-Deprecation-and-Teardown-Guide). For current production backend architecture, see [`Backend-and-Database-Architecture`](Backend-and-Database-Architecture) and [`Backend-Migration-Strategy-Serverpod-Appwrite-Firebase`](Backend-Migration-Strategy-Serverpod-Appwrite-Firebase).

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
```
