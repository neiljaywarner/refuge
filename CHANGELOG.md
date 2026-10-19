# Changelog

All notable changes to **Refuge** (the calm-tech community platform anchored on **Belong on the Spectrum** — `belongonthespectrum.com`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased] — Target `v0.6.0` (Clean Circle-Style Shell & White-Label Foundation)
### Planned
- Extract white-label `CommunityBrandConfig` (defaulting to **Belong on the Spectrum** — `belongonthespectrum.com`, Psalm 139:14, custom spaces, and calm palette).
- Clean Circle.so-inspired layout polish for General (`#main-hall`) and Meme (`#special-interests-memes`) spaces.
- Integrate `bdd_widget_test` and Marionette live-driving harness.

---

## [0.5.0] - 2026-10-18 — Working Full-Stack Baseline & Apple Silicon (`arm64`) Environment
### Added
- **Full-Stack Serverpod 4 Cloud Architecture**:
  - Typed `.spy.yaml` protocol models (`ReflectionPost`, `QuietDigest`) with PostgreSQL persistence (`reflection_posts`) and Redis/WebSocket real-time streaming (`watchSpace`).
  - Server-side `getQuietDigest` aggregation and calm-tech urgency filtering (`publishReflection`, `affirmCare`).
  - **800ms Resilient Offline-First Fallback** in `ServerpodPostRepository` so web and mobile clients remain responsive even when offline.
- **Neurodivergent-Affirming Calm-Tech UI**:
  - **5 Fellowship Spaces**: `#prayer-sanctuary`, `#weekly-study`, `#announcements`, `#special-interests-memes`, and `#main-hall`.
  - **4 WCAG AAA/AA Sensory Modes**: Clean Slate, Sage Botanical, Monastic Dark, and High Contrast.
  - **Qualitative Care Affirmations**: `🙏 Praying`, `🤍 Standing With`, `🕊️ Peace`, `🌱 Encouraged`, and `🧩 Relatable`.
  - **Calm Meme Gallery Modal**: Curated Autism & Faith memes and special-interest tagging.
- **Apple Silicon (`arm64`) Development & Tri-Harness QA Environment (`#1`)**:
  - Migrated and bootstrapped native ARM64 toolchain (`flutter 3.47.7`, `serverpod_cli 4.0.4`, `serverpod_cloud_cli 1.1.0`, `adb 37.0.1`, `maestro`, `marionette_mcp 0.7.0`, `patrol_cli 4.8.0`, `patrol_mcp 0.2.1`, `dart mcp-server`, and 25 official Dart/Flutter skills).
  - Verified 26/26 passing unit, widget, and BDD feature tests (`flutter test` in 1s).
