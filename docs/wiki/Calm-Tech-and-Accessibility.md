# 🛡️ Calm-Tech & Accessibility (WCAG AAA) — Sanctuary (Refuge)

> **Start here if you are a member:** **[Welcome](Home)** and **[How you can help](How-You-Can-Help-Volunteer-Guide)**. This page is an earlier design note. The app is **Belong**. The looks you can choose are **Clean**, **Sage**, **Dark**, and **Contrast**. Notifications can show a count. If this page disagrees with what you see, trust the app.

> Technology should require the smallest possible amount of attention and inform without intruding.

---

## 🧘 Calm-Tech Philosophy in Sanctuary

In standard social media and corporate group software (Slack, Discord, Facebook), the interface is intentionally designed to trigger dopamine spikes through variable-reward mechanics:
* Red notification badges simulate an emergency state in the human brain.
* Unread counters demand to be cleared like a stressful to-do list.
* "Someone is typing..." animations induce anticipatory anxiety.
* Public "Like" counts foster insecurity and performative behavior.

**Sanctuary** is built on the calm-tech principles articulated by Amber Case and Mark Weiser, tailored to the emotional and sensory needs of **autistic believers and neurodivergent individuals**:

1. **The Smallest Amount of Attention**: Content does not scream for attention; it waits patiently until you are ready to engage.
2. **Zero-Badge Architecture**: No red badges, no unread counts, and no persistent notification dots anywhere in the interface.
3. **Intent Precedes Content**: Intent tags establish emotional context before a reader begins processing text, eliminating the cognitive exhaustion of trying to decipher subtext.
4. **Rest is Spiritual**: As God rested on the seventh day (Genesis 2:2), stepping away from technology is viewed as an act of worship and obedience.

---

## 🎨 4 WCAG AAA Sensory Modes

Sensory processing differences often make bright white backgrounds or harsh saturated colors physically painful to look at. Sanctuary provides four carefully engineered themes:

| Theme | Primary Hex | Background Hex | Contrast Ratio | Sensory Target |
| :--- | :--- | :--- | :--- | :--- |
| **Sage Botanical** | `#2D5A27` | `#F4F7F4` | `8.2:1` (AAA) | Calming natural green; lowers visual fatigue and cortisol. |
| **Clean Slate** | `#212121` | `#FAFAFA` | `15.8:1` (AAA) | Neutral minimalist grayscale; removes all chromatic distraction. |
| **Monastic Dark** | `#E0E0E0` | `#121212` | `13.5:1` (AAA) | Warm low blue-light dark mode; protects circadian rhythms. |
| **High Contrast** | `#FFEB3B` | `#000000` | `19.5:1` (AAA) | Maximum visual legibility; supports low vision and high focus. |

*All themes exceed the WCAG 2.1 Level AAA requirement of 7:1 for normal text.*

---

## 🧩 Neurodivergent Affirmations & Accommodations

* **Special Interest Badging**: Rather than treating intense passions as a distraction, Sanctuary honors special interests (theology, technology, nature, mechanics) as God-given gifts of depth and devotion.
* **Autism & Faith Memes**: Dedicated space for humor that normalizes neurodivergent experiences within the Christian church.
* **No Unbounded Viewports or Layout Shifts**: Designed with stable layout builders and responsive constraints to prevent disorienting jumps or unexpected scrolls.
* **Large Touch Targets**: All action buttons and chips provide a minimum tap target of `48x48` dp, satisfying mobile accessibility guidelines.

## Large system text

Belong keeps the operating-system Font size. The in-app sensory preset (Standard, Comfort, Spacious, Max Clarity) multiplies that size. It does not replace it. A widget that cannot grow may clamp itself and should say why. Nothing clamps the whole app back to 100%.

Widget checks use a phone-sized surface at text scales 1.0, 1.3, 2.0, and 3.0. `pumpWithTextScale` in `test/helpers/text_scale.dart` fails the test when Flutter reports an overflow. The scenarios live in `test/features/accessibility/large_text.feature`. `bdd_widget_test` is not a dependency yet (#926), so `large_text_bdd_test.dart` runs the steps by hand.

On an Android emulator or phone:

```bash
bash tool/run_large_text_device_checks.sh
```

That sets `font_scale` to 2.0 and a slightly larger display density, runs `integration_test/large_text_patrol_test.dart` and `.maestro/large_text_sign_in_flow.yaml`, then restores both settings. The Maestro flow checks the signed-out sign-in wall. The Patrol test walks home, messages, and feedback on a local feed. Group-call screens are not on `main` (PR #905). Cover the lobby, guest join form, in-call controls, and participant grid after that branch merges.
