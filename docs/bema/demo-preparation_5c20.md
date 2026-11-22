Source: https://docs.google.com/document/d/1mD1ZPmppunP9NlgW8UM-fW41LFm_v-JGR9kIE7gp0dY/edit

# Refuge – Bema Group Demo Preparation

*Review draft for Gemini · Prepared Sat Nov 21, 2026 from status reported by Neil's assistants · Items marked **Open question** need Neil's decision or verification.*

## 1\. Summary

**Close for a guided call demo once \#981 and the flagged rebuild land; not yet ready for a group switch.** Refuge has topic rooms (Spaces) with posts, comments, and reactions, and a GetStream video call with guest invite links and screen share that works on the proven device path. Spaces are threaded rooms, not live chat, and they are hardcoded in the app (two Dart lists), so they are not organizer-configurable. The remaining gaps are **a mix of engineering steps, code changes, and product work**, not new product:

- Use Belong as the stand-in. Her channel names would be a code change, and a separate Bema community needs white-label work (\#924/\#925).  
- Use one reusable preview call link (?call=monthly) after a flagged rebuild. A real scheduled weekly call with calendar invites is product work.  
- Be honest that Spaces are threaded rooms, not live Discord chat (a chat-style Space is Phase 2 or later).  
- Accept that Refuge has no always-on voice rooms (the call is a meeting you join).  
- Merge PR \#981 and verify a comment saves on the demo build (comments can fail on dev too, not only prod).

Refuge is the platform; **Belong on the Spectrum** is its first live community. No Bema-branded community exists yet.

## 2\. Demo goal and audience

- **Audience:** Carina, who leads a Bema discussion group. Bema is The BEMA Podcast from BEMA Discipleship, hosted by Marty Solomon and others, which walks through the historical context of the Bible (https\://www\.bemadiscipleship.com). Groups listen to episodes, usually in order, and then discuss; Carina's group meets weekly.  
- **Goal:** Show how Refuge could host (a) the weekly group video call and (b) channels such as scripture videos and prayer requests, and learn what a real switch would need. The rhythm-first "This Week" home is not built, so the demo uses a hand-made "this week" post instead and doesn't promise one.  
- **Success for the demo:** Carina gives a clear yes or no to a pilot ("run next week's call here, with Discord as backup") and names what would need to change first.  
- **Open question:** Is the demo an informal walkthrough with Neil, or should Carina try it hands-on on her own Pixel 9a?

## 3\. Discord vs Refuge Spaces

| Discord concept | Refuge equivalent today | Gap | Type of gap |
| :---- | :---- | :---- | :---- |
| Server | Community (Belong on the Spectrum is live) | No Bema community yet; needs white-label work (\#924/\#925) | Code or product work (not config) |
| Text channel (e.g. \#prayer-requests, \#scripture-videos) | Space (topic room with posts, comments, reactions). Belong has Start Here, Announcements, General Chat, Weekly Study, Prayer Sanctuary, and Online Resources / Videos (Prayer Sanctuary and Weekly Study are in the feed space bar; Online Resources / Videos is in the Spaces directory) | Spaces are hardcoded (two Dart lists); her channel names need a code change | Code or product work (not config) |
| Real-time chat messages | Threaded posts with comments; DMs for 1:1 | Feels less like live chat | Polish / UX expectation |
| Reactions, GIFs | Reactions (including praying/relate), Giphy | None known | — |
| Weekly voice/video call | GetStream preview call with guest links and screen share | Preview link (?call=monthly), not a stable recurring weekly link; some device combos unproven | Code or product work (not config) \+ verification |
| Always-on voice channels | None; calls are meetings you join | No drop-in voice rooms | Product difference (likely acceptable — **Open question**) |
| Member list | Member directory | None known | — |
| Notifications | In-app notifications | Large-text notification UI in PR \#984 | Polish |
| Welcome / rules channel | Start Here space, organizer welcome message | Bema-specific wording (whether the welcome message is editable without code is unverified) | Code or product work (not config) |
| Moderation (delete own messages) | Members can't delete their own posts (\#776) | Missing | Small feature |

**Open question:** Does Carina's group rely on real-time chat during the week, or mainly on posting and replying? This decides whether threaded posts are "good enough" for the demo.

## 4\. Demo scenario and script

Step 0, before any demo: talk to Carina first (using "A note for Carina"). Learn her real channels, which Discord features she uses (forum channels, events, voice), what her members are on (iPhone or Android), and which episode they're on, then adjust this script.  
Recommended format: **signed-in walkthrough on dev**, a **test call with a guest join**, and **Belong as the stand-in, being careful what is visible (real members and prayer requests). A separate seeded community would be safer but needs \#924/\#925. Never use prod.**

1. **Welcome (2 min).** Sign in on dev. Show the organizer welcome message and Start Here space.  
2. **Her channels (5 min).** Open the rooms that map to her Discord: Prayer Sanctuary and Weekly Study from the feed space bar, and Online Resources / Videos from the Spaces directory (it isn't in the bar). Show the seeded prayer request and react with "praying". Don't add a comment unless \#981 is merged and comment save is verified on this build.  
3. **Weekly discussion (5 min).** Show the seeded "this week" post in Weekly Study, with the episode deep link, listen-by date, and call link. It's a hand-made post: there is no "This Week" home yet, so don't promise one. No live commenting unless \#981 is verified on this build.  
4. **Weekly call (5–10 min).** Start the GetStream call from the preview link on the proven path only (Pixel 9a preview APK host, desktop Chrome guest via invite link), on headphones, and show screen share. If it fails, switch to her existing Discord call link. Keep audio quiet/muted near Carina during setup.  
5. **Extras (2 min).** Member directory, DMs, sensory themes and large text, Vote & Feedback.  
6. **Feedback (5 min).** Ask what she'd miss from Discord, then make the pilot ask: "Run next week's call here, with Discord as backup?"

**Open question:** Should the scripted episode post use a real Bema episode title, or a placeholder?

## 5\. Current readiness

| Feature | Status | Environment | Owner / PR |
| :---- | :---- | :---- | :---- |
| Sign-in | Works | Dev/preview | — ; a11y \#973/\#974 merged Nov 21 and \#976 merged Nov 19; not on prod |
| Feed / reflections with comments | Feed works; comment saves can fail on dev (ci-dbfcc70) and prod until \#981 ships | Dev and prod | \#978 → PR \#981 (awaiting CodeRabbit re-review, then Neil) |
| Comment double-send | Fixed | Dev | \#979 |
| Reactions, Giphy, DMs | Works | Dev/preview | — |
| Notifications | Works; large-text UI in progress | Dev/preview | PR \#984 (CI-green) |
| Spaces (hardcoded in the app; Prayer Sanctuary and Weekly Study in the feed bar, Online Resources / Videos in the directory) | Works | Dev/preview | — |
| Links | Works | Dev/preview | — |
| Member directory, sensory themes, Vote & Feedback, organizer welcome | Works | Dev/preview | — |
| GetStream video call \+ guest links \+ screen share | Mostly works (preview) | On main; current dev (ci-dbfcc70) lacks the call flag | Needs flagged dev rebuild after \#981 |
| Large-text call UI | CI-green | Not merged | PR \#983 (part of \#935) |
| Two-way call: Pixel 9a APK host \+ desktop Chrome guest | Proven | Preview | — |
| Web-to-web, APK-to-APK calls | Not fully proven | Preview | **Open question:** who verifies? |
| Recurring weekly call link | Not built (preview link only) | — | Code or product work (not config) |
| Bema community / her channel names | Not set up | — | Code or product work (not config) |
| Invite-mint hardening | Merged and on dev web; mint edge function still needs a human deploy; ban reader unwired; revokeMyInvites is on main but the preview edge function doesn't expose it yet | — | \#982 |
| Guest/token follow-ups (issues still open, but the fixes are already on main and dev) | Open | — | \#914–\#920 |
| Delete own post | Missing | — | \#776 |
| Course video (Mux HLS, captions, Educator Studio) | Separate Auxano POCs, not in Refuge | Separate apps | Port planned for Jan 1 |
| Production deploy | Prod is still the Nov 4 v0.9.9 build (dc99aaa); the current prod-deploy blocker is unverified | Prod | None current (\#765 is the v1.0 checklist, closed Nov 1\) |

## 6\. Must-fix before the demo (in order)

1. **Merge PR \#981** after CodeRabbit re-review, then verify a comment actually saves on the demo build (\#978).  
2. **One flagged dev web \+ Android rebuild** to turn the call preview back on (merges to main currently deploy dev without the call flag).  
3. **Set up the stand-in:** use Belong's existing rooms (renaming or adding Spaces is a code change; a second community needs \#924/\#925). Seed three posts: a prayer request, a scripture/video link, and a "this week" post with an episode deep link, a listen-by date, and the call link. Keep test content out of real members' view. **Open question:** is dev's data separate from the live Belong community?  
4. **Stable weekly call link:** pick one reusable preview call link for the demo and label it as "the weekly call." **Open question:** is a fixed preview link acceptable for the demo, or is a scheduled recurring call required?  
5. **Dry-run only the proven path** (Pixel 9a preview APK host \+ desktop Chrome guest) on headphones with quiet audio. Residual audio risk: \#909/\#919.

## 7\. Nice-to-haves

- Merge PR \#983 (large-text call UI) and PR \#984 (notification/sign-in large text).  
- Members can delete their own posts (\#776).  
- Finish \#982 invite hardening: a human deploy of the mint edge function, wire the ban reader, and expose revokeMyInvites in the preview edge function (must-haves before real group use).  
- Make threaded posts feel more like live chat (e.g. faster refresh or a chat-style Space): Phase 2 or later, not for this demo.  
- Packages/refuge extraction (\#924) and public refuge-demo repo (\#925) — demo checklist items, likely not needed for Carina's demo. **Open question.**

## 8\. Environment and device plan

- **Environment:** Dev ([https\://dev-belongonthespectrum.web.app/](https://dev-belongonthespectrum.web.app/)), signed in. Do not use prod ([https\://belongonthespectrum.web.app/](https://belongonthespectrum.web.app/)) — it is the Nov 4 v0.9.9 build (dc99aaa). Comment saves can fail on both dev and prod until \#981 ships. Team norm: publish only to dev/preview unless Neil says otherwise.  
- **Host device:** Pixel 9a with the preview APK (proven as call host).  
- **Guest device:** Desktop Chrome via guest invite link (proven).  
- **Backup:** If the call fails, move to Carina's existing Discord call link. Screen share itself works from web, Chrome, and the Mac app, so content can be shown during the call.  
- **Accounts:** **Open question:** which test accounts are signed in, and does Carina use her own account?

## 9\. Dry-run checklist

- [ ] \#981 merged and comment save verified on dev  
- [ ] Flagged dev web \+ Android rebuild done; call button visible  
- [ ] Preview APK installed on host Pixel 9a  
- [ ] Belong stand-in checked: test content not visible to real members, no real prayer requests on screen  
- [ ] Three posts seeded: prayer request, scripture/video link, "this week" post (episode deep link, listen-by date, call link)  
- [ ] Weekly call link chosen and tested  
- [ ] Guest invite link tested from desktop Chrome  
- [ ] Screen share tested  
- [ ] Audio tested quietly (headphones/muted), not around Carina  
- [ ] Reactions and notifications checked end-to-end; comments only if \#981 is verified  
- [ ] Fallback ready: Carina's existing Discord call link

## 10\. Switching: what a real move would need

* Talk to Carina first: learn her channels, the Discord features her group actually uses (forum channels, scheduled events with reminders, voice), and what devices her members use.  
* Member invite and onboarding: members sign in on the web (Android can also use the APK) and land in Start Here. iPhone members would use Safari on the web: there is no native iOS app, and iOS push (\#165) and Safari/PWA calls are unproven. This is a big risk if her group is iPhone-heavy. Open question: what is the exact member invite path beyond call guest links?  
* Call fallback (decided): her existing Discord call link stays in place; if the Refuge call fails, everyone moves there.  
* Test content: keep demo and test posts out of the live Belong community. A separate Bema community would be cleaner but needs white-label work (\#924/\#925).  
* Pilot ask: "Run next week's call here, with Discord as backup."  
* Must-haves before real use: prayer privacy (members-only prayer Space), delete-own-post (\#776), and finished guest-link hardening (\#982 edge function deploy, ban reader, revokeMyInvites).

## 11\. Risks and mitigations

| Risk | Mitigation |
| :---- | :---- |
| Comments fail to save | Merge \#981 first and verify a comment saves on the demo build; until then, no comment posting in any demo step; never use prod |
| Call not visible on dev | Flagged rebuild after \#981 |
| Call fails on an unproven device combo | Use proven combo (Pixel 9a APK host \+ desktop Chrome guest), headphones; residual audio risk \#909/\#919; Discord link as fallback |
| Threaded posts feel unlike Discord chat | Frame Spaces as channels; ask Carina what matters most |
| No always-on voice rooms | Position the weekly call as the group's meeting; confirm she doesn't need drop-in voice |
| Guest link abuse while \#982's mint edge function is undeployed | Use links only for the demo; keep them private |
| Testing disrupts Carina | Quiet audio tests; don't ask her to test until comments are solid |
| GCP billing account closed (Storage, backups) | Link-based videos (Fireside, YouTube) shouldn't be blocked; avoid file uploads in the demo |
| Prod is an old build (v0.9.9, dc99aaa); deploy blocker unverified | Not needed; demo on dev only, never prod |

## 12\. Open questions for Neil

1. Is dev's data separate from the live Belong community, so test posts stay out of real members' view?  
2. What are Carina's exact Discord channel names?  
3. Is a fixed preview call link acceptable, or must the weekly call be scheduled/recurring for the demo?  
4. Does she need real-time chat or always-on voice, or are threaded posts plus a weekly call enough?  
5. Target demo date?  
6. Should course/scripture video be shown from the Auxano POCs, or wait for the Jan 1 port?  
7. How many of Carina's members use iPhones? (No native iOS app; Safari/PWA calls and iOS push \#165 are unproven.)  
8. Who verifies web-to-web and APK-to-APK calls, and are they needed for this demo?
