# 🎓 Engineering Lessons Learned & Sprint Accomplishments

> **Project**: Belong on the Spectrum (`neiljaywarner/refuge`)  
> **Audience**: Engineering Students, Apprentices, Mentees & Maintainers  
> **Tags**: `engineering`, `mentoring`, `education`, `architecture`, `lessons-learned`  
> **Last Updated**: October 19, 2026

---

## 🏆 Summary of Sprint Accomplishments (October 18–19, 2026)

In an intensive 24-hour sprint preceding the October 31 cutover deadline, the engineering team delivered rapid, high-quality milestones under strict ticket-driven discipline:

### 1. Production Web & Android Delivery
- **Live Multi-Channel Web PWA**: Deployed to production at [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) with automated Firebase Preview Channels per release.
- **First Release APK Delivered**: Built release APK and distributed to the `pre-alpha-testers` group via Firebase App Distribution.
- **Truthful Semantic Release Notes**: Automated `tool/deploy_release.dart` to generate release notes strictly from actual merged GitHub PRs.

### 2. Physical Device Driving & Real Glass Verification
- Automated driving of the connected **Google Pixel 9a / Android device** using Marionette and Patrol.
- **Two Real-World Bugs Caught & Fixed on Glass**:
  1. 🛑 **Riverpod Red-Screen Runtime Crash**: A nested `ProviderScope` in debug builds caused root providers to fail. Fixed by consolidating into a single root `ProviderScope` with `overrides`.
  2. 🛑 **ChoiceChip Viewport Squeeze**: Default chip checkmarks caused severe text truncation on 411dp mobile screens. Resolved with custom label padding and `showCheckmark: false`.

### 3. Community Organizer Specs Fully Delivered
- **Required Church Affiliation**: Implemented Marty's exact SMS specification requiring *"Which ICOC church do you attend?"* alongside the explicit option *"I am not a member of an ICOC church"*.
- **Members Section & Directory**: Interactive directory featuring the signed-in user's profile and dev-mode dummy community members (Marty, Hannah, Alex, Jordan).
- **Literal 3-Intent Feedback Funnel**: Private feedback, public praise, and 1-tap feature voting.

### 4. Circle.so Migration CLI Importer
- Built pure-Dart CLI tool `tool/import_circle_csv.dart` supporting `--dry-run` and `--json` modes.
- Full RFC 4180 parsing (quotes, embedded commas, newlines, escaped quotes) with zero third-party dependencies.
- Canonical space mapping preserving original timestamps and author names.

### 5. Multi-Tier Testing & Quality Baseline
- Test suite expanded from 0 to **82 automated tests passing green** (`run_tests` via Dart MCP).
- Zero static analysis errors or warnings (`analyze_files` via Dart MCP).
- **16 Atomic Pull Requests Merged** to `main` with strict `1 Issue = 1 Worktree = 1 PR` hygiene.

---

## 🧠 Key Engineering Lessons Learned

### Lesson 1: Headless Tests Cannot Replace Real Device Glass
Unit and widget tests run in a synthetic Flutter test environment with ideal constraints. They did not catch the nested `ProviderScope` assertion or the 411dp viewport chip clipping. Driving the app on real hardware (Google Pixel 9a) or an interactive browser is mandatory before declaring any UI feature complete.

### Lesson 2: Dedicated Tooling Protocol (MCP) Outperforms Fragile Shell Scripts
Using the **GitHub MCP Server** (`push_files`, `create_pull_request`, `merge_pull_request`) eliminated hundreds of repetitive terminal approval prompts. Similarly, using the **Dart MCP Server** (`analyze_files`, `run_tests`) delivered sub-second feedback loops without shell escaping bugs.

### Lesson 3: Clean Repository Seams Decouple Architecture from Infrastructure
By defining clean abstract interfaces (`FeatureVotingRepository`, `PostRepository`, `AuthRepository`), the UI can sit on `InMemory`, Firebase, or Serverpod adapters. Appwrite is on `main` ([PR #412](https://github.com/neiljaywarner/refuge/pull/412), `fc71fd4`) and stays off unless both `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` are set. It has not replaced Serverpod. [#384](https://github.com/neiljaywarner/refuge/issues/384) is not closed.

### Lesson 4: Strict Zero-PII Discipline Must Be Automated
Real member data must never touch Git repositories. We enforced this structurally:
- Automated regex scrubbing in `ErrorReporterService`.
- `.gitignore` rule blocking all `**/*.csv` files except explicit synthetic fixtures.
- Model serialization tests asserting that email fields serialize as `[ANONYMIZED_PII]`.

### Lesson 5: Pure-Dart CLI Tooling Maximizes Team Velocity
Instead of writing Bash or Python scripts that require external interpreters or fail on Windows, writing CLI tools in pure Dart (`tool/refuge_cli.dart`, `tool/import_circle_csv.dart`) allows Flutter developers to read, test, and debug tooling using the exact same language and IDE.
