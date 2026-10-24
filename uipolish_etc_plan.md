# UI Polish, Stream Resilience & Application ID / Flavors Master Plan (`uipolish_etc_plan.md`)

This master execution plan outlines the remaining tasks following PR #433 (`feat(ux,branding): calm splash, BELONG icons, safe cosmetics (#389)`). Every task strictly follows the project rules:
1. **1 Issue = 1 Worktree = 1 PR** for every item without exception.
2. **Zero Direct Commits to `main`** — all code changes land via verified squash-merged PRs.
3. **Zero Terminal Push Prompts** — always use GitHub MCP tools (`call_mcp_tool(ServerName: 'github', ...)`) for branch creation, file commits, PR creation, and merges.
4. **Dart & Maestro MCP Prioritization** — use `analyze_files` and `run_tests` via Dart MCP; take high-res device screenshots and screen inspections via Maestro MCP (`ServerName: 'maestro'`).
5. **Mandatory CodeRabbit Protocol** — invoke `@coderabbitai review`, wait min 90–180 seconds until analysis completes, triage findings into tracked issues, then squash-merge.
6. **Mandatory Visual Evidence** — capture Before and After screenshots on real hardware (`56091JEBF14039`, `58221JEBF20835`) or `emulator-5554` and attach to issues and PRs.

---

## Architecture & Work Items Overview

| Item | Title | Branch / Worktree | Scope & Key Files |
| :--- | :--- | :--- | :--- |
| **Item 1** | **High-Contrast Theme Tokens & Monogram Initials** | `fix/#<NUM>-high-contrast-initials`<br>`.worktrees/issue-<NUM>-high-contrast-initials` | `lib/src/constants/app_theme.dart`<br>`lib/src/features/reflections/presentation/reflection_card.dart`<br>`lib/src/features/reflections/presentation/space_navigation_bar.dart`<br>`test/features/profile/member_profile_initials_test.dart` |
| **Item 2** | **Feed Loading Stream & Sub-View Navigation Resilience** | `fix/#<NUM>-feed-stream-resilience`<br>`.worktrees/issue-<NUM>-feed-stream-resilience` | `lib/src/home_screen.dart`<br>`lib/src/features/reflections/data/serverpod_post_repository.dart`<br>`test/features/feed/feed_stream_resilience_test.dart` |
| **Item 3** | **Application ID (`com.belongonthespectrum.refuge`) & Flavors** | `feat/#<NUM>-refuge-application-id-flavors`<br>`.worktrees/issue-<NUM>-refuge-application-id-flavors` | `android/app/build.gradle.kts`<br>`android/app/google-services.json`<br>`android/app/src/main/kotlin/com/belongonthespectrum/refuge/MainActivity.kt`<br>`lib/src/core/config/app_flavor.dart`<br>`lib/src/features/branding/domain/community_brand_config.dart`<br>`lib/src/features/reflections/presentation/community_anchor_banner.dart`<br>`lib/src/features/auth/data/auth_repository.dart`<br>`lib/src/features/notifications/data/app_launcher_badge_service.dart`<br>`ios/Runner.xcodeproj/project.pbxproj`<br>`macos/Runner/Configs/AppInfo.xcconfig` |

---

## Detailed Step-by-Step Execution Guide

### Item 1: High-Contrast Theme Tokens & Reflection Card Initials Polish
- **Objective**: Ensure WCAG AAA compliance in `SensoryMode.contrast` and clean monogram initials across all cards and directory lists.
- **Problem**:
  1. In `app_theme.dart`, `SensoryMode.contrast` currently defaults `secondary` and `secondaryContainer` to Material 2 teal (`Color(0xFF03DAC6)`), which clashes with the high-contrast yellow/black palette and fails contrast checks on dark backgrounds.
  2. `ReflectionCard._getInitials` in `lib/src/features/reflections/presentation/reflection_card.dart` uses a naive split without removing parenthetical suffixes (e.g. `David M. (UK)` generates `D(` instead of `DM`).
  3. `SpaceNavigationBar` chip labels in high-contrast mode do not enforce pure black text when selected on yellow background chips.
- **Implementation**:
  1. In `lib/src/constants/app_theme.dart`:
     - Update `SensoryThemeData.contrast` ColorScheme:
       ```dart
       secondary: Color(0xFFFFEB3B),
       onSecondary: Colors.black,
       secondaryContainer: Color(0xFF2B2600),
       onSecondaryContainer: Color(0xFFFFEB3B),
       ```
     - Add `chipTheme: ChipThemeData(...)` specifying high-contrast selected and unselected text styles.
  2. In `lib/src/features/reflections/presentation/reflection_card.dart`:
     - Refactor `_getInitials(String author)`:
       ```dart
       String clean = author.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
       // Strip non-alphanumeric except whitespace
       clean = clean.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
       final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
       if (parts.isEmpty) return '?';
       if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
       return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
       ```
     - In avatar circle, when `isContrast == true`, enforce background `Colors.yellow` and text `Colors.black`.
  3. In `lib/src/features/reflections/presentation/space_navigation_bar.dart`:
     - Set label style color: `isSelected && isContrast ? Colors.black : (isContrast ? Colors.yellow : null)`.
  4. Unit test:
     - Add unit tests in `test/features/profile/member_profile_initials_test.dart` verifying initials for `David M. (UK)`, `Dr. Sarah Chen`, `Alex`, and empty string.
- **Verification**:
  - `call_mcp_tool(ServerName: 'dart', ToolName: 'analyze_files')` -> 0 errors.
  - `call_mcp_tool(ServerName: 'dart', ToolName: 'run_tests')` -> All tests passing.
  - Maestro MCP: Take screenshot on `emulator-5554` verifying high contrast cards and chips.

---

## Detailed Step-by-Step Execution Guide

### Item 2: Feed Loading Stream & Sub-View Navigation Resilience
- **Objective**: Prevent indefinite loading spinners when toggling sub-views (`Feed` <-> `Spaces`) or switching bottom navigation tabs.
- **Problem**:
  1. In `lib/src/home_screen.dart`, `useMemoized` caching `postStream` was keyed on empty list `[]` or incomplete state, meaning that when returning from Spaces or changing filters, the stream listener could remain stalled or waiting for a WebSocket frame.
  2. In `lib/src/features/reflections/data/serverpod_post_repository.dart`, `watchPosts` was tied directly to Serverpod streaming without immediate replay from local cached state.
- **Implementation**:
  1. In `lib/src/home_screen.dart`:
     - Key stream subscription memoization to `[homeSubView.value, activeBottomTab.value, selectedSpace.value]`.
     - Ensure fallback timeout or default initial data from cache so UI immediately renders cached feed items instead of blank circular progress indicator.
  2. In `lib/src/features/reflections/data/serverpod_post_repository.dart`:
     - Use a `BehaviorSubject` or broadcast stream controller that emits local cached posts immediately before opening remote stream.
  3. Add a test in `test/features/feed/feed_stream_resilience_test.dart` simulating rapid subview toggles and ensuring post count > 0 without lingering progress indicators.
- **Verification**:
  - `call_mcp_tool(ServerName: 'dart', ToolName: 'run_tests')`.
  - Drive `emulator-5554` via Maestro to switch tabs: Home -> Spaces -> Feed -> Notifications -> Home and confirm feed appears immediately.

---

### Item 3: Application ID (`com.belongonthespectrum.refuge`) & Multi-Environment Flavors
- **Objective**: Finalize base application ID rename from `sanctuary` to `refuge` across Android, iOS, macOS, and Web, with support for environment flavor suffixes (`.dev`, `.stg`, `.qa`) and URL prefixes.
- **Key Changes**:
  1. `lib/src/core/config/app_flavor.dart`:
     - Define `AppFlavor` enum: `dev`, `stg`, `qa`, `prod`.
     - `applicationIdSuffix`: `.dev`, `.stg`, `.qa`, `""`.
     - `applicationId`: `com.belongonthespectrum.refuge${applicationIdSuffix}`.
     - `urlPrefix`: `dev.`, `stg.`, `qa.`, `""`.
     - `websiteUrl`: `https://${urlPrefix}belongonthespectrum.com`.
     - `magicLinkRedirectUrl`: `https://${urlPrefix}belongonthespectrum.com/auth/verify`.
  2. `lib/src/features/branding/domain/community_brand_config.dart`:
     - Update config to read from `AppFlavor.current`.
  3. `lib/src/features/reflections/presentation/community_anchor_banner.dart`:
     - Display current flavor badge when not in production.
  4. `android/app/build.gradle.kts`:
     - `namespace = "com.belongonthespectrum.refuge"`
     - Parse `dart-defines` in Gradle to extract `FLAVOR`:
       ```kotlin
       val dartDefines = project.findProperty("dart-defines") as? String
       // decode base64 dart-defines and extract FLAVOR
       val flavor = extractedFlavor ?: "dev"
       val appIdSuffix = when(flavor) {
           "prod" -> ""
           else -> ".$flavor"
       }
       defaultConfig {
           applicationId = "com.belongonthespectrum.refuge$appIdSuffix"
       }
       ```
  5. Native Source directories:
     - Relocate `android/app/src/main/kotlin/com/belongonthespectrum/sanctuary/MainActivity.kt` to `android/app/src/main/kotlin/com/belongonthespectrum/refuge/MainActivity.kt` with package declaration `package com.belongonthespectrum.refuge`.
  6. `android/app/google-services.json`:
     - Add client entries for `com.belongonthespectrum.refuge`, `com.belongonthespectrum.refuge.dev`, `com.belongonthespectrum.refuge.stg`, and `com.belongonthespectrum.refuge.qa`.
  7. Apple Bundle Identifiers:
     - `ios/Runner.xcodeproj/project.pbxproj`: `PRODUCT_BUNDLE_IDENTIFIER = com.belongonthespectrum.refuge;`
     - `macos/Runner/Configs/AppInfo.xcconfig`: `PRODUCT_BUNDLE_IDENTIFIER = com.belongonthespectrum.refuge;`
  8. Notifications MethodChannel:
     - `lib/src/features/notifications/data/app_launcher_badge_service.dart`: `com.belongonthespectrum.refuge/badge`.
- **Verification**:
  - `call_mcp_tool(ServerName: 'dart', ToolName: 'run_tests')`.
  - Android Gradle build check.
  - Maestro test asserting correct application ID on launch.

---

## Autonomous Execution Checklist for Agents

```markdown
- [x] Create GitHub Issue for Item 1 (#451)
- [x] Create isolated git worktree for Item 1 (`.worktrees/issue-451-high-contrast-initials`)
- [x] Implement High-Contrast tokens, Reflection Card initials, SpaceNavigationBar black chip text
- [x] Verify Item 1 via Dart MCP analyze_files and run_tests
- [x] Push files via GitHub MCP push_files
- [x] Create PR referencing "Closes #451" (PR #455)
- [x] Trigger @coderabbitai review and wait 90-180s until review completes
- [x] Triage findings and squash-merge PR via GitHub MCP (Merged in commit 7a4e2303)
- [x] Repeat for Item 2 (Feed Stream Resilience - Issue #458 / PR #461, Issue #470 / PR #471)
- [x] Repeat for Item 3 (Application ID & Flavors - Issue #472 / PR #476)
```
