Source: https://docs.google.com/document/d/1mD1ZPmppunP9NlgW8UM-fW41LFm_v-JGR9kIE7gp0dY/edit

# Refuge – Bema Group Demo Preparation

*Review draft for Gemini · Prepared Sat Nov 21, 2026 from status reported by Neil's assistants · Items marked **Open question** need Neil's decision or verification.*

## 1\. Summary

**The demo is close.** Refuge already has most of what Carina's Discord does: Spaces work like Discord text channels (topic rooms with posts, comments, and reactions), and the GetStream video call mostly works, including guest invite links and screen share. The remaining gaps are **mostly configuration and polish**, not new product:

- Set up a Bema community (or use Belong as a stand-in) with her channel names.  
- Provide a stable, recurring weekly call link.  
- Accept or smooth the difference between Discord's real-time chat feel and Refuge's threaded posts.  
- Accept that Refuge has no always-on voice rooms (the call is a meeting you join).  
- Merge PR \#981 so comments save reliably.

Refuge is the platform; **Belong on the Spectrum** is its first live community. No Bema-branded community exists yet.

## 2\. Demo goal and audience

- **Audience:** Carina, who leads a Bema discussion group. Bema is The BEMA Podcast from BEMA Discipleship, hosted by Marty Solomon and others, which walks through the historical context of the Bible (https\://www\.bemadiscipleship.com). Groups listen to episodes, usually in order, and then discuss; Carina's group meets weekly.  
- **Goal:** Show that a rhythm-first Refuge can replace her Discord for (a) the weekly group video call and (b) channels such as scripture videos and prayer requests.  
- **Success for the demo:** Carina can picture her group's weekly rhythm living in Refuge and names what would need to change before she'd try it with the group.  
- **Open question:** Is the demo an informal walkthrough with Neil, or should Carina try it hands-on on her own Pixel 9a?

## 3\. Discord vs Refuge Spaces

| Discord concept | Refuge equivalent today | Gap | Type of gap |
| :---- | :---- | :---- | :---- |
| Server | Community (Belong on the Spectrum is live) | No Bema community yet | Configuration |
| Text channel (e.g. \#prayer-requests, \#scripture-videos) | Space (topic room with posts, comments, reactions). Belong has Start Here, Announcements, General Chat, Online Resources / Videos, Prayer Sanctuary | Her channel names not set up | Configuration |
| Real-time chat messages | Threaded posts with comments; DMs for 1:1 | Feels less like live chat | Polish / UX expectation |
| Reactions, GIFs | Reactions (including praying/relate), Giphy | None known | — |
| Weekly voice/video call | GetStream preview call with guest links and screen share | Preview link (?call=monthly), not a stable recurring weekly link; some device combos unproven | Configuration \+ verification |
| Always-on voice channels | None; calls are meetings you join | No drop-in voice rooms | Product difference (likely acceptable — **Open question**) |
| Member list | Member directory | None known | — |
| Notifications | In-app notifications | Large-text notification UI in PR \#984 | Polish |
| Welcome / rules channel | Start Here space, organizer welcome message | Bema-specific wording | Configuration |
| Moderation (delete own messages) | Members can't delete their own posts (\#776) | Missing | Small feature |

**Open question:** Does Carina's group rely on real-time chat during the week, or mainly on posting and replying? This decides whether threaded posts are "good enough" for the demo.

## 4\. Demo scenario and script

Recommended format: **signed-in walkthrough on dev**, a **test call with a guest join**, and **Belong as a stand-in or a second community configured with her channel names**.

1. **Welcome (2 min).** Sign in on dev. Show the organizer welcome message and Start Here space.  
2. **Her channels (5 min).** Open the Spaces that map to her Discord: Prayer Sanctuary (prayer requests) and Online Resources / Videos (scripture videos). If a Bema stand-in is configured, use her channel names. Post a sample prayer request; react with "praying"; add a comment.  
3. **Weekly discussion (5 min).** Show a post for this week's episode in a discussion Space and a short comment thread. (Requires \#981 for reliable comment saves.)  
4. **Weekly call (5–10 min).** Start the GetStream call from the preview link, have a second device join via a guest invite link, and show screen share. Keep audio quiet/muted near Carina during setup.  
5. **Extras (2 min).** Member directory, DMs, sensory themes and large text, Vote & Feedback.  
6. **Feedback (5 min).** Ask what she'd miss from Discord and what would need to be true to try it with the group.

**Open question:** Should the scripted episode post use a real Bema episode title, or a placeholder?

## 5\. Current readiness

| Feature | Status | Environment | Owner / PR |
| :---- | :---- | :---- | :---- |
| Sign-in | Works | Dev/preview | — ; a11y \#973/\#974/\#976 merged, not on prod |
| Feed / reflections with comments | Feed works; comments not saving reliably until \#981 ships (reported on prod; verify on dev) | Dev and prod | \#978 → PR \#981 (awaiting CodeRabbit re-review, then Neil) |
| Comment double-send | Fixed | Dev | \#979 |
| Reactions, Giphy, DMs | Works | Dev/preview | — |
| Notifications | Works; large-text UI in progress | Dev/preview | PR \#984 (CI-green) |
| Spaces (incl. Prayer Sanctuary, Online Resources / Videos) | Works | Dev/preview | — |
| Links | Works | Dev/preview | — |
| Member directory, sensory themes, Vote & Feedback, organizer welcome | Works | Dev/preview | — |
| GetStream video call \+ guest links \+ screen share | Mostly works (preview) | On main; dev currently lacks call flag | Needs flagged dev rebuild after \#981 |
| Large-text call UI | CI-green | Not merged | PR \#983 (part of \#935) |
| Two-way call: Pixel 9a APK host \+ desktop Chrome guest | Proven | Preview | — |
| Web-to-web, APK-to-APK calls | Not fully proven | Preview | **Open question:** who verifies? |
| Recurring weekly call link | Not built (preview link only) | — | Configuration |
| Bema community / her channel names | Not set up | — | Configuration |
| Invite-mint hardening | Reviewed, not deployed; ban checker unwired; no revoke-my-invites | — | \#982 |
| Guest/token follow-ups | Open | — | \#914–\#920 |
| Delete own post | Missing | — | \#776 |
| Course video (Mux HLS, captions, Educator Studio) | Separate Auxano POCs, not in Refuge | Separate apps | Port planned for Jan 1 |
| Production deploy | Prod still Nov 4 v0.9.9; deploy last blocked on Firebase CLI auth | Prod | Issue \#765 |

## 6\. Must-fix before the demo (in order)

1. **Merge PR \#981** after CodeRabbit re-review, so comments save (\#978).  
2. **One flagged dev web \+ Android rebuild** to turn the call preview back on (merges to main currently deploy dev without the call flag).  
3. **Configure her channels:** either rename/add Spaces in Belong as a stand-in, or create a second community with her channel names (placeholders such as Prayer Requests, Scripture Videos, Weekly Discussion until Carina's actual channel names are known). **Open question:** which option?  
4. **Stable weekly call link:** pick one reusable preview call link for the demo and label it as "the weekly call." **Open question:** is a fixed preview link acceptable for the demo, or is a scheduled recurring call required?  
5. **Verify the call path to be used** (device combo for the demo) end-to-end, quietly.

## 7\. Nice-to-haves

- Merge PR \#983 (large-text call UI) and PR \#984 (notification/sign-in large text).  
- Merge \#980 (checklist docs).  
- Members can delete their own posts (\#776).  
- Deploy \#982 invite-mint hardening, wire the ban checker, add revoke-my-invites.  
- Make threaded posts feel more like live chat (e.g. faster refresh or a chat-style Space). **Open question:** in scope?  
- Seed sample content: a prayer request, a scripture video link, and a weekly episode discussion post.  
- Packages/refuge extraction (\#924) and public refuge-demo repo (\#925) — demo checklist items, likely not needed for Carina's demo. **Open question.**

## 8\. Environment and device plan

- **Environment:** Dev ([https\://dev-belongonthespectrum.web.app/](https://dev-belongonthespectrum.web.app/)), signed in. Do not use prod ([https\://belongonthespectrum.web.app/](https://belongonthespectrum.web.app/)) — it is the Nov 4 v0.9.9 build and comments are broken until \#981 ships. Team norm: publish only to dev/preview unless Neil says otherwise.  
- **Host device:** Pixel 9a with the preview APK (proven as call host).  
- **Guest device:** Desktop Chrome via guest invite link (proven).  
- **Backup:** No fallback for a failed call is decided yet (see the dry-run checklist). Screen share itself works from web, Chrome, and the Mac app, so content can be shown during the call.  
- **Accounts:** **Open question:** which test accounts are signed in, and does Carina use her own account?

## 9\. Dry-run checklist

- [ ] \#981 merged and comment save verified on dev  
- [ ] Flagged dev web \+ Android rebuild done; call button visible  
- [ ] Preview APK installed on host Pixel 9a  
- [ ] Bema channels configured (stand-in or second community)  
- [ ] Sample posts seeded in each channel  
- [ ] Weekly call link chosen and tested  
- [ ] Guest invite link tested from desktop Chrome  
- [ ] Screen share tested  
- [ ] Audio tested quietly (headphones/muted), not around Carina  
- [ ] Reactions, comments, notifications checked end-to-end  
- [ ] Backup plan ready if the call fails (for example a recorded walkthrough — **Open question**)

## 10\. Risks and mitigations

| Risk | Mitigation |
| :---- | :---- |
| Comments fail to save | Merge \#981 first; demo on dev only; verify in dry run |
| Call not visible on dev | Flagged rebuild after \#981 |
| Call fails on an unproven device combo | Use proven combo (Pixel 9a APK host \+ desktop Chrome guest) |
| Threaded posts feel unlike Discord chat | Frame Spaces as channels; ask Carina what matters most |
| No always-on voice rooms | Position the weekly call as the group's meeting; confirm she doesn't need drop-in voice |
| Guest link abuse before \#982 deploys | Use links only for the demo; keep them private |
| Testing disrupts Carina | Quiet audio tests; don't ask her to test until comments are solid |
| GCP billing account closed (Storage, backups) | **Open question:** does this affect any demo feature? |
| Prod deploy blocked (\#765) | Not needed; demo on dev |

## 11\. Open questions for Neil

1. Belong as a stand-in, or a second community with her channel names?  
2. What are Carina's exact Discord channel names?  
3. Is a fixed preview call link acceptable, or must the weekly call be scheduled/recurring for the demo?  
4. Does she need real-time chat or always-on voice, or are threaded posts plus a weekly call enough?  
5. Target demo date?  
6. Should course/scripture video be shown from the Auxano POCs, or wait for the Jan 1 port?  
7. Does the closed GCP billing account block anything in the demo?  
8. Who verifies web-to-web and APK-to-APK calls, and are they needed for this demo?
