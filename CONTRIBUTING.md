# 🤝 Contributing to Belong on the Spectrum (`refuge`)

Welcome! Thank you for helping build **Belong on the Spectrum** ([belongonthespectrum.com](https://www.belongonthespectrum.com/), partnered with [DFW Church](https://dfwchurch.org)) — a calm, neurodivergent-affirming community platform and white-label Circle.so replacement.

---

## 🌱 Not a Programmer? You Can Still Contribute!
Please read our **[🤝 How You Can Help (No Coding Required!)](https://github.com/neiljaywarner/refuge/wiki/How-You-Can-Help-Volunteer-Guide)** page on the Wiki for 5 easy ways to help test, welcome members, and vote on features in under 5 minutes.

---

## 🔒 Non-Negotiable Safety & Engineering Rules

1. **Zero PII & Zero Plaintext API Keys**:
   - Never commit `passwords.yaml`, `.scloud/`, `.firebase/`, `.env*`, `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, or real member `.csv` exports.
   - All sensitive patterns are blocked in `.gitignore`.
2. **Strict Ticket-Driven Development (`1 Issue = 1 Worktree = 1 PR`)**:
   - Never push directly to `main`.
   - Every change must reference a GitHub Issue (`feat/#18-...`, `fix/#22-...`, `docs/#21-...`) and be developed in an isolated git worktree under `.worktrees/`.
3. **CodeWithAndrea Feature-First Architecture + `hooks_riverpod`**:
   - Organize features under `lib/src/features/<feature_name>/{domain,data,application,presentation}/`.
   - Prefer `HookConsumerWidget` (`hooks_riverpod` + `flutter_hooks`) for presentation widgets to eliminate `StatefulWidget` boilerplate and controller disposal bugs.
4. **Pure-Dart Tooling Over Bash**:
   - Checked-in repository automation scripts belong in `tool/*.dart` (see `tool/refuge_cli.dart` and `tool/generate_belong_icons.dart`).
5. **Red-Green-Refactor BDD Verification**:
   - Run `dart analyze` and `flutter test` before opening or merging any Pull Request.
   - Trigger `@coderabbitai review` on every PR and resolve critical findings.

---

## 🚀 Quickstart for Developers & Student Mentees

```bash
# 1. Create an isolated git worktree for your issue
git worktree add ../.worktrees/issue-<NUM>-<slug> -b feat/#<NUM>-<slug>

# 2. Run static analysis & widget/BDD tests
flutter analyze
flutter test

# 3. Run the app locally in Chrome (Dev flavor)
flutter run -d chrome -t lib/main_dev.dart
```

For AI-assisted development and token quota optimization, see [`less_expensive_llm_to_execute_guidance.md`](less_expensive_llm_to_execute_guidance.md) and our [Apprentice & Token Optimization Wiki Guide](https://github.com/neiljaywarner/refuge/wiki/Apprentice-and-Token-Optimization-Guide).
