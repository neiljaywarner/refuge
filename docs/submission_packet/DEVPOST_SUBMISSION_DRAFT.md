# 📝 Devpost Hackathon Submission Draft
**Project Name**: Sanctuary (Refuge) — Calm-Tech Fellowship
**Tagline**: An unhurried, zero-badge fellowship platform built with Flutter and Serverpod 4.
**Last Updated**: Tuesday, October 14, 2026 at 12:08 AM CDT

---

## 🌟 Elevator Pitch
Modern communication software is weaponized for urgency—red badges, unread counts, and engagement dopamine loops induce anxiety. **Sanctuary** is a calm-tech fellowship platform built with Flutter and Serverpod 4 designed specifically for unhurried reflection, spiritual care, and intentional community. Featuring sensory accessibility modes, qualitative care reactions, and real-time Serverpod streaming, Sanctuary restores peace to digital fellowship.

---

## 🕊️ Inspiration
Every major group communication app—from Discord and Slack to WhatsApp and Facebook Groups—was designed for high-frequency workplace collaboration or ad-driven viral retention. When faith communities, prayer circles, and support groups gather on these platforms, they inherit the anxiety of notifications, unread counters, and dopamine gamification. 

We asked ourselves: **What would a platform look like if its primary goal was human peace and genuine spiritual care?** We wanted to build a sanctuary—a digital space where people could breathe, share vulnerable reflections without fear of algorithmic ranking, and support one another in stillness. Serverpod 4's high-performance Dart backend and streaming capabilities gave us the perfect full-stack foundation to bring this calm vision to life.

---

## 💡 What It Does
- **Sensory & Cognitive Modes**: 4 curated themes tailored to cognitive comfort—*Sage Botanical*, *Clean Slate*, *Monastic Dark*, and *High Contrast* (WCAG AAA compliant).
- **Zero-Badge Architecture**: No red notification dots, no unread badge counters, and no manipulative urgency. Content waits patiently for you; you never chase it.
- **Fellowship Spaces**: Dedicated environments with tailored rhythms—from contemplative silence in the *Quiet Room* to intercessory support in *Prayer & Care*, and thanksgiving in the *Gratitude Journal*.
- **Intent-Driven Posting**: Authors declare their intent before posting (*Seeking Wisdom*, *Sharing Joy*, *Vulnerable Care*, *Quiet Reflection*), establishing emotional context before words are read.
- **Qualitative Care Reactions**: Replaces vanity "Likes" and emoji spam with meaningful affirmations: *🙏 Praying*, *🤍 Standing With*, *🕊️ Peace*, and *🌱 Encouraged*.
- **Real-Time Streaming**: Reflections and reactions sync instantaneously across platforms using Serverpod 4 WebSocket streaming protocol.

---

## 🛠️ How We Built It
- **Frontend (Flutter Multi-Platform)**: Built with pure Flutter, targeting Web, macOS desktop, iOS, and Android with responsive adaptive layouts. Single-file runnable architecture with strict separation of concerns.
- **Backend (Serverpod 4)**: 
  - Protocol models defined via Serverpod SPI (`post.spy.yaml`, `reaction_payload.spy.yaml`).
  - Streaming endpoint (`post_endpoint.dart`) using Serverpod streaming WebSocket sessions for real-time broadcasts.
  - PostgreSQL 16 database running via Docker Desktop with native Serverpod migrations.
  - Redis 7 caching & session synchronization.
- **Architecture**: Strict abstract `PostRepository` contract with runtime backend switching (`--dart-define=BACKEND=serverpod` / `local`) and offline-first fallback.
- **Testing & Quality Gate**: 11 unit and widget tests passing in 4 seconds; 0 warnings on `flutter analyze`.
- **Live Deployment**: Live web build hosted on Firebase CDN with global SSL and instant preview channels.

---

## 🧗 Challenges We Ran Into
1. **Calm-Tech vs. Real-Time Paradox**: Real-time streaming often translates to intrusive "Someone is typing..." badges and popping animations. Designing a real-time Serverpod streaming protocol that delivers updates smoothly without inducing urgency required thoughtful UX restraint.
2. **Dart Broadcast Stream Lifecycle**: When using broadcast stream controllers for reactive UI, late-subscribing widgets could miss initial data. We solved this by using Dart `async*` generator streams that yield the in-memory cache immediately before forwarding real-time events.
3. **Seamless Offline Fallback**: To support contemplative use in low-connectivity retreats, we engineered the client repository to degrade gracefully from Serverpod WebSockets to an in-memory repository without breaking the UI.

---

## 🏆 Accomplishments We're Proud Of
- **Zero Analyzer Warnings**: Complete clean static analysis across the entire project (`flutter analyze`).
- **Comprehensive Automated Testing**: 11 unit and widget tests covering models, repositories, and UI flows with 100% pass rate.
- **Live Deployed Prototype**: Working public web application deployed and verified on Firebase CDN ([Demo Link](https://ministry-demos--sanctuary-cnf3fnh7.web.app)).
- **Comprehensive Architecture Documentation**: 4 Architecture Decision Records (ADRs) and a full Non-Technical Team Wiki.
- **True Calm-Tech Feat**: Successfully eliminating every notification counter while maintaining engaging, deep communal connection.

---

## 📚 What We Learned
- Serverpod 4's unified Dart ecosystem dramatically accelerates full-stack development by eliminating JSON boilerplate and type mismatches between client and server.
- Calm technology isn't about doing less; it requires rigorous intentionality to omit deceptive design patterns that modern developers take for granted.

---

## 🚀 What's Next for Sanctuary
- **Gemini 3.8 Tone Harmony**: An optional AI reflection companion that helps users ensure their words foster peace and avoid unintentional hostility before posting.
- **Voice Reflections & Meditative Chimes**: Audio reflections with gentle haptic resonance for prayer moments.
- **Decentralized Ministry Pods**: Allowing individual churches, non-profits, and communities to self-host their own Serverpod Sanctuary instances with full data sovereignty.

---

## 🏷️ Built With
- `flutter`
- `dart`
- `serverpod`
- `postgresql`
- `docker`
- `redis`
- `websockets`
- `firebase-hosting`
