# 📸🎬 Execution Plan: Automated Videos & Screenshots for GitHub Wiki, Pull Requests & Issues

*File: `plan_to_make_videos_and_screenshots_for_wiki_and_prs_andgithub_issues.md`*
*Last Updated: October 18, 2026 (`2026-10-18T20:10:00-05:00`)*
*Designed for: Less-Expensive LLMs (`Gemini 3.8 Flash Medium`, `Gemini 4 Argon Low/Medium`, `Claude Sonnet 5.5 Medium`) & Student Mentees*
*Linked Status Files:*
- [`18Oct2026_session_plan_and_status.md`](18Oct2026_session_plan_and_status.md)
- [`less_expensive_llm_to_execute_guidance.md`](less_expensive_llm_to_execute_guidance.md)

---

## 🎯 1. Goal & Why This Matters

Non-technical Belong on the Spectrum community members, church organizers, and student mentees shouldn't have to build the Flutter app from source just to see what changed in **`v0.5.5`**, **`v0.6.0-alpha`**, or **`v0.8.0-alpha`**.

Every feature Pull Request, milestone GitHub Issue, and Wiki guide should include **actual screenshots (`.png`) and short 10–20 second walkthrough videos/GIFs (`.mp4` / `.gif`)** showing the calm UI in action across **Chrome Web, Android (Pixel 9a / Emulator), and iOS Simulator**.

---

## ⚡ 2. Zero-Secret, Zero-Repo-Bloat Storage Strategy (How to Host Images & Videos for GitHub Issues, PRs & Wiki)

Because `neiljaywarner/refuge` is a **public open-source repository**, we keep `main` fast while making images/videos render everywhere on GitHub:

1. **For the Live GitHub Wiki (`https://github.com/neiljaywarner/refuge/wiki`)**:
   - The Wiki is its own git repository (`https://github.com/neiljaywarner/refuge.wiki.git`, cloned locally at `/Users/neil/belongonthespectrum/.worktrees/refuge-wiki-live`).
   - Store curated screenshots and compact `<5MB` `.gif` / `.mp4` walkthroughs inside `/Users/neil/belongonthespectrum/.worktrees/refuge-wiki-live/assets/screenshots/` and commit/push them to `refuge.wiki.git`!
   - Reference them in Wiki markdown pages as:
     ```markdown
     ![Belong Home Feed & Spaces](assets/screenshots/v0_5_5_home_and_spaces.png)
     ```
2. **For GitHub Pull Requests & GitHub Issues (`https://github.com/neiljaywarner/refuge/pulls` & `/issues`)**:
   - Once an image or `.gif` is pushed to `refuge.wiki.git` (or a dedicated `docs/screenshots/` folder on the PR branch), its raw GitHub URL renders **inline** inside any GitHub Issue description, PR body, or PR comment!
   - Format for PRs and Issues:
     ```markdown
     ### 📸 Visual Verification (`v0.5.5` / `v0.6.0-alpha`)
     | Home Feed & Organizer Banner | Circle-Style Spaces Directory | 1-Tap Feature Voting & Literal Feedback |
     | :---: | :---: | :---: |
     | ![Home](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/home_feed.png) | ![Spaces](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/spaces_directory.png) | ![Voting](https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/feature_voting_sheet.png) |
     ```
   - *(Notice that `https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/<filename>` works automatically for any file pushed to `refuge.wiki.git` without bloating the main code repo!)*

---

## 🛠️ 3. Step-by-Step Capture Playbook by Platform (Token-Optimized)

> **Token-Saving Rule (`.agents/skills/marionette-token-saver/SKILL.md` & `.agents/skills/patrol-token-saver/SKILL.md`)**:
> Never call vision/screenshot tools in a loop to "find" buttons! Drive the UI deterministically using `test/features/*_feature.txt` keys/labels (`#subnav_spaces_tab`, `#open_feedback_and_voting_button`, `#tab_private_feedback`), and capture **1 clean screenshot per screen state**.

### Platform A: Fast Headless Golden / Widget Screenshots (`Zero Emulator Needed — 2 Seconds!`)
Even before booting Chrome or a simulator, any agent can generate crisp `800x900` PNG screenshots directly inside a `flutter test` using `matchesGoldenFile` or `RepaintBoundary` (`tool/capture_widget_screenshots.dart`):
1. Pump `SanctuaryApp(repository: LocalPostRepository())` inside a `RepaintBoundary`.
2. Capture PNGs for:
   - `01_home_feed_calm_sage.png` (Home Feed + Organizer Banner + Space Pills)
   - `02_circle_spaces_directory.png` (After tapping `#subnav_spaces_tab`)
   - `03_feature_voting_wip_board.png` (After tapping `#open_feedback_and_voting_button`)
   - `04_literal_3_intent_feedback.png` (After tapping `#tab_private_feedback`)
   - `05_community_search_and_memes.png` (Search tab)
   - `06_member_profile_badges.png` (After tapping `#belong_profile_avatar_button`)

### Platform B: Chrome Web (`marionette_mcp` + `test/features/*_feature.txt`)
1. Connect to the running Chrome debug session (`flutter run -d chrome --web-port 8080`).
2. Follow `test/features/circle_spaces_navigation_feature.txt` and `test/features/feedback_and_feature_voting_feature.txt`:
   - Navigate through `Feed` -> `Spaces` -> `Vote & Feedback` -> `Share Feedback` -> `Profile`.
   - Save screenshots to `/Users/neil/belongonthespectrum/.worktrees/refuge-wiki-live/assets/screenshots/`.

### Platform C: iOS Simulator (`xcrun simctl io booted`)
When an iOS Simulator is booted:
```bash
# Capture a crisp iOS PNG screenshot
xcrun simctl io booted screenshot /Users/neil/belongonthespectrum/.worktrees/refuge-wiki-live/assets/screenshots/ios_home_feed.png

# Record a 12-second MP4 walkthrough video while Patrol / Marionette drives the flow
xcrun simctl io booted recordVideo --codec=h264 /Users/neil/belongonthespectrum/.worktrees/refuge-wiki-live/assets/screenshots/ios_walkthrough.mp4
```

### Platform D: Android Physical Device (Pixel 9a) or Emulator (`patrol` MCP + `adb`)
When the Pixel 9a or Android Emulator is connected:
```bash
# Capture screenshot via Patrol MCP `screenshot` tool or ADB:
adb exec-out screencap -p > /Users/neil/belongonthespectrum/.worktrees/refuge-wiki-live/assets/screenshots/android_home_feed.png

# Record a 15-second walkthrough video:
adb shell screenrecord --time-limit 15 /sdcard/belong_walkthrough.mp4
adb pull /sdcard/belong_walkthrough.mp4 /Users/neil/belongonthespectrum/.worktrees/refuge-wiki-live/assets/screenshots/android_walkthrough.mp4
```
Convert `.mp4` to a lightweight inline `.gif` (so it auto-plays smoothly inside GitHub Wiki pages, Issues, and PR descriptions without requiring a click):
```bash
ffmpeg -y -i android_walkthrough.mp4 -vf "fps=10,scale=480:-1:flags=lanczos" android_walkthrough.gif
```

---

## 📋 4. Checklist for the Less-Expensive LLM (`v0.5.5` & `v0.6.0-alpha`)

- [ ] **Step 1**: Run `test/features/*_feature.txt` flows and capture the 6 core screenshots (`01_home_feed_calm_sage.png` .. `06_member_profile_badges.png`) + short `.gif` walkthrough into `/Users/neil/belongonthespectrum/.worktrees/refuge-wiki-live/assets/screenshots/`.
- [ ] **Step 2**: Push `refuge-wiki-live` to `https://github.com/neiljaywarner/refuge.wiki.git` so all `https://raw.githubusercontent.com/wiki/neiljaywarner/refuge/assets/screenshots/...` URLs are live.
- [ ] **Step 3**: Embed the 3-column screenshot & GIF table into:
  - Wiki [`Home.md`](https://github.com/neiljaywarner/refuge/wiki) and [`Belong-Community-Guide.md`](https://github.com/neiljaywarner/refuge/wiki/Belong-Community-Guide)
  - Open Pull Requests (`#47`, `#48`, `#49`, `#50`, `#51`)
  - Milestone `v0.5.5` & `v0.6.0-alpha` GitHub Issues (`#17`, `#18`, `#19`, `#20`, `#21`, `#22`, `#23`).
