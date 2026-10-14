# 📋 Product Requirements Document (PRD)

**Product Name**: Sanctuary (Refuge) — Calm-Tech Fellowship Clubhouse  
**Version**: 1.0 (Hackathon Edition)  
**Status**: Active / In Development  
**Author**: Antigravity Staff Systems Team  

---

## 1. Problem Statement & Mission

Modern social platforms drive addictive behaviors through red badges, rapid-fire chat indicators, and algorithmic outrage. Communities centered around prayer, spiritual reflection, and mental recovery require a **digital sanctuary** — a quiet, unhurried space designed for intentional communion without cognitive overload.

**Mission Statement**: To engineer a low-stimulation digital clubhouse that fosters meaningful spiritual fellowship, emotional safety, and peaceful reflection using modern pure-Dart and Serverpod technologies.

---

## 2. Target User Personas

### 🧑‍💼 Persona 1: Sarah, Overwhelmed Ministry Leader
- **Needs**: An organized space to share prayer updates and weekly study questions without answering 50 fragmented WhatsApp or Slack messages.
- **Pain Point**: Constant notification anxiety from church member pings at 11 PM.
- **Sanctuary Solution**: Asynchronous fellowship rooms where posts are read and answered in unhurried rhythms without active status or typing indicators.

### 🎨 Persona 2: David, Neurodivergent / Sensory-Fatigued Believer
- **Needs**: A visually soothing, low-stimulation environment to reflect on scripture and seek communal prayer.
- **Pain Point**: Migraines and sensory exhaustion from bright fluorescent screens, infinite feeds, and flashing notification dots.
- **Sanctuary Solution**: Sage and Charcoal sensory palettes, zero red badges, and clean typographic spacing.

### 🤝 Persona 3: Elena, Community Member Seeking Comfort
- **Needs**: A safe space to post personal struggles without receiving unsolicited lectures or debate.
- **Pain Point**: People trying to "fix" her issues when all she needs is empathetic listening.
- **Sanctuary Solution**: Compulsory Intent Tags like `[Comfort Only]`, which instruct readers to offer prayer and silent support rather than advice.

---

## 3. Core Functional Requirements

### 3.1 Room-Based Navigation
- Provide 4 dedicated fellowship spaces:
  - `🙏 #prayer-sanctuary`: Community intercession and personal burdens.
  - `📖 #weekly-study`: Thematic questions and scripture meditations.
  - `📢 #announcements`: Community bulletins without intrusive alerts.
  - `☕ #general-fellowship`: Casual unhurried conversations.
- Switching spaces must dynamically stream only reflections tagged for that room.

### 3.2 Unhurried Reflection Composer
- Members compose thoughts in a peaceful, multiline card.
- Compulsory **Intent Tag Picker**:
  - `[Prayer Request]`
  - `[Comfort Only]`
  - `[Question]`
  - `[Resource]`
- Publishing immediately injects the reflection into the chronological feed and broadcasts via Serverpod WebSocket stream.

### 3.3 Qualitative Care Affirmations
- Replaces binary "Likes" with:
  - `🙏 Praying` (increment count)
  - `🤍 Support` (increment count)
- Real-time updates delivered without distracting push alerts.

### 3.4 Sensory Ergonomics Modes
- **Sage**: Calming organic greens (`#4A7C59` on `#F4F7F5`).
- **Clean**: Neutral daylight theme (`#FAFAFA`).
- **Charcoal**: Nighttime low-contrast slate (`#1A1D20`).
- **Contrast**: High contrast WCAG AAA black/yellow/white mode.

### 3.5 Serverpod 4 Real-Time Synchronization
- Serverpod WebSocket streaming endpoint (`streamPosts`) isolates message channels per space (`space_$spaceKey`).
- ORM entities defined via YAML (`post.spy.yaml`).
- PostgreSQL persistence and Redis message queuing.
- Local-first fallback when server is unreachable.

---

## 4. Non-Functional Requirements

- **Performance**: Sub-100ms UI responsiveness; widget test suite executes under 5 seconds.
- **Accessibility**: 100% adherence to WCAG AAA contrast in Contrast Mode; minimum tap targets 48x48.
- **Calm-Tech Compliance**: Absolute ban on red notification badges, typing indicators, and read receipts.
- **Portability**: Single-codebase support for Web, macOS desktop, iOS, and Android.

---

## 5. Success Metrics & Key Results

| Metric | Target | Measurement |
| :--- | :--- | :--- |
| **Code Health** | 0 warnings, 100% tests passing | CI static analysis & `flutter test` |
| **Stream Sync Latency** | < 250ms cross-device update | Serverpod WebSocket message dispatch |
| **User Perceived Calm** | > 90% positive feedback on sensory modes | In-app feedback & partner survey |
| **Accessibility Compliance** | WCAG 2.1 AAA Contrast | Automated color ratio audits |
