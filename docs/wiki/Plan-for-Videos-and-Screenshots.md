# 📸🎬 Automated Videos & Screenshots Plan for Wiki, Pull Requests & GitHub Issues (Historical Archive)

> [!NOTE]
> **Historical Archive Document**: This document outlines the original asset hosting architecture for early video and screenshot capture. For current testing, device driving, and screenshot verification on real Pixel 9a hardware, see [`QA-and-Beta-Testing-Guide`](QA-and-Beta-Testing-Guide) and [`Engineering-Lessons-Learned-and-Accomplishments`](Engineering-Lessons-Learned-and-Accomplishments).

*Last Updated: October 18, 2026 (`2026-10-18T20:10:00-05:00`)*
*Canonical Plan File: `plan_to_make_videos_and_screenshots_for_wiki_and_prs_andgithub_issues.md`*

---

## 🎯 Why We Attach Screenshots & Videos to Every Release (`v0.5.5`, `v0.6.0-alpha`, `v0.8.0-alpha`)

So non-technical **Belong on the Spectrum** community members, church leaders, and student mentees can visually inspect new features right inside **GitHub Issues**, **Pull Requests**, and this **Wiki** without needing to compile the app locally!

---

## ⚡ How Our Visual Pipeline Works (Zero Main-Repo Bloat)

1. **Driven by Executable `test/features/*_feature.txt` Specs**:
   - `test/features/circle_spaces_navigation_feature.txt`
   - `test/features/feedback_and_feature_voting_feature.txt`
   - `test/features/member_profile_and_search_feature.txt`
2. **Captured Across Chrome Web, iOS Simulator & Android**:
   - **Chrome Web**: Driven via `marionette_mcp` / Flutter test rendering.
   - **iOS Simulator**: `xcrun simctl io booted screenshot` & `recordVideo`.
   - **Android (Pixel 9a / Emulator)**: `patrol` MCP `screenshot` & `adb shell screenrecord` + `ffmpeg` GIF conversion.
3. **Hosted in `refuge.wiki.git` (`assets/screenshots/`)**:
   - Pushing screenshots and `.gif` walkthroughs to `https://github.com/neiljaywarner/refuge.wiki.git` makes them immediately embeddable in Wiki pages AND in GitHub Issues/PRs via `https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/<file>`!
