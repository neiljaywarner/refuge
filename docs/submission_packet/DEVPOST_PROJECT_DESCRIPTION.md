### 🌟 What Refuge Does
Modern digital communities are weaponized for urgency: red badge counters, rapid notification pings, and algorithmic gamification induce chronic anxiety and sensory overload—especially for neurodivergent individuals and mindful fellowship groups.

**Refuge** is an unhurried, zero-badge, sensory-friendly community platform built with **Flutter** and **Serverpod 4**. Designed in partnership with the neurodivergent community ([Belong on the Spectrum](https://www.belongonthespectrum.com/)), Refuge provides a peaceful digital haven:
* **Zero-Badge Architecture**: No red notification dots, unread counters, or manipulative push urgency. Posts wait peacefully for you; you never chase them.
* **4 WCAG AAA Sensory Modes**: Instant cognitive comfort with *Sage Botanical*, *Clean Slate*, *Monastic Dark*, and *High Contrast* modes.
* **Calm-Tech Memes & Wholesome Fun**: Curated, low-stimulus meme gallery celebrating neurodivergent life and relatable humor without flashing strobe GIFs, external CDN lag, or ad trackers.
* **Mindful Intent Clarification**: Authors declare their intent before posting (*[Seeking Wisdom]*, *[Sharing Joy]*, *[Vulnerable Care]*, *[Special Interest Infodump]*), setting emotional context before words are read.
* **Qualitative Care Affirmations**: Replaces vanity "Likes" and emoji spam with meaningful communal care (*🙏 Standing With You*, *🤍 Caring Support*, *🕊️ Peace*, *🌱 Encouraged*).
* **Quiet Digest**: Server-computed aggregate peaceful summaries (*"Gathered in peace • 2 reflections shared with 35 care affirmations"*) instead of divisive engagement leaderboards.

---

### 🚀 How Refuge Uses Serverpod 4
Serverpod 4 provides our full-stack Dart backend running on **Serverpod Cloud** with PostgreSQL 16 and Redis 7:
1. **End-to-End Type Safety via Serverpod SPI**: Models (`ReflectionPost`, `QuietDigest`, `ReactionPayload`) are declared in `.spy.yaml` and compiled into shared Dart classes across server and client, eliminating JSON serialization drift.
2. **Real-Time WebSocket Streaming**: The `ReflectionEndpoint` leverages Serverpod's native streaming sessions and pub/sub message bus, broadcasting new reflections, meme cards, and atomic care reactions with sub-100ms latency.
3. **Calm-Tech API Filtering**: Serverpod endpoints enforce calm-tech principles at the gateway, filtering hostile urgency keywords (`asap`, `act now`, `urgent`) to safeguard community peace.
4. **Atomic Care Increments & Aggregations**: PostgreSQL atomic field increments handle simultaneous reactions without concurrency locks, while server endpoints compute holistic `QuietDigest` aggregates.
5. **Production Deployment**: Live and operational in the cloud at **[https://refuge4serverpod.api.serverpod.space](https://refuge4serverpod.api.serverpod.space)** and monitored via the **Serverpod Insights** macOS App.

---

### 🎨 How Refuge Uses Flutter
The frontend is a pure Flutter multi-platform application targeting Web, Android, iOS, and Desktop:
1. **CodeWithAndrea Riverpod Feature-First Architecture**: Structured cleanly into modular features (`features/reflections/`, `features/sensory_themes/`, `features/memes/`, `features/fellowship_spaces/`, `features/about/`) with strict separation of Data, Domain, and Presentation layers.
2. **Reactive State Management**: Powered by `flutter_riverpod` `ProviderContainer` providers and stream providers for seamless, declarative state synchronization.
3. **Resilient 800ms Offline-First Fallback**: If network connectivity fluctuates, the abstract `PostRepository` automatically detects dropped sockets and degrades gracefully to local seed storage within 800ms so members never face a broken screen or infinite loading spinner.
4. **Adaptive Material 3 Ergonomics**: Uncrowded, accessible layout with top-right sensory theme switcher and full theme controls in the About/Settings dialog.

---

### 🏆 Complete & Functional Proof of Delivery
* **Live Deployed Web App**: [https://refuge4serverpodhackathon.web.app](https://refuge4serverpodhackathon.web.app) (Firebase CDN with global SSL).
* **Live Serverpod Cloud API**: [https://refuge4serverpod.api.serverpod.space](https://refuge4serverpod.api.serverpod.space).
* **100% Automated Test Suite**: 26 unit, widget, BDD, and Riverpod architecture tests passing; 0 issues on `flutter analyze`.
* **Physical Hardware Validation**: Tested live on two physical Google Pixel 9a devices streaming reflections across real-world T-Mobile LTE cellular networks.
