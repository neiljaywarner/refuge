# 📥 Bringing Over Past Posts & Introductions (Spreadsheet / CSV Migration Guide)

> **Audience**: Community Organizers, Pastors, Moderators, and Non-Technical Volunteers  
> **Purpose**: Plain-English guide on how our past discussions, introductions, and prayer requests are safely brought into Belong on the Spectrum before October 31st, 2026.  
> **Technical Tool Reference**: `tool/import_circle_csv.dart` ([Issue #41](https://github.com/neiljaywarner/refuge/issues/41), [PR #98](https://github.com/neiljaywarner/refuge/pull/98))

---

## 1. What Is a CSV File? (In Plain English)

A **CSV** (Comma-Separated Values) file is simply a **spreadsheet**, just like an Excel sheet or a Google Sheet.

When you open a CSV in Excel, you see familiar rows and columns:
* **Column A**: The date and time the message was posted.
* **Column B**: The name of the member who posted it.
* **Column C**: Which room it was posted in (e.g., `Start Here` or `General Chat`).
* **Column D**: The actual message or reflection.

When our community leaves our old paid platform on October 31st, the platform lets community organizers download an archive of past messages as a spreadsheet.

---

## 2. Why Are We Importing Past Posts?

Over the past year, many members have shared meaningful introductions in `Start Here & Introduce Yourself`, posted prayer requests, and shared favorite autistic memes.

We believe **community memory matters**:
- New members who joined months ago shouldn't have to re-introduce themselves from scratch.
- Encouraging conversations and answered prayers shouldn't disappear into thin air.
- By importing the spreadsheet, our new Belong app feels lived-in, warm, and familiar from Day 1.

---

## 3. How the Rooms Map Over

Every room from the old platform connects directly to the matching room in Belong on the Spectrum:

| Room Name in Old Platform | Where It Goes in Belong | What Members Will Find |
| :--- | :--- | :--- |
| **Start Here & Introduce Yourself** | **`start_here`** | Member introductions and welcome stories |
| **Announcements** | **`announcements`** | Official fellowship notices and updates |
| **General Chat** | **`general_chat`** | Everyday community discussions |
| **Memes** | **`memes`** | Autistic & faith memes, funny pictures, and shared joys |
| **Online Resources / Videos** | **`resources_videos`** | Helpful articles, books, and sensory tools |
| **Actually Autistic Chat** | **`actually_autistic_chat`** | Peer support and autistic discussion |
| **Friends Chat** | **`friends_chat`** | Encouraging chat for friends and allies |
| **Family Chat** | **`family_chat`** | Space for parents, spouses, and family members |

---

## 4. How the 4-Step Import Works (Safe & Non-Destructive)

We follow a strict safety protocol so nothing ever gets lost or accidentally corrupted:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        4-STEP SAFE IMPORT PROCESS                      │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Download Archive (Organizer):                                       │
│    - Organizer clicks "Export" in the old platform's admin settings    │
│    - Downloads a ZIP file containing the past spreadsheets             │
│                                                                        │
│ 2. Safe "Preview Test" (Dry Run):                                      │
│    - The tool reads every row and checks for formatting errors         │
│    - Counts how many posts belong in each room                         │
│    - DOES NOT touch the live database yet (100% read-only test)        │
│                                                                        │
│ 3. Organizer Review:                                                   │
│    - Organizer reviews the summary report (e.g., "52 introductions,    │
│      38 general chats, 14 memes ready to import")                      │
│                                                                        │
│ 4. Final Import to Belong:                                             │
│    - Posts are placed into the new Belong rooms                        │
│    - Original dates and author names are preserved                     │
│    - Past conversations stay in their natural chronological order      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Our Strict Privacy & Safety Guarantee

As an open-source, public-friendly ministry project, we adhere to the highest standards of member privacy:

1. **Spreadsheets Are Never Committed to Git or Public Websites**:
   - Real member CSV spreadsheets are strictly blocked by automated repository filters (`.gitignore`).
   - Only synthetic, pretend test data (e.g., `member@example.com`) is used in automated developer tests.
2. **Private Member Information Stays Private**:
   - Phone numbers and private email addresses are never published to community feeds.
   - Posts only show the member's chosen display name and message text.
3. **No Overwrites**:
   - Importing past posts does not overwrite or delete any new posts made by members who are already exploring the app during our October 24–31 overlap week.

---

## 6. Official Circle.so Welcome & Overlap Invitation Post (Oct 24–31)

To begin the calm 7-day exploration overlap week, organizers post the official invitation in Circle.so **Announcements**:

> [!IMPORTANT]
> **High-Priority Maintainer Tracking**: [Issue #249](https://github.com/neiljaywarner/refuge/issues/249) (`*** 🚨 HIGH PRIORITY: Copy Circle.so Welcome Post into Circle to begin Oct 24–31 Overlap Week 🚨 ***`).  
> **Source Markdown File**: [`docs/circle_migration_invitation_post.md`](https://github.com/neiljaywarner/refuge/blob/main/docs/circle_migration_invitation_post.md)  
> **Self-Testing Guide**: [`docs/ascii_email_for_self_testing_alpha_verification.txt`](https://github.com/neiljaywarner/refuge/blob/main/docs/ascii_email_for_self_testing_alpha_verification.txt)  
> **Production App URL**: [https://belongonthespectrum.web.app](https://belongonthespectrum.web.app)

### Quick Copy Template for Organizers
```markdown
🎉 Welcome to Belong on the Spectrum — Our Calm-Tech Digital Home!

We are beginning our 7-day calm exploration week (Oct 24–31, 2026). Both our existing Circle community and our new Belong on the Spectrum home will remain open side-by-side so everyone can explore at their own unhurried pace.

🔗 Open the live app: https://belongonthespectrum.web.app
📖 How to test & help: Check out our self-testing guide in the app under "About Belong" or explore the spaces directory.
🕊️ Sensory Comfort: Try out the 4 WCAG AAA sensory themes (Clean Slate, Sage Botanical, Monastic Dark, High Contrast).
```

---

## 7. Questions?
If you have any questions or need assistance exporting past files, please reach out to the organizers or post in [GitHub Issue #41](https://github.com/neiljaywarner/refuge/issues/41) or [Issue #249](https://github.com/neiljaywarner/refuge/issues/249)!
