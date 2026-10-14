# 🧪 QA & Beta Testing Guide — Sanctuary (Refuge)

> **Welcome Testers!**  
> Thank you for helping us test **Sanctuary v0.1.0**. Your feedback ensures that autistic disciples of Jesus receive an unshakeable, peaceful digital community platform.

---

## 📥 How to Access Test Builds

### 1. Web Application (All Modern Browsers)
* URL: [https://refuge4serverpodhackathon.web.app](https://refuge4serverpodhackathon.web.app)
* Supported: Chrome, Safari, Firefox, Edge on desktop, tablet, and mobile.

### 2. Android Standalone APK
* Download: [`sanctuary-belong-v0.1.0.apk`](https://github.com/neiljaywarner/refuge4serverpod/releases/download/v0.1.0/sanctuary-belong-v0.1.0.apk) from the [v0.1.0 Release](https://github.com/neiljaywarner/refuge4serverpod/releases/tag/v0.1.0).
* Installation via ADB:
  ```bash
  adb install -r sanctuary-belong-v0.1.0.apk
  ```

---

## 🎭 Testing Personas & User Acceptance Test (UAT) Scenarios

Please run through the following personas during your evaluation:

### Persona A: Sensory-Sensitive Believer (Elena)
* **Goal**: Validate cognitive comfort and absence of sensory triggers.
* **Test Steps**:
  1. Open Sanctuary.
  2. Toggle each sensory theme: **Clean**, **Sage**, **Dark**, and **Contrast**.
  3. Verify that all text remains readable without blinding glare.
  4. Verify that there are **no flashing animations**, auto-playing media, or pop-up toast alerts.
* **Success Criteria**: Switching themes applies smoothly; text contrast satisfies WCAG AAA standards.

### Persona B: Deep-Dive Scripture Explorer (David)
* **Goal**: Verify space switching, intent filtering, and rich reflection posting.
* **Test Steps**:
  1. Tap `#weekly-study` space chip.
  2. Select intent filter `[Bible Deep-Dive]`.
  3. Enter a scripture insight in the composer box:
     > *"Reflecting on Romans 12:2 and neurodivergence: 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind.'"*
  4. Tap **Publish Reflection**.
* **Success Criteria**: The reflection appears at the top of the feed immediately; the composer resets cleanly; Quiet Digest updates reflection count.

### Persona C: Off-Grid / Low-Connectivity Retreat User (Samuel)
* **Goal**: Verify the resilient 800ms offline-first fallback moat.
* **Test Steps**:
  1. Launch the app on mobile or desktop.
  2. Turn on **Airplane Mode** or disconnect Wi-Fi.
  3. Refresh the page or navigate between fellowship spaces (`#prayer-sanctuary` ↔ `#special-interests`).
  4. Attempt to publish a reflection or tap a care reaction.
* **Success Criteria**: The app does **not** crash or display a network error dialog; seeded community reflections display reliably within 800ms.

### Persona D: Intercessory Prayer Partner (Hannah)
* **Goal**: Verify atomic qualitative care affirmations.
* **Test Steps**:
  1. Navigate to `#prayer-sanctuary`.
  2. Locate an unhurried prayer request.
  3. Tap the **🙏 Praying** affirmation button.
  4. Tap the **🤍 Standing With** affirmation button.
* **Success Criteria**: Affirmation count increments immediately; no sound effects or jarring badge pop-ups occur.

---

## 📋 Comprehensive Verification Matrix

| Test ID | Feature Area | Action | Expected Behavior |
| :--- | :--- | :--- | :--- |
| **UAT-01** | Branding & Info | Tap `ℹ️` in top-right app bar. | About Sanctuary dialog appears with v0.1.0 release notes, Psalm 139:14, and BuilderBase/Serverpod credits. |
| **UAT-02** | Theme Switching | Cycle Clean → Sage → Dark → Contrast. | Visual background and foreground contrast adjust instantly without state loss. |
| **UAT-03** | Space Navigation | Tap `#special-interests` space chip. | Feed updates to special interest infodumps (trains, coding, biology). |
| **UAT-04** | Intent Filtering | Tap filter chip `[Autism & Faith Meme]`. | Displays only reflections tagged with relatable faith memes. |
| **UAT-05** | Urgency Rejection | Submit post containing `"Urgent prayer click here!"`. | Rejected by Serverpod backend calm-tech validation. |
| **UAT-06** | Real-Time Sync | Open app in two browser tabs or two devices. | Post published on Device A appears on Device B via Serverpod WebSocket stream. |

---

## 🐛 Bug & Feedback Reporting Template

If you encounter any anomalies, please open an issue on the repository:  
🔗 [Submit GitHub Issue](https://github.com/neiljaywarner/refuge4serverpod/issues/new)

**Issue Format**:
```markdown
### Summary
Brief description of the issue.

### Environment
- Device / OS: (e.g. Pixel 9a Android 15 / Chrome macOS)
- App Version: v0.1.0 (Web or APK)

### Steps to Reproduce
1. Go to...
2. Tap on...
3. Observe...

### Expected Behavior
What should happen according to calm-tech principles.

### Actual Behavior
What actually happened (include screenshots if available).
```
