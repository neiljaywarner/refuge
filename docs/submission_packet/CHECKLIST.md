# ✅ Serverpod Hackathon — Pre-Flight Submission Checklist
**Project**: Sanctuary (Refuge)  
**Target Submission Window**: Tuesday, October 14, 2026 (Before 9:00 PM CDT)  
**Last Updated**: Tuesday, October 14, 2026 at 12:06 AM CDT  

---

## 1. 🧪 Code & Quality Gate Verification
- [x] **Static Analysis Clean**: Run `flutter analyze` — Must report `No issues found!`. *(Verified: 0 issues, 1.8s)*
- [x] **Automated Tests Passing**: Run `flutter test` — All 11 unit & widget tests pass. *(Verified: 11/11 pass, 4s)*
- [x] **Single-File Integrity**: Ensure `lib/main.dart` compiles and runs standalone without missing imports.
- [x] **Clean Decoupling**: Ensure all UI interactions communicate strictly through abstract `PostRepository`.
- [ ] **Serverpod End-to-End Live Stream**: Start Docker Postgres (`localhost:8090`), start Serverpod server (`dart bin/main.dart`), and run client with `--dart-define=BACKEND=serverpod`.

---

## 2. 🌐 Deployment & Live Demo Verification
- [x] **Web Release Build**: Run `flutter build web --release` — Compiles cleanly to `build/web`.
- [x] **Firebase CDN Preview**: Deployed and active at `https://ministry-demos--sanctuary-cnf3fnh7.web.app`.
- [x] **Asset Integrity**: Verified HTTP 200 on `index.html`, `flutter.js`, and `main.dart.js`.
- [x] **Sensory Themes**: Verified Sage, Clean Slate, Monastic Dark, and High Contrast on live web app.
- [x] **Fellowship Space Navigation**: Verified Main Hall, Quiet Room, Prayer & Care, Gratitude Journal.
- [x] **Qualitative Affirmations**: Verified `🙏 Praying`, `🤍 Standing With`, `🕊️ Peace`, `🌱 Encouraged`.

---

## 3. 🎥 Demo Video & Media Artifacts (Non-Negotiables)
- [ ] **Length**: 2:00 to 2:45 minutes (strictly under 3:00 minute hard ceiling).
- [ ] **Dual-Device Live Demo**: Side-by-side demonstration (e.g. macOS desktop app + Chrome browser or iOS Simulator) showing real-time reflection sync.
- [ ] **Audio Voiceover**: Clear, unhurried, calm vocal narration matching the storyboard script in [`VIDEO_SCRIPT_AND_STORYBOARD.md`](file:///Users/neil/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/docs/submission_packet/VIDEO_SCRIPT_AND_STORYBOARD.md).
- [ ] **Video Host**: Upload to YouTube as "Public" or "Unlisted" (or Vimeo). Ensure 1080p60 resolution.
- [ ] **Thumbnail**: High-resolution image showing Sanctuary in Sage mode with the calm-tech tagline: *"Sanctuary — Quiet Fellowship in an Anxious World"*.

---

## 4. 🐙 GitHub Repository Hygiene
- [x] **Public Visibility**: Repo is public at `https://github.com/njwandroid/refuge_13oct_2026_prototype_for_serverpod_hackathon`.
- [x] **Pristine History**: All changes tracked through GitHub issues, feature branches, and squash-merged PRs.
- [x] **Documentation Linked in README**:
  - [x] Architecture Decision Records (`docs/adr/`)
  - [x] Non-Technical Team Wiki (`docs/wiki/`)
  - [x] Competitor Analysis (`docs/COMPETITOR_ANALYSIS.md`)
  - [x] Product Requirements Document (`docs/PRD.md`)
  - [x] Serverpod Integration Guide (`serverpod_integration.md`)
- [ ] **Release Tag**: Cut a git release tag `v1.0.0-hackathon` prior to submitting.

---

## 5. 📝 Devpost Form Fields (Ready to Copy-Paste)
- [ ] **Project Name**: Sanctuary (Refuge) — Calm-Tech Fellowship
- [ ] **Tagline**: An unhurried, zero-badge fellowship platform built on Serverpod 4 & Flutter.
- [ ] **Video URL**: Paste YouTube link.
- [ ] **Live Demo URL**: `https://ministry-demos--sanctuary-cnf3fnh7.web.app`
- [ ] **GitHub Repository URL**: `https://github.com/njwandroid/refuge_13oct_2026_prototype_for_serverpod_hackathon`
- [ ] **Inspiration, What it Does, How We Built It**: Copy text from [`DEVPOST_SUBMISSION_DRAFT.md`](file:///Users/neil/AndroidStudioProjects/refuge_13oct_2026_prototype_for_serverpod_hackathon/docs/submission_packet/DEVPOST_SUBMISSION_DRAFT.md).
- [ ] **Built With**: `dart`, `flutter`, `serverpod`, `postgresql`, `docker`, `redis`, `websockets`, `firebase-hosting`.

---

## 6. 🏁 Final Sanity Check
- [ ] Open Devpost submission in an incognito browser window.
- [ ] Click every link (GitHub repo, live web demo, video) to verify zero 404s or permissions blocks.
- [ ] Submit and take a screenshot of confirmation!
