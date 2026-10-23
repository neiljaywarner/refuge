# ADR 0005: Bottom Navigation Bar Package Selection & WCAG AAA Sensory Compatibility

- **Status**: Accepted (`2026-10-18`)
- **Issue**: [`#18`](https://github.com/neiljaywarner/refuge/issues/18)

---

## 1. Context & Problem Statement

For **Belong on the Spectrum** (`belongonthespectrum.com`), our Circle.so-style mobile and web interface requires a clean 4-tab Bottom Navigation Bar:
1. **`Home`** (`Feed` + `Spaces`)
2. **`Notifications`** (*Coming Soon* view — tracked in Issue #27)
3. **`Msgs`** (*Coming Soon* view — tracked in Issue #27)
4. **`Search`** (Instant keyword & space search across posts, memes, and videos)

We must evaluate `pub.dev` bottom navigation packages for Flutter 3.47 / Dart 3.13 compatibility, visual clarity, and strict adherence to our **WCAG AAA sensory accessibility modes** (*Clean Slate*, *Sage Botanical*, *Monastic Dark*, *High Contrast*).

---

## 2. Candidates Evaluated

| Package (`pub.dev`) | Pros | Cons / Sensory Considerations | Verdict |
| :--- | :--- | :--- | :--- |
| **`salomon_bottom_bar`** (`^3.3.2`) | • Pure Dart, zero native dependencies<br>• Pill-shaped active tab highlight closely matches Circle.so & modern calm-tech UI<br>• Custom `duration` & `curve` parameters allow instant `Duration.zero` transitions when reduced-motion / High Contrast mode is active<br>• Always shows active label clearly | In default mode, inactive tabs show icon-only unless tapped | **Selected (Primary)** — Paired with explicit `Tooltip` and semantic labels on all 4 tabs |
| **`google_nav_bar`** | • Similar pill aesthetic | Slightly heavier padding on narrow 320px screens | Runner-up |
| **`persistent_bottom_nav_bar_v2`** | • Built-in nested navigators | Too opinionated for Riverpod declarative state (`HookConsumerWidget`) | Rejected |
| **Material 3 `NavigationBar`** | • Built into Flutter SDK | Standard Material look; less distinctive than pill highlight | Used as accessible fallback |

---

## 3. Decision

We adopt **`salomon_bottom_bar`** wrapped in a dedicated `BelongBottomNavBar` `HookConsumerWidget` (`lib/src/features/navigation/presentation/belong_bottom_nav_bar.dart`) that:
1. Renders the 4 core tabs: **`Home`**, **`Notifications`**, **`Msgs`**, and **`Search`**.
2. Uses high-contrast yellow/black borders in `SensoryMode.contrast` and calm `#112334` deep navy / `#C99F49` warm gold accents in standard Belong modes.
3. Respects `MediaQuery.disableAnimationsOf(context)` so neurodivergent members sensitive to motion experience zero sliding animation jitter.

---

## 4. Evolution: Persistent, Legible Labels for Cognitive Accessibility (`#362`)

Following community accessibility feedback in Issue `#362`, collapsing inactive tab labels created cognitive friction for autistic and neurodivergent community members who rely on explicit textual semantics rather than abstract icon glyphs alone.
`BelongBottomNavBar` was evolved into a bespoke, lightweight, fully responsive Flutter component maintaining the exact same public Riverpod API:
- **Persistent Text Labels**: All 4 tabs (`Home`, `Notifications`, `Messages`, `Search`) permanently display both their icon and legible text label simultaneously.
- **Zero Overflow**: Employs `FittedBox(fit: BoxFit.scaleDown)` within symmetrical `Expanded` columns, ensuring zero `RenderFlex` overflow even on compact 320px screens or enlarged accessibility font scales.
- **Enhanced High Contrast (WCAG AAA)**: Active tab is rendered with bold yellow borders and yellow text/icon in `SensoryMode.contrast`.
- **Integrated Unread Badge**: Renders clean count badge over the `Notifications` icon.
