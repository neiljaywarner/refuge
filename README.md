# ♾️ Refuge — Powering Belong on the Spectrum

> *"I praise you because I am fearfully and wonderfully made."* — **Psalm 139:14**  
> **First Community**: **[Belong on the Spectrum](https://www.belongonthespectrum.com/)** (partnered with **[DFW Church](https://dfwchurch.org)**)  
> **Circle.so Cutover Target**: **Saturday, October 31, 2026**

---

## 🌟 About Belong on the Spectrum & Refuge

**Refuge** is an open, white-labelable, calm-technology community platform built with **Flutter** and **Serverpod** as a sensory-friendly, cost-effective replacement for Circle.so.

Its flagship community is **[Belong on the Spectrum](https://www.belongonthespectrum.com/)** — a welcoming Christian & neurodivergent/autistic fellowship community.

### Key Features
- **Familiar Circle.so-Style Navigation**:
  - **Top Bar**: Official **Belong** cross & gold neurodiversity infinity (`∞`) logo in the upper-left, Sensory Theme switcher + **Member Profile Avatar** in the upper-right, and **`Feed`** | **`Spaces`** selector below the logo.
  - **Spaces Hierarchy**:
    - 📌 **Pinned**: `General Chat`
    - 👋 **Welcome**: `Start Here & Introduce Yourself`, `Announcements`
    - 🤝 **Community**: `General Chat`, `Memes`, `Online Resources / Videos`, `Actually Autistic Chat`, `Friends Chat`, `Family Chat`
    - 📅 **Actually Autistic**: `Actually Autistic Events`
    - 🔗 **Links**: `Community Guidelines`, `DFW Church` (`dfwchurch.org`), `Download the Android App`, `Download the iOS App`
  - **4-Tab Bottom Navigation Bar**: `Home`, `Notifications`, `Msgs`, and `Search`.
- **Non-Technical Organizer Control (`Firebase Remote Config`)**:
  - Community organizers can update the **"Message from the Organizer"** welcome card, announcements, and store links anytime from the Firebase Console without code changes.
- **4 Neurodivergent-Affirming Sensory Themes (WCAG AAA)**:
  - *High Clarity*, *Warm Calm*, *Low Stimulus Dark*, and *Low Motion* (zero surprise pop-ups or auto-playing media).
- **Multi-Environment Flavor Isolation (`dev` vs `prod`)**:
  - Built using the **CodeWithAndrea (`codewithandrea.com`) Feature-First Layered Architecture** (`presentation` / `application` / `domain` / `data`) + **`hooks_riverpod`** (`HookConsumerWidget`).

---

## 📚 Documentation & Wiki Portals (`docs/wiki/`)

| Guide | Audience | Description |
| :--- | :--- | :--- |
| **[📅 Oct 31 Circle.so Cutover Schedule](docs/wiki/Non-Technical-Roadmap-to-Oct-31.md)** | **Organizers & Pastors** | Plain-English day-by-day schedule from Oct 18 to Oct 31, 2026 (final day of Circle.so subscription). |
| **[📣 Organizer Remote Config Guide](docs/wiki/Organizer-Remote-Config-Guide.md)** | **Organizers & Leaders** | How to edit the *"Message from the Organizer"* banner without needing a developer. |
| **[📱 PWA & App Store Guide](docs/wiki/PWA-Guide-for-Members-and-Organizers.md)** | **Members & Organizers** | How members install Belong to their iPhone/Android Home Screen in 10 seconds, and how long we can run on the PWA before needing Google Play & the Apple App Store. |
| **[🤝 Contributor Guide](docs/wiki/Contributor-Guide.md)** | **Volunteers & Developers** | How to contribute via Ticket-Driven Development (`1 Issue = 1 Worktree = 1 PR`). |
| **[🎓 Student, Mentee & Apprentice Guide](docs/wiki/Apprentice-and-Token-Optimization-Guide.md)** | **Students & Mentees** | Clean architecture walkthrough, BDD testing, pure-Dart CLI tools (`tool/refuge_cli.dart`), and **Free-Tier AI Token Optimization**. |

---

## 🛠️ Quick Start for Developers & Mentees

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis & BDD/widget test suite
dart analyze
flutter test

# 3. Launch in Chrome (or connected Pixel 9a)
flutter run -d chrome
```
