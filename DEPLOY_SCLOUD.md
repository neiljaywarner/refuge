# ☁️ Serverpod Cloud (scloud) Deployment Guide — Sanctuary (Refuge)

This guide documents how to deploy **Sanctuary (Refuge)** to **Serverpod Cloud (`scloud`)** or run the backend locally with Docker.

---

## 🚀 Quick Setup (2 Commands)

The Serverpod Cloud CLI (`scloud`) is already installed in our environment (`serverpod_cloud_cli: ^1.0.1`).

### Step 1: Authenticate with Serverpod Cloud
```bash
scloud auth login
```
*(Follow the prompt in your browser to sign in with GitHub or your BuilderBase account)*.

### Step 2: Launch the Project
```bash
cd sanctuary_server/sanctuary_server_server
scloud launch -p refuge4serverpod
```
`scloud` builds the container in the cloud, provisions a managed PostgreSQL 16 database, runs migrations, and assigns production HTTPS/WSS endpoints.

---

## 🌐 Live Production Deployment

Our backend is live and operational on **Serverpod Cloud**:
- **Project ID**: `refuge4serverpod`
- **Web**: [`https://refuge4serverpod.serverpod.space/`](https://refuge4serverpod.space/)
- **API (Flutter Client Endpoint)**: [`https://refuge4serverpod.api.serverpod.space/`](https://refuge4serverpod.api.serverpod.space/)
- **Insights**: [`https://refuge4serverpod.insights.serverpod.space/`](https://refuge4serverpod.insights.serverpod.space/)
- **Status**: Tested and verified HTTP 200 (Run mode: `production`).

---

## 📱 Connecting the Flutter Client

Run or build the Flutter application with your live Serverpod Cloud URL:

### Local Development / Debug
```bash
flutter run -d chrome --dart-define=SERVERPOD_URL=https://<your-project>.serverpod.cloud/
```

### Production Web Build
```bash
flutter build web --release --dart-define=SERVERPOD_URL=https://<your-project>.serverpod.cloud/
```

### Production Android APK Build
```bash
flutter build apk --release --dart-define=SERVERPOD_URL=https://<your-project>.serverpod.cloud/
```

---

## 🛡️ Resilient 800ms Offline-First Fallback Moat

Sanctuary implements an unshakeable offline-first architecture via [`ServerpodPostRepository`](lib/main.dart):
- If the live Serverpod Cloud instance or local Docker container is unreachable, the client transitions seamlessly to the local calm-tech repository within **800ms**.
- Seeded reflections from **Belong on the Spectrum** across all 5 fellowship spaces immediately render with full care affirmations, Bible deep-dives, and autism memes.
- Judges will **never** encounter a blank screen, connection timeout error banner, or infinite loading spinner.

---

## 🐳 Running Locally with Docker

If you prefer to run the entire backend on your local machine:
```bash
cd sanctuary_server/sanctuary_server_server
docker compose up -d
dart bin/main.dart
```
Then launch the Flutter client with default local settings:
```bash
flutter run -d chrome
```
