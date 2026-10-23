---
name: marionette-live-showcase
description: Live feature showcase and interactive presentation driver using Marionette MCP and CLI across physical Pixels, Android emulators, and Chrome browsers. Use when demonstrating Belong on the Spectrum live to users or stakeholders.
---

# Marionette Live Feature Showcase & Demo Driver Skill

This skill operationalizes interactive live demonstrations and automated feature walkthroughs for **Belong on the Spectrum** using LeanCode Marionette over the Dart VM Service WebSocket.

## 1. When to Use
- **Stakeholder / User Demonstrations**: Presenting the app's features smoothly at comfortable speeds (`--speed slow` or `--interactive`).
- **Milestone Feature Verification**: Running an automated tour across all primary UI milestones (Sensory Themes, Spaces, Profiles, Voting, Notifications) with instant milestone screenshots (`--capture`).
- **Hardware & Multi-Client Matrix**: Demonstrating live sync between a physical Pixel (`56091JEBF14039` / `58221JEBF20835`), an Android emulator (`emulator-5554`), or Chrome Web.

## 2. Command Line Execution

```bash
# Automated normal-speed walkthrough on auto-detected device:
dart run tool/marionette_demo.dart

# Or via the pre-approved bash wrapper:
tool/marionette_demo.sh

# Interactive presentation mode (pauses between features for explanation):
dart run tool/marionette_demo.dart -i --speed slow

# Capture full-resolution milestone screenshots to /tmp:
dart run tool/marionette_demo.dart --capture

# Explicitly target connected Pixel or Emulator:
dart run tool/marionette_demo.dart -d 56091JEBF14039
dart run tool/marionette_demo.dart -d emulator-5554
dart run tool/marionette_demo.dart -d chrome
```

## 3. Automated Milestone Tour
The driver executes the following 7 milestones sequentially:
1. **Header & Infinity Monogram**: Verifies the brand logo, scripture anchor (Psalm 139), and calm title.
2. **Sensory Themes & Contrast**: Toggles High Contrast mode (yellow/black), validates theme persistence, and restores the Sage theme.
3. **Fellowship Spaces Directory**: Navigates from Feed to Spaces, showcasing categorized fellowship rooms.
4. **Member Profiles & Monograms**: Opens the Member Directory, displaying comfort badges, church affiliations, and generated monograms.
5. **Feature Voting & Feedback**: Opens the bottom sheet for neurodivergent community feedback and feature upvoting.
6. **Calm Notifications**: Navigates to the Calm Notifications tab with inbox, mentions, threads, and following filters.
7. **Return to Sanctuary Feed**: Restores home view.

## 4. MCP Server Integration
AI agents can also drive these milestones step-by-step using the Marionette MCP server:
- `connect` to `ws://127.0.0.1:<PORT>/ws`
- `get_interactive_elements` to discover active keys (under 150 tokens)
- `tap` on interactive keys (`home_high_contrast_toggle_button`, `subnav_spaces_tab`, `open_feedback_and_voting_button`)
- `take_screenshots` at the completion of milestones
