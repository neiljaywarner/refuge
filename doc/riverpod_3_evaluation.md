# Riverpod 3 Architectural Evaluation & Migration Strategy

**Tracking Issue**: [#345](https://github.com/neiljaywarner/refuge/issues/345)  
**Date**: October 2026  
**Status**: Completed — **Recommendation: Defer upgrade until post-soft launch cutover**

---

## 1. Executive Summary

Riverpod 3 (`flutter_riverpod: ^3.4.3`) is available on pub.dev and represents a major evolution in Dart/Flutter reactive caching and state architecture.

We performed a sandbox spike in worktree `.worktrees/issue-345-riverpod-3-eval` upgrading `flutter_riverpod` and `hooks_riverpod` from `2.6.1` to `3.4.3`. 

### Key Finding
While dependency resolution (`flutter pub get`) succeeded cleanly, **upgrading to Riverpod 3 immediately introduces significant breaking changes into our existing unit test suite**, primarily due to `Notifier.state` becoming `@protected`. Because our 175+ passing tests directly assert against `notifier.state` on clean POJO notifiers, an immediate upgrade would require refactoring dozens of unit test harnesses into `ProviderContainer` wrappers during the sensitive soft launch stabilization window (October 24–31, 2026).

Therefore, **we recommend keeping Riverpod 2.6.1 for the soft launch release and scheduling the Riverpod 3 migration for milestone v1.1.**

---

## 2. Technical Evaluation Matrix

| Criterion | Riverpod 2.6.1 (Current) | Riverpod 3.4.3 | Impact / Assessment |
| :--- | :--- | :--- | :--- |
| **Pub Resolution** | Stable, zero conflicts | Resolves cleanly with `flutter_localizations` & overrides | Low risk on package resolution |
| **`Notifier.state` Visibility** | Public getter | `@protected` on `Notifier` | **High Breaking Impact**: Direct test assertions (`expect(notifier.state, ...)`) fail static analysis |
| **`StateProvider` Support** | First-class | Deprecated / relegated to `legacy.dart` | Requires migrating remaining `StateProvider` instances first (Tracked in #342) |
| **Readability & Ergonomics** | High for standard Flutter widgets | High when using code generation (`riverpod_generator`), but higher ceremony for pure POJO unit testing | Neutral to slightly improved for apps; more verbose for unit tests |
| **Soft Launch Risk** | **Zero** (175/175 tests green, verified on physical Pixels) | **High** (requires refactoring ~25 unit tests across notifications and sensory themes) | **Risk exceeds benefit during launch week** |

---

## 3. Detailed Findings from Spike

### A. The `@protected Notifier.state` Change
In Riverpod 3, `Notifier.state` cannot be inspected directly outside of the `Notifier` subclass:
```dart
// Riverpod 2.x (Valid):
final soundscapeNotifier = SensorySoundscapeNotifier();
expect(soundscapeNotifier.state.selectedSoundscape, SoundscapeTrack.gentleRain);

// Riverpod 3.x (Compile Error):
// undefined_getter: The getter 'state' isn't defined for the type 'SensorySoundscapeNotifier'.
// Must use:
final container = ProviderContainer();
expect(container.read(sensorySoundscapeProvider).selectedSoundscape, SoundscapeTrack.gentleRain);
```

While wrapping tests in `ProviderContainer` is Riverpod's recommended testing pattern, doing so across the entire test suite carries substantial churn.

### B. Synergy with Issue #342 (StateProvider Migration)
The best architectural stepping stone is to first execute **Issue #342 (`refactor(state): Migrate legacy StateProviders to Riverpod Notifier architecture`)** under Riverpod 2.6.1. Once our providers are decoupled from legacy `StateProvider`, upgrading to Riverpod 3 in milestone v1.1 will be straightforward.

---

## 4. Final Recommendation & Action Plan

1. **Keep `flutter_riverpod: ^2.6.1` for Soft Launch (Oct 24–31)**:
   - Maintain 100% test reliability across all 175+ tests and physical Pixel devices.
2. **Execute Issue #342 First**:
   - Modernize existing `StateProvider` declarations into `Notifier` / `AsyncNotifier`.
3. **Schedule Riverpod 3 for Post-Launch Milestone v1.1**:
   - Upgrade to `flutter_riverpod: ^3.4.3`.
   - Update unit test harnesses with standard `ProviderContainer` test utilities.
