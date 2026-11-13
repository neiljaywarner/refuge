# Belong on the Spectrum — what's new since v0.9.9

Production is still **v0.9.9**. These notes describe what is on `main` and the dev site, in plain language, for the next production release. The technical list is [`CHANGELOG.md`](CHANGELOG.md). The same words, ready for the deploy highlights file, are in [`docs/release_highlights/unreleased-since-v0.9.9.md`](docs/release_highlights/unreleased-since-v0.9.9.md). The release checklist is [#937](https://github.com/neiljaywarner/refuge/issues/937).

## For members

- **Your phone's text size now changes Belong.** A larger system font grows the type in the app, together with the text size you pick in sensory settings. Sign-in, home, messages, and feedback were checked at several sizes. A few tight spots are still open: the feed can feel short, and some rows can clip on a phone. Call screens will get the same check after video calling lands.
- **Relate keeps a name this device already knows.** Press and hold Relate, and a person who related on this device stays listed when a later update only has the count. A phone opening the post for the first time, with only that count, can still show an empty list. This covers posts and comments.
- **Animated text on a post.** In the attach sheet, choose Animate Text, type a short phrase, and attach a styled text GIF. It works on the website, the Android web app, and an iPhone home-screen app. The result stays PG, motion stays calm, and the GIPHY credit stays visible.
- **A cleaner list of people you can message.** Someone who has left the member directory, or whose account is closed or banned, no longer shows up as a message recipient.
- **Honest notification settings on the web.** When the browser cannot offer push, the notification sheet says so.
- **Feedback is stored once.** If a feedback note is sent again after a hiccup, Belong keeps a single copy of that note.

## For organizers and contributors

These do not change what members see in the app.

- The partner wiki now shows Refuge as the platform and Belong as the first community, with a Circle.so scorecard and a 90-day playbook.
- When a free backend has to keep running with very little attention, the docs now prefer Supabase Free, because ordinary visits and requests count. The live member store is still Firestore.
- A sanitized November working-chat archive is in `docs/chat-transcripts/` for apprentices. It is not product documentation.
- Continuous integration now uses a newer Java setup action.

Video calling, guest join, and screen sharing are still open pull requests. They are preview-only. A production build keeps the sign-in wall.

### Paste-ready "what's new"

Larger phone text now changes Belong's type, together with the in-app size. Press and hold Relate to see a name this device already saved. A first visit that only has the count can still be blank. You can attach animated text from GIPHY on the website and the home-screen app. The message list skips people who left the directory or whose accounts are closed. On the web, notification settings say when push is unavailable.

There is no Play Store or App Store listing file in this repository. Listings are still pending.

---

## Historical: Sanctuary v0.1.0 hackathon prototype

The rest of this file is the Serverpod hackathon prototype note. It is not the current Belong release.

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
  * **Pixel Left**: Wi-Fi `192.168.4.46` / Cellular `192.0.0.4`
  * **Pixel Right**: Wi-Fi `192.168.4.45` / Cellular `192.0.0.4`
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
