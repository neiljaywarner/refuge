# 🌿 Belong on the Spectrum: Manual Sensory & Notifications Audit Checklist

> **Purpose**: Manual quality assurance checklist designed for neurodivergent safety, sensory calmness, and unhurried usability across Web, Android, and iOS.

---

## 🎨 1. Sensory Themes & WCAG AAA Contrast
- [ ] **High Contrast Switch**: Toggling high-contrast mode immediately renders `#000000` deep black backgrounds and `#FFFF00` yellow borders. Zero washed-out grey text.
- [ ] **Colorways**:
  - `Classic Sanctuary`: Calming neutral tones.
  - `Sage Botanical`: Soothing green hues.
  - `Twilight Calm`: Gentle blue/slate tones.
  - `Charcoal Night`: Muted dark mode.
- [ ] **Dynamic Font Scaling**: Increase system font scaling to 1.5x and 2.0x. Ensure zero `RenderFlex overflowed` red-and-yellow bars on feed cards, profile dialogs, and bottom navigation.

---

## 🔔 2. Calm Notifications & Bottom Navigation Bell
- [ ] **Zero Red Urgency Dots**:
  - The notification bell counter must use soft forest green (`#2E6B56`) or contrast yellow.
  - No pulsing animations or urgent alarm badges.
- [ ] **Filter Chips**:
  - `Inbox`: Shows all items.
  - `Mentions`: Filters only items with `@username` mentions.
  - `Direct Messages`: Filters private 1-on-1 messages.
  - `Threads`: Filters discussion replies.
  - `Following`: Filters updates from followed members.
- [ ] **Mark All Read**:
  - Tapping "Mark all read" immediately removes all unread indicators.
  - Bottom navigation badge clears to 0 and disappears.
  - Launcher icon badge count synchronizes to 0.
- [ ] **Deep Linking**:
  - Tapping a Mention card navigates to the Home tab and highlights the target reflection.
  - Tapping a Direct Message card navigates to the Messages tab and immediately opens the conversation thread.
  - Tapping an archived reflection displays the polite floating message: *"This reflection was unhurriedly archived or moved"*.

---

## 🪟 3. OS Notification Shade & Permission Ethics
- [ ] **Zero Startup Permission Popups**: Launching the app on fresh install must NEVER trigger an OS notification permission dialog.
- [ ] **Deliberate Opt-In**: Permission is only requested when opening "Calm Notification Preferences" and toggling "Receive Push Digests" ON.
- [ ] **Silent Delivery**: Test notification delivered to the Android shade must be silent (`playSound: false`, `enableVibration: false`).
