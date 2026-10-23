# Bug Reporting & In-App Feedback SDK Evaluation

> **Evaluated For**: Belong on the Spectrum (`belongonthespectrum.com`)  
> **Date**: October 22, 2026  
> **Context**: Evaluating in-app diagnostic feedback SDKs (Bugsee, ShakeBugs, Sentry, and In-House Canvas) with opt-in controls in General Settings.

---

## 1. Executive Summary & Verdict

For our soft launch and community cutover, **our custom in-house module (`FeedbackDrawingCanvas` + `PrivateFeedbackRouter`) is the winner and default choice**:
- **\$0/month forever** (Zero vendor lock-in or recurring SaaS invoices).
- **100% Cross-Platform**: Works identically across Flutter Web, PWA, Android, and iOS.
- **Privacy First**: Private notes are written to Firestore. The drawing is a placeholder storage URL, not a file on a GitHub issue ([#407](https://github.com/neiljaywarner/refuge/issues/407)).
- **Zero Heavy SDK Dependencies**: No bloated native binaries or binary tracking SDKs running in the background.

If leadership desires deeper automated crash symbolication and network stack traces in the future, **Sentry** is the recommended external SDK due to its generous **permanent free tier** (5,000 errors/month free) and official `sentry_flutter` web support, accessible via an opt-in toggle in the app Settings screen.

---

## 2. Head-to-Head Comparison Table

| Dimension | Bugsee | ShakeBugs (Shake) | Sentry (Top Competitor) | In-House Belong Canvas (Active) |
| :--- | :---: | :---: | :---: | :---: |
| **Free Tier Allowance** | ❌ Trial only / \$99+/mo | ⚠️ 10 reports/mo | 🟢 **5,000 errors/mo free forever** | 🟢 **Unlimited free forever (\$0)** |
| **Flutter Web / PWA Support** | ❌ Incomplete | ❌ Mobile only | 🟢 **First-class Web + Mobile** | 🟢 **100% First-Class Everywhere** |
| **Drawing / Markup Canvas** | ✅ Built-in | ✅ Built-in | ⚠️ Basic text prompt | 🟢 **Custom sensory canvas** |
| **Private Repo Dispatch** | ❌ Proprietary portal | ❌ Proprietary portal | ⚠️ Webhook required | ⚠️ **Firestore note only. GitHub attachment is open in [#407](https://github.com/neiljaywarner/refuge/issues/407)** |
| **Member Privacy (Zero-PII)** | ⚠️ Captures full video | ⚠️ Captures screen | 🟢 Text masking available | 🟢 **100% Member-Controlled** |
| **App Bundle Impact** | Heavy (~8-12 MB) | Medium (~4-6 MB) | Lightweight (~2-3 MB) | **0 MB (Pure Flutter `dart:ui`)** |

---

## 3. Deep-Dive Analysis by Tool

### Option 1: Bugsee
- **Overview**: Records video replays of user actions alongside console logs and network requests.
- **Why It Fails Belong's Needs**:
  - High recurring cost (\$99–\$199/month minimum) after brief trial.
  - Autistic members discussing sensitive personal experiences, prayer requests, or sensory overwhelm should not have background video recordings captured without explicit active consent.
  - Web/PWA support is secondary to native iOS/Android.

### Option 2: ShakeBugs (Shake)
- **Overview**: Users shake their physical device to capture a screenshot and annotate it with drawing tools.
- **Why It Fails Belong's Needs**:
  - Free tier is capped at **only 10 tickets per month**, which is exhausted within days of community onboarding.
  - Paid tier starts at \$160/month.
  - Lacks Flutter Web support; useless for members visiting on desktop or mobile web browsers.

### Option 3: Sentry (`sentry_flutter`) — Recommended Future SDK
- **Overview**: The industry standard open-core observability and crash diagnostic platform.
- **Key Strengths**:
  - **Developer tier is permanently free forever**: 5,000 errors/month, 10,000 performance transactions, and 50 session replays at \$0.
  - Official, mature `sentry_flutter` package with full Web, Android, iOS, and Desktop compatibility.
  - Configurable data scrubbing (automatically hides email addresses, passwords, and private text fields).
- **Settings Integration**: Can be enabled as an opt-in toggle in `BelongSettingsScreen` (`Diagnostic Logging -> Opt into Sentry Diagnostics`).

### Option 4: Belong In-House Canvas (`FeedbackDrawingCanvas`) — Active Implementation
- **Overview**: Built with pure Flutter `CustomPainter` and `dart:ui` without adding any third-party dependencies.
- **Key Strengths**:
  - Lets members draw arrows, circles, and handwritten notes on captured screenshots.
  - Offers 6 calm, sensory-friendly palette colors and fine/bold pen widths.
  - Automatically formats GitHub-flavored markdown with embedded image attachment.
  - The note is stored in Firestore. The drawing URL is a placeholder and is not attached to a GitHub issue ([#407](https://github.com/neiljaywarner/refuge/issues/407)).
  - 17/17 automated unit and Patrol widget tests passing green.
