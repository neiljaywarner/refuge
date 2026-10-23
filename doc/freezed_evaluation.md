// Evaluation: Freezed vs Dart 3 Native Patterns

# Evaluation: Freezed vs Dart 3 Native Patterns

**Tracking Issue**: [#348](https://github.com/neiljaywarner/refuge/issues/348)  
**Date**: October 2026  
**Status**: Evaluated — **Recommendation: Retain manual Dart 3 patterns for soft launch; evaluate Freezed for sealed union states in v1.1**

---

## 1. Context & Motivation
The user requested an evaluation of `pub.dev/packages/freezed` for automatically generating `copyWith`, equality (`==`), `hashCode`, and `toString()` across domain models (such as `MemberProfile`, `Post`, `BelongNotification`).

---

## 2. Comparison Matrix

| Feature | Freezed (`package:freezed`) | Dart 3 Native (`class` + Records) |
| :--- | :--- | :--- |
| **Boilerplate** | Very low (annotations only) | Low to moderate (explicit `copyWith`) |
| **Build Runner Dependency** | **Requires `build_runner`** (`dart run build_runner build`) | **Zero codegen dependencies** (instant compile) |
| **CI & Hot Reload Speed** | Slower CI (adds 45–90s build step for code generation) | **Instant hot-reload and sub-2s test execution** |
| **Pattern Matching** | Deep sealed union support (`when`, `map`) | **Native Dart 3 switch expressions & exhaustiveness checking** |
| **IDE Autocomplete** | Dependent on generated `.freezed.dart` files | Instant, native, zero missing file errors |
| **Maintenance Risk** | Upgrade churn during major Flutter / analyzer bumps | Zero third-party risk |

---

## 3. Findings & Recommendation

1. **Current Codebase Strength**:
   - `MemberProfile`, `Post`, and `BelongNotification` are already cleanly implemented with `copyWith` and `Equatable` (or standard immutability).
   - Adding `freezed` and `freezed_annotation` would mandate running `build_runner` across the repository, slowing down our sub-2-second widget test iterations.
   - Dart 3's native pattern matching and switch expressions now deliver the vast majority of Freezed's union benefits without any code generation penalty.

2. **Conclusion**:
   - Keep our lightweight, zero-codegen Dart classes for the upcoming soft launch (Oct 24–31).
   - If complex polymorphic state machines or multi-variant sealed union hierarchies are required in milestone v1.1, Freezed can be introduced selectively without impacting core models.
