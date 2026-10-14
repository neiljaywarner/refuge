# 🌿 Sanctuary (Refuge) v0.1.0 Release Notes

> **Official Serverpod Hackathon v0.1.0 MVP Release**  
> 🔗 **Live Web App**: [https://refuge4serverpodhackathon.web.app](https://refuge4serverpodhackathon.web.app)  
> 🌐 **Alternative CDN**: [https://ministry-demos--sanctuary-cnf3fnh7.web.app](https://ministry-demos--sanctuary-cnf3fnh7.web.app)  
> 🎬 **Demo Video**: Attached to this release (`sanctuary_v01_walk_demo.mp4`)  
> 📱 **Android APK**: Attached to this release (`app-debug.apk`)  
> 🧩 **Spiritual & Community Anchor**: [Belong on the Spectrum](https://www.belongonthespectrum.com/)

---

## 🌟 What is Sanctuary?
Sanctuary is a full-stack calm-tech fellowship platform built with **Flutter 3** and **Serverpod 4** for neurodivergent church fellowships, Christian communities, and support circles.

It solves two critical problems:
1. **High SaaS Overhead**: Replaces expensive legacy corporate community SaaS platforms ($130/month or $1,560/year) with a self-hostable Serverpod 4 backend running for <$5/month.
2. **Sensory & Emotional Overload**: Eliminates anxiety-inducing red notification badges, public like counts, and algorithmic outrage loops in favor of peaceful, unhurried reflection.

---

## 🚀 Key Features in v0.1.0

### 1. Serverpod 4 Full-Stack Architecture
- **Protocol Models (`.spy.yaml`)**:
  - `ReflectionPost`: Mapped directly to PostgreSQL table `reflection_posts` with composite index `space_created_idx` over `spaceKey, createdAt`.
  - `QuietDigest`: Server-side aggregation payload.
- **Endpoints Doing Real Backend Work (`ReflectionEndpoint`)**:
  - `publishReflection`: Validates content length and calm-tech tone, sets UTC timestamps, and saves via `ReflectionPost.db.insertRow(session, post)`.
  - `affirmCare`: Atomic increment of qualitative care reactions in PostgreSQL via `ReflectionPost.db.updateRow`.
  - `watchSpace`: Real-time WebSocket session streams via `session.messages.createStream<ReflectionPost>('space_$spaceKey')`.
  - `getQuietDigest`: Server-side domain computation calculating total reflections, care affirmation sums, and predominant intent.

### 2. Calm-Tech & Neurodivergent Accessibility
- **4 WCAG Sensory Modes**:
  - 🌿 **Sage** (`#4A6B5D`): Soothing natural green for everyday visual grounding.
  - ⚪ **Clean Slate** (`#FFFFFF`): High-clarity white for daylight reading.
  - 🕯️ **Monastic Dark** (`#1A1C1B`): Subdued charcoal and deep forest tones for insomnia and night prayer.
  - ⚡ **High Contrast** (`#000000` / `#FFFF00`): Maximum contrast yellow-on-black for low vision and neurodivergent clarity.
- **Fellowship Rooms**:
  - `🌿 Main Hall` (`main_hall`)
  - `🕯️ Quiet Room` (`quiet_room`)
  - `🕊️ Prayer & Care` (`prayer_care`)
  - `📖 Gratitude Journal` (`gratitude`)
- **Qualitative Care Reactions (No Dopamine Traps)**:
  - `🙏 Praying`, `🤍 Standing With`, `🕊️ Peace`, `🌱 Encouraged`
- **Mindful Intent Tags**:
  - `Seeking Wisdom`, `Giving Thanks`, `Vulnerable Sharing`, `Quiet Reflection`

### 3. Resilience & Quality Assurance
- **800ms Resilient Fallback**: Automatically connects to local/remote Serverpod instances, but falls back gracefully within 800ms to offline-cached data so judges and users on web or mobile never experience a blank screen or broken loader.
- **11/11 Automated Tests Passing**: Comprehensive unit and widget tests covering immutability, stream updates, space switching, sensory theming, and reaction mutations.
- **0 Analyzer Warnings**: Analyzed cleanly across Dart 3 and Flutter 3.

---

## 📦 Release Artifacts
- `app-debug.apk`: Android standalone package.
- `sanctuary_v01_walk_demo.mp4`: Native iOS Simulator walk-through demo video.
