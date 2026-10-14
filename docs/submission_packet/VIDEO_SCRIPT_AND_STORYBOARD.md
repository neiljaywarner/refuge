# 🎬 Serverpod Hackathon Demo Video — Script & Storyboard
**Target Length**: 2 Minutes 15 Seconds (Max 2:45)  
**Resolution**: 1080p (60fps) or 4K  
**Presenter**: Neil / Voiceover Collaborator  
**Last Updated**: Tuesday, October 14, 2026 at 12:07 AM CDT  

---

## 💡 Director's Guidelines for Delivery
- **Tone**: Grounded, calm, intentional, and articulate. Avoid fast tech-hustle jargon or loud background music.
- **Background Music**: Low-volume ambient acoustic guitar or soft piano (3-5% volume).
- **Screen Layout**: For the live demo portion, show **two windows side-by-side**: macOS Desktop Client on the left, Chrome/Web Client on the right to visually demonstrate real-time Serverpod streaming.

---

## ⏱️ Second-by-Second Storyboard & Voiceover Script

### Act I: The Hook & The Problem (0:00 – 0:30)
| Timecode | On-Screen Visual | Audio Voiceover Script |
| :--- | :--- | :--- |
| **0:00 – 0:10** | Title card: *Sanctuary — Calm-Tech Fellowship for Serverpod Hackathon*. Transition to rapid montage of red notification badges, Discord pings, and algorithmic social feeds. | *"Modern communication platforms are engineered for urgency. Red badges, unread counters, and dopamine loops keep our minds constantly frazzled—even in spaces meant for spiritual reflection and deep community."* |
| **0:10 – 0:25** | Cut to the tranquil, clean Sanctuary UI in **Sage Mode**. The feed is still, organic, and readable. | *"We asked ourselves: What if fellowship software was designed around peace instead of panic? Introducing Sanctuary—a calm-tech platform engineered specifically for intentional, unhurried fellowship."* |
| **0:25 – 0:30** | Quick logo and subtitle: *Built with Flutter & Serverpod 4*. | *"Built from the ground up using Flutter on the client and Serverpod 4 on the backend."* |

---

### Act II: Calm-Tech Core Features in Action (0:30 – 1:15)
| Timecode | On-Screen Visual | Audio Voiceover Script |
| :--- | :--- | :--- |
| **0:30 – 0:45** | Cursor selects the Sensory Theme dropdown: switches from Sage to **Monastic Dark**, then to **Clean Slate**, then **High Contrast**. | *"Sanctuary respects your cognitive load. Our Sensory Modes include botanical Sage, daylight Clean Slate, nocturnal Monastic Dark, and AAA-accessible High Contrast. Notice what's missing: zero red badges, zero alert counters, and zero manipulative urgency."* |
| **0:45 – 1:00** | Clicking through Fellowship Spaces: Main Hall, Quiet Room, Prayer & Care, Gratitude Journal. | *"Communities gather in dedicated Spaces—from contemplative silence in the Quiet Room to intercession in Prayer & Care. Every post is anchored by an Intent Tag, setting expectations before words are even read."* |
| **1:00 – 1:15** | Composing a reflection: *"Quiet morning meditation on Psalm 23"*, selecting tag *"Contemplative Reflection"*, clicking Publish. Tapping *"🙏 Praying"* and *"🕊️ Peace"*. | *"Instead of gamified 'Likes' or flame wars, Sanctuary offers qualitative affirmations—'Praying', 'Standing With', 'Peace', and 'Encouraged'. Care is conveyed without turning human connection into a popularity contest."* |

---

### Act III: The Serverpod 4 Streaming Engine (1:15 – 1:50)
| Timecode | On-Screen Visual | Audio Voiceover Script |
| :--- | :--- | :--- |
| **1:15 – 1:35** | **Side-by-side view**: Left window is macOS Desktop; Right window is live Chrome Web Demo. Presenter creates a post on macOS. Immediately, it glides into the Chrome window in real time without refreshing. Presenter clicks "🙏 Praying" on Web, count increments on macOS. | *"Under the hood, Sanctuary is powered by Serverpod 4. Using Serverpod's streaming WebSocket protocols and PostgreSQL database, reflections and care reactions sync instantaneously across platforms—from desktop to web to mobile—with type-safe Dart models end-to-end."* |
| **1:35 – 1:50** | Quick 5-second cut to clean code: `PostRepository` contract, Serverpod `post.spy.yaml`, and terminal showing `flutter test` passing 11/11 tests. | *"Our architecture decouples data access through an abstract repository pattern with runtime backend switching, backed by rigorous automated tests and Dockerized Postgres and Redis."* |

---

### Act IV: The Vision & Closing (1:50 – 2:15)
| Timecode | On-Screen Visual | Audio Voiceover Script |
| :--- | :--- | :--- |
| **1:50 – 2:05** | Cut back to the full-screen Sanctuary app in Sage mode. Screen displays live URL: `ministry-demos--sanctuary-cnf3fnh7.web.app` and GitHub repo link. | *"Sanctuary is already deployed and live on the web right now. You can test it yourself on mobile or desktop, review our open-source codebase, and experience fellowship that restores your soul rather than draining your battery."* |
| **2:05 – 2:15** | Closing slide: *Sanctuary — Quiet Fellowship in an Anxious World. Thank you Serverpod team!* | *"Thank you to the Serverpod team for empowering Dart developers to build beautiful, full-stack experiences. We are Sanctuary."* |

---

## 🛠️ Recording Setup Recommendations
1. **Screen Capture Software**:
   - macOS QuickTime (`File > New Screen Recording`) or OBS Studio (Canvas: 1920x1080).
2. **Audio Setup**:
   - USB Microphone (Blue Yeti, Rode, or AirPods with Voice Isolation enabled in macOS Control Center).
3. **Browser Window**:
   - Open Chrome to `https://ministry-demos--sanctuary-cnf3fnh7.web.app` in 100% zoom (not full screen, sized to half screen width).
4. **Desktop App**:
   - Run `flutter run -d macos` sized to the other half of the screen.
