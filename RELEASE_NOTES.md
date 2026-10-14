# 🕊️ Sanctuary v0.1.0 — Belong on the Spectrum
### *Official Prototype Release for the Serverpod Hackathon 2026*
**Anchor Community**: [Belong on the Spectrum](https://www.belongonthespectrum.com/)  
*"I praise you because I am fearfully and wonderfully made; your works are wonderful, I know that full well."* — **Psalm 139:14**

---

## 🌟 What is Sanctuary?
Sanctuary (Refuge) is a calm-tech digital community platform engineered with **Flutter** and **Serverpod 4**. It was specifically designed for **Belong on the Spectrum**, a community created by and for Autistic Disciples of Jesus and their allies.

Mainstream community platforms (such as Circle, Mighty Networks, and Discord) charge small faith-based non-profits **$89–$130/month ($1,000+ per year)** and bombard neurodivergent believers with red notification badges, dopamine-driven engagement loops, and sensory overload. Sanctuary replaces this high cost with efficient, low-cost Serverpod compute while delivering an unhurried, peaceful refuge.

---

## 🚀 Key Highlights & What's New in v0.1.0

### 1. Full-Stack Serverpod 4 Architecture
* **Typed Protocols**: Defined via `.spy.yaml` schemas for `ReflectionPost` and `QuietDigest`.
* **Server-Side Aggregations**: `getQuietDigest` endpoint computes total reflections, qualitative care affirmations, and featured God-given special interests without tracking vanity metrics.
* **Calm-Tech Urgency Filtering**: Serverpod endpoint rejects manipulative urgency keywords (`asap`, `urgent`, `act now`, `click here`) to protect nervous systems.
* **Atomic Qualitative Care**: Replaces vanity "Likes" with meaningful affirmations (`🙏 Praying`, `🤍 Standing With`, `🕊️ Peace`, `🌱 Encouraged`, `🧩 Relatable`).
* **Real-Time Streaming**: Serverpod `session.messages` WebSocket streams keep spaces synchronized in real-time.
* **Resilient 800ms Offline-First Fallback**: If internet connectivity is interrupted, the Flutter client gracefully transitions to local seeded fellowship data within 800ms.

### 2. Dual Pixel 9a Live Cloud Demonstration
* Verified live across two physical Google Pixel 9a devices running on **T-Mobile LTE** communicating over **Serverpod Cloud**:
  * **Pixel Left (`56091JEBF14039`)**: Wi-Fi `192.168.4.46` / Cellular `192.0.0.4`
  * **Pixel Right (`58221JEBF20835`)**: Wi-Fi `192.168.4.45` / Cellular `192.0.0.4`
* Screen recordings captured via `adb screenrecord` demonstrate synchronized post publication, tone-tagging, qualitative reactions, and sensory theme toggles.

### 3. Neurodivergent-Affirming Craft & Sensory Comfort
* **4 WCAG AAA Sensory Modes**: Sage Botanical (calming green), Clean Slate (minimalist white), Monastic Dark (low blue-light night mode), High Contrast (high readability).
* **5 Dedicated Fellowship Spaces**: `#prayer-sanctuary`, `#weekly-study`, `#special-interests`, `#fellowship-hall`, and `#quiet-reflections`.
* **Autism & Faith Memes & Special Interests**: Dedicated tagging for infodumps, special interests, and humor that celebrates how God fearfully and wonderfully made each member.
* **About Sanctuary Dialog**: In-app dialog featuring release details, Psalm 139:14, and grateful appreciation to **Serverpod** and **BuilderBase**.

---

## 🌐 Live Deployments & Verification

* **Web Application**: [`https://refuge4serverpodhackathon.web.app`](https://refuge4serverpodhackathon.web.app)
* **Serverpod Cloud API**: [`https://refuge4serverpod.api.serverpod.space/`](https://refuge4serverpod.api.serverpod.space/)
* **Serverpod Cloud Web**: [`https://refuge4serverpod.serverpod.space/`](https://refuge4serverpod.serverpod.space/)
* **Serverpod Insights**: [`https://refuge4serverpod.insights.serverpod.space/`](https://refuge4serverpod.insights.serverpod.space/)
* **Android Release APK**: `sanctuary-belong-v0.1.0.apk` (packaged in this release)

---

## 🧪 Comprehensive Test Suite
* **20 / 20 Tests Passing**:
  * Unit tests (`PostModel`, `LocalPostRepository`, `ServerpodPostRepository`)
  * Widget tests (Theme switching, space switching, composer reset, filtering)
  * Human-readable BDD Feature tests (`bdd_features_test.dart`)
* **0 Analyzer Warnings**: Clean `flutter analyze` and `dart analyze`.

---

## 🙏 Credits & Acknowledgments
* **Belong on the Spectrum** ([`belongonthespectrum.com`](https://www.belongonthespectrum.com/))
* **Serverpod Team & Community** ([`serverpod.dev`](https://serverpod.dev/))
* **BuilderBase** for hosting the hackathon and enabling calm-tech development.
