# 💼 Resume & Engineering Showcase: Principal Full-Stack Dart Architecture

> **Engineering Leadership Overview**:
> * **Role**: Lead Architect & Principal Full-Stack Engineer
> * **Project**: Sanctuary (Refuge) — Calm-Tech Digital Community Platform
> * **Core Technologies**: Dart 3.13, Flutter 3, Serverpod 4 (`^4.0.4`), PostgreSQL 16, Redis 7, Serverpod Cloud (`scloud`), Docker, WebSockets, ADB Hardware Automation, BDD Testing.
> * **Deliverables**: Live Web App, Live Serverpod Cloud Backend, Android Release APK, 20/20 Test Suite, Dual-Device Hardware Video Verification.

---

## 🎯 Executive Engineering Summary

Sanctuary is a production-grade demonstration of **full-stack unified Dart architecture**, replacing costly, fragmented legacy community platforms with an integrated, typed, low-latency solution.

As lead architect, Neil Warner designed and executed the entire system lifecycle:
1. **Business & Unit Economics**: Eliminated a **~$1,500/year ($130/month)** SaaS overhead for a faith-based non-profit ([Belong on the Spectrum](https://www.belongonthespectrum.com/)), replacing it with a self-hostable Serverpod 4 compute stack costing **<$5/month** (a **96% operating cost reduction**).
2. **End-to-End Type Safety**: Shared Dart models between Flutter multi-platform clients and Serverpod cloud servers via Serverpod SPI (`.spy.yaml`), eliminating JSON serialization boilerplate and client-server drift.
3. **Resilient Offline-First Architecture**: Engineered an unshakeable 800ms fallback moat ensuring zero user-facing crash or error states during connectivity fluctuations.
4. **Physical Device Test Automation**: Built an automated hardware verification harness driving two real Google Pixel 9a smartphones communicating live over T-Mobile LTE.

---

## 🏗️ Architectural Highlights & Innovations

### 1. Unified Dart 3 Ecosystem (Client to Cloud)
* **Single Language Advantage**: Avoided language-context switching between TypeScript/Go and Dart by running 100% Dart across frontend, backend, test suites, and scripts.
* **Shared Serialization & Models**:
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
  ```
  Generated code guarantees compile-time type safety across database queries, network payloads, and UI bindings.

### 2. High-Performance Serverpod 4 Backend Engine
* **PostgreSQL 16 Persistence with Composite Indexing**:
  Configured composite B-tree index `space_created_idx` over `(spaceKey, createdAt)` for high-throughput, low-latency space filtering.
* **Calm-Tech Urgency Filtering**:
  Implemented custom server-side validation to reject hostile, dopamine-inducing urgency keywords (`urgent`, `asap`, `click here`, `act now`), protecting neurodivergent members' cognitive peace at the API gateway layer.
* **Atomic Qualitative Care Affirmations**:
  Replaced high-overhead optimistic locks with atomic SQL field increments (`praying`, `standingWith`, `peace`, `encouraged`, `relatable`).
* **Real-Time WebSocket Streaming**:
  Integrated `session.messages` pub/sub engine for sub-100ms real-time event dissemination across connected clients without polling.
* **Server-Side Aggregation (`QuietDigest`)**:
  Calculates holistic community posture without tracking or displaying anxiety-inducing vanity follower metrics.

### 3. Resilient 800ms Offline-First Fallback Moat
To support users in rural retreats or low-connectivity zones, the Flutter repository layer implements an unshakeable resilience strategy:
```dart
@override
Stream<List<Post>> watchPosts({required String spaceKey}) async* {
  // 1. Instantly yield local fallback so user never sees a blank screen
  yield await _fallback.getPosts(spaceKey: spaceKey);

  // 2. Try to connect to Serverpod streaming endpoint with 800ms timeout
  try {
    final stream = _client.reflection
        .watchSpace(_mapSpaceKey(spaceKey))
        .timeout(const Duration(milliseconds: 800));

    await for (final spPost in stream) {
      // Yield live updates
    }
  } catch (_) {
    // 3. Seamlessly degrade to seeded local stream
    yield* _fallback.watchPosts(spaceKey: spaceKey);
  }
}
```

### 4. Hardware-Level Verification & Dual-Pixel ADB Automation
Unlike projects tested solely on emulators or mocked environments, Sanctuary was tested and recorded live on physical production hardware:
* **Test Fleet**: Two physical **Google Pixel 9a** devices (`56091JEBF14039` & `58221JEBF20835`).
* **Real Network Topology**: Both devices connected over **T-Mobile LTE** mobile networks.
* **Orchestration**: Automated shell scripts driving simultaneous `adb screenrecord`, UI input injection, theme toggles, and cross-device communication verification.

---

## 📊 Rigorous Quality & Ticket-Driven Delivery

* **Conventional Commits & Clean PR Flow**: 8 completed pull requests (#8 through #15) linked to issues #1 through #7.
* **Zero Analyzer Warnings**: Strict adherence to Effective Dart guidelines; 0 issues on `flutter analyze` and `dart analyze`.
* **20 / 20 Test Coverage**:
  * Unit tests covering post modeling, immutability, and atomic reactions.
  * Widget tests verifying theme propagation, space navigation, and composer reset.
  * BDD feature tests verifying human-readable acceptance scenarios.

---

## 🛠️ Technical Competency Matrix

| Domain | Competencies Demonstrated |
| :--- | :--- |
| **Frontend Architecture** | Flutter 3, Material 3, Adaptive Layouts, Custom State Management, WCAG AAA Accessibility. |
| **Backend Engineering** | Serverpod 4, Dart Server CLI, RPC Endpoints, WebSocket Streams, Relic HTTP, Redis 7. |
| **Database Design** | PostgreSQL 16, Relational Modeling, Composite Indexing, Database Migrations, Schema Versioning. |
| **Cloud & DevOps** | Serverpod Cloud (`scloud`), Docker Containerization, Firebase Hosting, SSL/TLS, CI/CD. |
| **Mobile Hardware** | Android SDK, ADB Shell Automation, Video Screen Recording, Native Device Profiling. |
| **Quality Engineering** | Test-Driven Development (TDD), Behavior-Driven Development (BDD), Unit & Widget Testing. |
| **Product Leadership** | Calm-Tech Design, Sensory Accommodation, Cost Engineering, Non-Profit Solution Architecture. |
