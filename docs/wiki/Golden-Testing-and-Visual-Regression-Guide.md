# 🎨 Golden Testing, Font Loading & Visual Regression Guide

> **Test Suite**: [`test/features/goldens/sociable_golden_widgets_test.dart`](https://github.com/neiljaywarner/refuge/blob/main/test/features/goldens/sociable_golden_widgets_test.dart)  
> **Font Loader**: [`test/support/test_font_loader.dart`](https://github.com/neiljaywarner/refuge/blob/main/test/support/test_font_loader.dart)  
> **Standard**: Martin Fowler's Sociable Unit & Widget Testing + `package:patrol_finders`

---

## 🧭 Why Sociable Golden Tests for Belong on the Spectrum?

In calm-tech neurodivergent applications, visual consistency, clear spacing, and predictable typography are first-class accessibility requirements. A misplaced margin, clipped chip, or faint text stroke can trigger sensory discomfort.

To ensure visual regressions are caught immediately without flakiness:
1. **Sociable Testing Over Isolation**: We test components working together with realistic domain models (`Post`, `OrganizerRemoteConfig`, `BelongBottomTab`), exercising state changes and callbacks rather than mocking internal layout details.
2. **Deterministic Typography**: Headless test runners (macOS, Linux CI) often render text as tofu blocks (`■`) because system fonts are not loaded. Our `TestFontLoader` loads `Roboto-Regular.ttf` and `Roboto-Bold.ttf` directly into Flutter's `FontLoader`.
3. **Sub-2-Second Execution Speed**: Tests run headlessly via Dart MCP (`run_tests`) in <2 seconds.

---

## 📦 Low-Hanging Fruit UI Covered

| Component | Visual Regression Scope | Sociable Behavior Verified |
| :--- | :--- | :--- |
| **`ToneFilterRow`** | Sensory intent chips (`[Comfort Only]`, `[Prayer Request]`, `All`) | Tap selection updates active filter state and invokes `onSelectFilter` callback. |
| **`CommunityAnchorBanner`** | Organizer welcome headline, message, and branding badge | Renders Remote Config defaults with dark-mode/contrast border styling. |
| **`BelongBottomNavBar`** | 4 tabs (`Home`, `Notifications`, `Msgs`, `Search`) | Salomon bottom bar expands selected tab label and fires navigation callback. |
| **`ReflectionCard`** | Unhurried reflection card, author name, tone badge, and reactions | Displays prayer & support reaction counts (`4 Praying`, `7 Support`) and handles tap affirmation. |

---

## 🛠️ How to Run & Update Golden Baselines

### Running Golden Tests Headlessly
```bash
# Via Dart MCP tool
call_mcp_tool(ServerName: 'dart', ToolName: 'run_tests', Arguments: {roots: [{root: 'file:///Users/neil/belongonthespectrum/refuge', paths: ['test/features/goldens']}]})

# Or via terminal:
flutter test test/features/goldens/sociable_golden_widgets_test.dart
```

### Updating Golden Files After Intentional UI Redesigns
```bash
flutter test test/features/goldens/sociable_golden_widgets_test.dart --update-goldens
```
*(Golden image baselines reside in `test/features/goldens/goldens/`).*
