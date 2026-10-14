# ❓ Serverpod Hackathon & Sanctuary FAQ
**Project**: Sanctuary (Refuge)  
**Hackathon**: Serverpod Global Hackathon (October 2026)  
**Last Updated**: Tuesday, October 14, 2026 at 12:10 AM CDT  

---

## 🧭 General & Product Philosophy FAQs

### Q1: What is Sanctuary in a single sentence?
**A**: Sanctuary is an unhurried, calm-tech digital fellowship platform designed with Flutter and Serverpod 4 for contemplative community, prayer, and authentic human care without dopamine-driven distractions.

### Q2: What exactly is "Calm Technology"?
**A**: Calm technology, a concept originally pioneered by Mark Weiser and John Seely Brown at Xerox PARC, asserts that technology should respect human attention rather than demanding it. In Sanctuary:
- There are **no red notification badges** or alarmist unread counts.
- There are **no typing indicators** ("... is typing") that force you to wait synchronously.
- There are **no read receipts** ("Seen at 10:14 PM") that induce guilt.
- There are **no algorithmic outrage sorting algorithms**; content is organized by human intentionality.

### Q3: Why not just use Discord, Slack, or WhatsApp?
**A**: Discord and Slack are designed for high-velocity workplace coordination or gaming chatter. WhatsApp and Facebook Groups are optimized for ad impressions and viral retention. In those apps, prayer requests and vulnerable life reflections compete against work messages, memes, and relentless notifications. Sanctuary is a dedicated, sacred space where the rhythm of interaction is inherently peaceful. (See our detailed [`docs/COMPETITOR_ANALYSIS.md`](file:///Users/neil/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/docs/COMPETITOR_ANALYSIS.md)).

### Q4: Can secular groups, recovery circles, or book clubs use Sanctuary?
**A**: Absolutely. While inspired by spiritual and faith-based fellowship, the architectural principles of Sanctuary apply directly to bereavement support groups, addiction recovery circles, poetry guilds, and any community that values intentional listening over rapid-fire chatting.

---

## ⚙️ Technical Architecture & Serverpod FAQs

### Q5: How is Serverpod 4 utilized in Sanctuary?
**A**: Serverpod 4 serves as the complete backend engine:
1. **Streaming Protocols**: Uses Serverpod streaming WebSockets for instantaneous real-time sync across desktop, web, and mobile clients.
2. **PostgreSQL Database & ORM**: Persists structured posts, space classifications, and qualitative reaction counters with zero SQL boilerplate.
3. **Type-Safe Protocol Definitions**: Defined via Serverpod SPI (`post.spy.yaml`, `reaction_payload.spy.yaml`), generating unified Dart models for both server and Flutter client.
4. **Redis Integration**: High-speed ephemeral cache and multi-server session broker.

### Q6: Can Sanctuary work offline?
**A**: Yes. Sanctuary utilizes an abstract `PostRepository` decoupling pattern. When the client is offline or disconnected, it seamlessly falls back to an in-memory cache without crashing or interrupting the user's reflection flow.

### Q7: Where can I see and try the live app?
**A**: Anyone can access our live production preview build deployed to Firebase CDN at:  
👉 **[https://ministry-demos--sanctuary-cnf3fnh7.web.app](https://ministry-demos--sanctuary-cnf3fnh7.web.app)**  
It works instantly on iPhone, Android, iPad, Mac, and Windows browsers without requiring any installation.

### Q8: What automated testing is in place?
**A**: The repository features an automated test suite executed via `flutter test`:
- 11 unit and widget tests covering immutable model updates, repository streaming, reaction increments, offline fallback, sensory theming, and fellowship space filtering.
- 100% test pass rate with zero warnings on `flutter analyze`.

---

## 🏆 Hackathon Judging & Submission FAQs

### Q9: Who is on the team?
**A**: Neil (Product Architecture, Video Presenter, and Engineering Direction) collaborating with an autonomous staff AI coding agent executing clean ticket-driven development, testing, and documentation.

### Q10: What are the key links for judging?
- **Public GitHub Repo**: [https://github.com/njwandroid/refuge_13oct_2026_prototype_for_serverpod_hackathon](https://github.com/njwandroid/refuge_13oct_2026_prototype_for_serverpod_hackathon)
- **Live Web Demo**: [https://ministry-demos--sanctuary-cnf3fnh7.web.app](https://ministry-demos--sanctuary-cnf3fnh7.web.app)
- **Master Submission Checklist**: [`docs/submission_packet/CHECKLIST.md`](file:///Users/neil/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/docs/submission_packet/CHECKLIST.md)
- **Video Script**: [`docs/submission_packet/VIDEO_SCRIPT_AND_STORYBOARD.md`](file:///Users/neil/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/docs/submission_packet/VIDEO_SCRIPT_AND_STORYBOARD.md)
- **Architecture Records**: [`docs/adr/`](file:///Users/neil/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/docs/adr/)
- **Team Wiki**: [`docs/wiki/`](file:///Users/neil/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/docs/wiki/)
