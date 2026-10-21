# ❓ Questions for Product, Users & Alpha Testers

> **Target Audience**: Pastors, Community Organizers, Neurodivergent Members, and Alpha Testers  
> **Related Issues**: [#243](https://github.com/neiljaywarner/refuge/issues/243), [#241](https://github.com/neiljaywarner/refuge/issues/241), [#239](https://github.com/neiljaywarner/refuge/issues/239), [#236](https://github.com/neiljaywarner/refuge/issues/236), [#101](https://github.com/neiljaywarner/refuge/issues/101)  
> **Master Dashboard**: [`status.md`](https://github.com/neiljaywarner/refuge/blob/main/status.md)

---

## 1. 🎯 Purpose & Why We Ask

When building software with autonomous AI coding agents, agents frequently make **architectural guesses** based on theoretical design guidelines. Some of these guesses are genuinely innovative calm-tech patterns; others can be tone-deaf, overly paternalistic, or simply miss practical real-world human needs.

This document compiles the **key product questions and design tradeoffs** identified during our pre-alpha testing for review by **Marty (Organizer)**, **pastors**, and **alpha testers**.

---

## 2. 🔔 Question 1: Real-Time Instant Alerts vs. Batched Calm Digests (The Service Worker Dilemma)

### The AI "Guess"
During early PWA development, the AI agent created `web/firebase-messaging-sw.js` with an aggressive calm-tech filter:
```javascript
tag: 'belong-calm-digest',
renotify: false, // Never chimes multiple times
silent: true,   // Default 100% silent
```
The agent reasoned: *"Autistic adults experience sensory overload, so all notifications must be silent, batched, and deduplicated into a single background digest."*

### Why We Are Questioning This
- **Paternalism vs. Autonomy**: True calm-tech is about giving members **choice**, not deciding for them that they can never receive an audible notification.
- **Urgent Moments**: If a friend sends a direct message (*"Are you at church yet?"*) or someone posts a time-sensitive prayer request, a silent daily digest delivered 6 hours later defeats the purpose of communication.
- **Normal Real-Time Expectations**: Many members expect real-time notifications for 1-on-1 conversations and urgent announcements, while preferring batched digests for general room chat.

### The Proposed Solution (Vote in App!)
We have added this feature to the **In-App Feature Voting Board** (Issue [#243](https://github.com/neiljaywarner/refuge/issues/243)):
- **Option A (Real-Time)**: Immediate banner + gentle chime for Direct Messages and direct post replies.
- **Option B (Calm Batched Digest)**: Silent morning (9:00 AM) and evening (6:00 PM) summary.
- **Option C (Granular Tiers - Recommended)**: Real-time for DMs & @mentions; calm batched digest for space reflections.

> **Question for You**: *Do you prefer immediate real-time notifications when someone interacts with you, or do you prefer scheduled quiet digests?*

---

## 3. ⛪ Question 2: ICOC Church Affiliation Badge Placement

### Background
Per Marty's SMS specification, every member profile requires answering:  
*"Which ICOC church do you attend?"* (with the explicit option *"I am not a member of an ICOC church"*).

### The Tradeoff
- **Option A (Directory & Profile Sheet Only)**: Affiliation is visible when viewing a member's profile in the Members Directory or tapping their avatar. Keeps the main reflection feed visually calm and clutter-free.
- **Option B (Everywhere on Reflection Cards)**: Displays `⛪ DFW Church` or `🌱 Welcoming Visitor` as a badge next to every author name on the main feed. Increases church fellowship identity, but adds visual density to every card.

> **Question for Organizers**: *Should church affiliation badges appear on every reflection card in the feed, or remain inside member profiles?*

---

## 4. ✉️ Question 3: Unverified Email Community Policy

### Background (Issue [#236](https://github.com/neiljaywarner/refuge/issues/236))
When a user signs up with email & password, Firebase Auth sets `isEmailVerified: false` until they click the link in their verification email.

### The Tradeoff
- **Strict Gating**: Block all publishing until email is verified (prevents spam bots, but introduces friction and potential drop-off for autistic members struggling with email access).
- **Calm Grace Period (Recommended)**: Unverified members can immediately browse spaces, adjust sensory themes, and save reflections. A gentle, non-blocking reminder banner appears when attempting to publish their first reflection (*"Please verify your email to share reflections"*).

---

## 5. 🎨 Question 4: Home Screen Visual Density ("When in Doubt, Leave it Out")

### Background (Issue [#239](https://github.com/neiljaywarner/refuge/issues/239))
Our latest Google Pixel 9a testing revealed that the home screen currently stacks 7 vertical controls (Top bar $\rightarrow$ Sub-nav $\rightarrow$ Welcome banner $\rightarrow$ Space chips $\rightarrow$ Gathering stats $\rightarrow$ 300px Composer $\rightarrow$ Filter chips) before displaying the first post.

### Proposed Simplification:
- Replace the permanent 300px composer box with a 1-tap quiet pill:  
  `[ ✍️ Share an unhurried thought, Scripture insight, or reflection... ]`  
  Tapping it slides up the composer sheet only when the member wants to write.
- Move the Gathering Stats banner into the About dialog.
- Ensure the first community post is visible immediately above the fold on mobile phones.

---

## 6. 🗳️ How to Share Your Feedback

1. **In-App Voting Board**: Tap **"Vote & Feedback"** in the top navigation bar to upvote your priorities or propose new ideas.
2. **Literal 3-Intent Feedback**: Switch to the **Private Feedback** tab to send private thoughts directly to the organizers.
3. **GitHub Discussions & Issues**: Comment on issues [#243](https://github.com/neiljaywarner/refuge/issues/243) and [#239](https://github.com/neiljaywarner/refuge/issues/239).