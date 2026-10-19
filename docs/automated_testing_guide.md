# 🧪 Automated Testing Guide: BDD (`patrol_finders`), Pragmatic TDD & Integration Testing

*Canonical QA & Testing Architecture for **Belong on the Spectrum (`refuge`)***
*Last Updated: October 18, 2026 (`2026-10-18T20:00:00-05:00`)*

---

## 🧭 Our Testing Philosophy: High Confidence, Zero Brittle Boilerplate

We follow a **pragmatic, token-efficient testing strategy** designed for fast feedback loops (<2 seconds) and real user-journey confidence:

| Test Layer | Share of Suite | Tooling | When to Use It (And When NOT To) |
| :--- | :---: | :--- | :--- |
| **1. BDD Widget Tests + `patrol_finders`** | **~80%** | `flutter_test`, `patrol_finders` (`patrolWidgetTest` + `$`), `bdd_widget_test` (`.feature` Gherkin files) | **Default for all UI screens & user flows.** Verifies that a member can switch spaces, search posts, open their profile, upvote WIP features, and submit private feedback — running headlessly in ~1 second without booting an emulator! |
| **2. Pragmatic Unit TDD** | **~15%** | `flutter_test` (`test()`) | **Strictly for real business/domain logic:** `CommunityBrandConfig` tenant rules, `OrganizerRemoteConfigService` fallback/JSON parsing, `FeatureVotingNotifier` vote toggling, and Circle.so `.csv` data transformation. **Never** waste time writing unit tests for trivial getters or pure Flutter layout constants. |
| **3. End-to-End Integration & Live Verification** | **~5%** | `integration_test`, `patrol` CLI/MCP, `marionette_mcp` | **Reserved for critical cross-platform smoke tests** (Chrome Web Preview Channel, Pixel 9a Android, iOS Simulator) before cutting a release (`v0.6.0`, `v0.8.0-alpha`, `v1.0.0`). |

---

## 🚀 1. Why We Love `patrol_finders` (`$`) in Widget Tests

Standard `flutter_test` finders can feel verbose (`find.descendant(of: find.byType(Card), matching: find.text('Geek Out!'))`).
By using **`patrol_finders`** (`package:patrol_finders/patrol_finders.dart`) inside standard widget tests (`patrolWidgetTest`), tests read like plain English and run at unit-test speed:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge/main.dart';

void main() {
  patrolWidgetTest(
    'Member switches from Home to Spaces, searches Geek Out, and upvotes a WIP feature',
    ($) async {
      await $.pumpWidgetAndSettle(const ProviderScope(child: RefugeApp()));

      // 1. Verify Belong default branding & Circle-style Spaces tab
      expect($('Belong on the Spectrum'), findsWidgets);
      await $(#nav_spaces).tap();
      expect($('Geek Out!'), findsWidgets);

      // 2. Open the Roadmap & Feedback sheet and upvote a WIP item
      await $(#open_feedback_and_voting_button).tap();
      expect($('Direct Messages (Msgs Tab)'), findsOneWidget);
      await $(#vote_button_wip_direct_messages).tap();
    },
  );
}
```

---

## 🥒 2. Executable Gherkin BDD Specifications (`test/*.feature`)

For core community journeys, we maintain human-readable Gherkin `.feature` files in `test/` compiled by `bdd_widget_test`:
- Non-technical community organizers can read the `.feature` file to verify how the app behaves.
- Running `flutter test` executes the generated Dart step definitions automatically.

---

## 🧠 3. Pragmatic TDD for Actual Business Logic (Red -> Green -> Refactor)

When building non-trivial logic — such as:
- **Multi-Tenant White-Label Configuration** (`test/features/whitelabel_brand_config_test.dart`),
- **Organizer Remote Config Fallbacks** (`test/features/organizer_remote_config_test.dart`),
- **Android Adaptive Icon & iOS Opaque RGB24 Asset Validation** (`test/features/belong_icons_and_manifest_test.dart`), or
- **Circle.so CSV Member & Post Migration** (`Issue #41`),

we write the **failing unit test first (Red)**, implement the minimal clean Dart code (**Green**), and **Refactor** with zero lint warnings (`dart analyze`).

---

## 📊 Coverage Milestones on Our Road to `v1.0`

| Milestone | Target Coverage | Focus Areas |
| :--- | :---: | :--- |
| **`v0.7.0` (`Issue #25`)** | **50%+** | Core domain models, `CommunityBrandConfig`, `OrganizerRemoteConfigService`, Home/Spaces navigation, Search, Profile, and Feature Voting. |
| **`v0.9.0-beta` (`Issue #32`)** | **70%+** | Stage 1 & Stage 2 Auth (Google Sign-In / Appwrite adapter), Direct Messages, Notifications, and Events Calendar. |
| **`v1.0.0` (`Issue #34`)** | **90%+** | Full BDD coverage across all 6 Belong space categories, error states, and offline/remote-config fallbacks. |
