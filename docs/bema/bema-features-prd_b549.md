Source: https://docs.google.com/document/d/18UE37OCFDsLV2qtxokBILOvK0veUGCcbCug1_5ZSz9Y/edit

# Refuge – Bema-Specific Features PRD

*Review draft for Gemini · Sat Nov 21, 2026 · Items marked **Open question** need a decision or verification. Nothing here is built unless stated.*

## 1\. Problem and context

Carina leads a Bema discussion group that meets weekly. The BEMA Podcast (https\://www\.bemadiscipleship.com) comes from BEMA Discipleship, a ministry of Impact Campus Ministries. It is hosted by Marty Solomon with Brent Billings, Reed Dent, and Elle Grover Fricks, and walks through the historical context of the Bible and the Text itself (tagline: "Love God. Love others. Become people of the Text."). The main body of work is Sessions 1–5 (episodes \-1 through 204: Torah, Prophets & Writings, Gospels, Early Church, Church History), and Bema encourages listening in order. Sessions 6–10 (episode 205 onward; Session 10, Walking the Labyrinth, is current) explore new topics. Recent new episodes have come out roughly every one to two weeks (for example, 518 on Nov 5 and 519 on Nov 19, 2026). A reboot is also re-recording the early sessions: the Session 1 reboot is complete, and the Session 2 reboot began May 4, 2026, with one episode each Monday, replacing the originals in the feed (source: https\://www\.bemaevents.com/). Episode pages carry show notes, and rebooted episodes add a transcript and The Companion study tool. Bema lists discussion groups on a public map with a guide to starting one (https\://www\.bemadiscipleship.com/groups), and runs the BEMA Slack community, the monthly BEMA Messenger email, monthly Live Q\&A with Marty, and the BEMA Liturgy. Today Carina's group uses Discord for its weekly video call and for channels such as scripture videos and prayer requests. Open question: which session or episodes is her group on now, and does it use the reboot versions?

Refuge is Neil's community platform (Flutter, web and Android). Its first live community is Belong on the Spectrum. Refuge covers part of what Discord does for this group. Spaces are threaded topic rooms (posts, comments, reactions), not live chat, and they are hardcoded in the app (two Dart lists), so her channel names are a code change and a separate Bema community needs white-label work (\#924/\#925). Comment saves can fail on dev and prod until PR \#981 merges. A GetStream video call with guest links and screen share works on the proven preview path (Pixel 9a APK host \+ desktop Chrome guest). There is no native iOS app: iPhone members would use Safari, and iOS push (\#165) and Safari/PWA calls are unproven. What Refuge lacks is the **weekly rhythm** a Bema group runs on: which episode(s) this week, when to listen by, when the call is, and gentle reminders.

This PRD proposes Bema-specific features that make Refuge "rhythm-first" for a podcast discussion group. No Bema-branded community exists yet.

## 2\. Users

- **Group leader (Carina):** plans which episodes the group covers, sets the weekly call, posts prompts, shares scripture videos, and keeps prayer requests cared for.  
- **Group members:** listen to the episode, join the weekly call, discuss, and share and pray for requests. **Open question:** group size and how comfortable members are with apps (Android, web, iPhone?). An iPhone-heavy group is a big risk: there is no native iOS app, and Safari/PWA calls and iOS push (\#165) are unproven.

## 3\. Goals and non-goals

**Goals**

- Make each week's plan obvious: episode(s), listen-by date, call time.  
- Help members actually listen before the call, with consented reminders.  
- Keep discussion, prayer requests, and scripture videos in one calm place instead of Discord.  
- Reuse what already exists (Spaces, posts/comments/reactions, notifications, GetStream calls).

**Non-goals (for now)**

- Hosting or re-distributing Bema audio without permission.  
- Always-on Discord-style voice rooms.  
- A general podcast app or full course platform (courses are a separate Jan 1 track).  
- Production launch; work ships to dev/preview unless Neil says otherwise.

## 4\. Features

### 4.1 Episode player (embedded audio — only if it makes sense)

**Options assessed**

| Option | How it works | Pros | Cons |
| :---- | :---- | :---- | :---- |
| A. Deep-link to podcast apps | Episode card links to the episode in Apple Podcasts, Spotify, or similar | No licensing risk; members keep their usual app and progress | Leaves Refuge; no in-app listen tracking |
| B. Embed from the podcast's public RSS feed | Refuge reads the public feed and plays the audio file URL in-app | Smooth in-app experience; can show "listened" | Licensing/permission unclear; audio hosting costs and analytics stay with the publisher; need to handle feed changes |
| C. Publisher-provided embed widget | Each Bema episode page offers an "Embeddable Audio Player" code and a direct MP3 download URL (site is hosted on Fireside) | Usually permitted by design | **Open question:** is using the share-page embed inside an app OK? Limited styling control |
| D. Link to the podcast's own website | Plain link per episode | Simplest | Least integrated |

**Recommendation for review:** Start with **A \+ D** (episode cards with deep links) in the MVP. Consider C (the embed Bema already offers for sharing) or B only after confirming permission. Bema's subscribe page recommends Pocket Casts for Android and Overcast or Apple Podcasts for iOS, so those are natural deep-link targets (https\://www\.bemadiscipleship.com/subscribe).

**User stories**

- As a member, I can tap this week's episode and start listening in my podcast app.  
- As a leader, I can attach an episode to a week without copying links by hand (pick from the feed).

**Requirements**

- Episode card shows title, episode number, and links out.  
- If an RSS feed is used only for metadata (titles, numbers, dates), cache it and refresh periodically.  
- Optional "I listened" check-off by members (self-reported).

**Open questions**

- **Licensing/permission:** may Refuge embed or stream Bema audio from the public RSS feed? Should we ask the publisher?  
- Bema publishes public RSS (https\://www\.bemadiscipleship.com/rss) and JSON (https\://www\.bemadiscipleship.com/json) feeds. Is using their metadata (titles, numbers, dates, lengths, links to show notes) inside Refuge acceptable?  
- Is "I listened" tracking welcome or does it feel like pressure?

### 4.2 Weekly episode planning (Phase 2\)

**User stories**

- As a leader, I can see at a glance how many episodes the group is covering this week.  
- As a leader, I can decide whether to split episodes across days or across weeks, and the plan updates.  
- As a member, I can see this week's episode(s), the listen-by date, and the call time on one screen.

**Requirements**

- A "This Week" view: week dates, assigned episode(s), listen-by date, call time, and link to the week's discussion thread.  
- A simple planner: list of upcoming weeks; drag or assign episodes; options for "one per week," "two this week," or "split across days" (e.g. Episode A by Tuesday, Episode B by Thursday).  
- Show total listening for the week if episode length is available. **Open question:** episode pages list length (e.g. 48 mins 2 secs for episode 0); confirm it is in the feed.  
- Leader-only editing; members view.

**Open questions**

- How does Carina plan today (spreadsheet, Bema's own guide, ad hoc)?  
- Bema encourages starting at episode \-1 or 0 and continuing in order; does the group follow that order strictly, and how should the planner handle reboot episodes that replace originals in the feed?  
- Should the plan handle breaks (holidays, skipped weeks)?

### 4.3 Email and SMS reminders (SMS Later; email is the reminder fallback)

**User stories**

- As a member, I can opt in to an email or text reminder before the weekly call.  
- As a member, I can opt in to a reminder before the listen-by date.  
- As a leader, I can see who is opted in (not their contact details unless shared), and send a one-off reminder.

**Requirements**

- **Explicit opt-in per channel** (email, SMS), recorded with timestamp; easy opt-out (e.g. STOP for SMS, unsubscribe link for email).  
- Configurable timing (e.g. day before, hour before).  
- Message content: episode(s), listen-by date, call time, link to join.  
- Quiet hours and frequency caps.

**Open questions**

- Which email/SMS provider? (Not yet chosen; cost and compliance rules for SMS consent need review.)  
- SMS is Later. Is email needed as a fallback for the MVP call reminder?  
- Which time zone(s) does the group live in?

### 4.4 In-app and push notifications to listen (Phase 2; the MVP call reminder is MVP \#4)

**User stories**

- As a member, I get a gentle notification to listen to this week's episode.  
- As a member, I can turn listen reminders off or choose their timing.

**Requirements**

- Build on Refuge's existing in-app notifications; add push where supported. **Open question:** current push support on Android and web — verify. iOS push (\#165) is unproven, and there is no native iOS app.  
- Default to a single, gentle reminder per week; respect notification settings and large-text/sensory preferences.  
- Deep link from the notification to the This Week view.

**Open questions**

- Opt-in by default or off by default?  
- Should reminders stop once a member marks "I listened"?

### 4.5 Related ideas

**Per-week discussion threads tied to episodes**

- Phase 2: each week auto-creates a discussion post in a Discussion Space, linked to the week's episode(s) and optional leader prompts.  
- Open question: one thread per episode or per week?

**Prayer-request and scripture-video channels**

- Use Spaces (Belong already has Prayer Sanctuary and Online Resources / Videos). Spaces are hardcoded in the app (two Dart lists), so Bema equivalents or her channel names need a code change, not configuration.  
- Praying reaction already exists. Must-haves for real use (MVP \#3): a members-only prayer Space and members can delete their own posts (\#776). Open question: should prayer requests also have an "answered" status?  
- Scripture videos: links/embeds for MVP; Mux-based video from the courses track later.

**Recurring weekly call**

- A stable, reusable call link for the group (today calls join via a preview link like ?call=monthly).  
- Shown in the This Week post (and the Phase 2 This Week view) and in reminders; guests can join via invite link.  
- A calendar invite (e.g. .ics) is part of MVP \#1.

### 4.6 Show notes, study tools, and Bema resources

What exists today on Bema's site: each episode page (for example https\://www\.bemadiscipleship.com/0) carries show notes with referenced books and links, some episodes have a presentation PDF, and rebooted episodes add a transcript and The Companion study tool. Bema also keeps a Referenced Resources list of books by episode plus a glossary of mostly Hebrew and Greek terms (https\://www\.bemadiscipleship.com/resources).  
User story: As a member, I can open this week's show notes, transcript, and Companion from the episode card in Refuge without hunting through a podcast app.  
Requirements: link out to the official episode page and its study tools rather than copying them; optionally show a short show-notes summary from the feed. Open question: is displaying show-notes text from the feed acceptable, or should Refuge only link?  
See the companion doc "Refuge – Bema Feature Wish List" for a broader list, including a Resources hub, the BEMA Messenger newsletter, Marty's events, and the BEMA Slack.

## 5\. Success metrics (proposed, for review)

- Carina chooses to run at least one weekly call in Refuge instead of Discord.  
- Share of members who join the weekly call through Refuge.  
- Share of members who open the This Week post before the call.  
- Opt-in rate for reminders, and opt-out rate (low opt-out \= not annoying).  
- Weekly discussion posts/comments and prayer reactions.  
- Qualitative: Carina says planning the week is easier than today.

**Open question:** what targets are realistic for a small group?

## 6\. Phasing

**MVP (one ranked list, shared with the Wish List)**

1. Weekly call room with a calendar invite: one stable, reusable call link plus an .ics invite.  
2. A "This Week" post (hand-made, not a new view) with the episode deep link, listen-by date, and call link, pre-filled with the eight discussion questions from Bema's group-start guide: What are the problems I see in this story? What sticks out to me? / Is there anything that radically changes by viewing this with eastern eyes? / What new truth did I learn in this podcast? / What am I having a hard time embracing and why? / Who are the characters in this story, and how do I relate to each one? / How do I see this teaching displayed in my own life? / What is changing in my life as a result of this lesson? / What action points do I need to pursue in order to be transformed by this Text?  
3. A private prayer Space (members-only) with delete-own-post (\#776).  
4. A call reminder (in-app notification; email as fallback).  
5. A Resources Space: links to Bema's episode pages, /resources and glossary, the BEMA Messenger archive and signup, and official Fireside embeds.  
- Not configuration: Spaces are hardcoded, so items 3 and 5 are code changes; the demo uses Belong as a stand-in, and a separate Bema community needs \#924/\#925.

**Phase 2**

- This Week view and episode planner (split across days or weeks).  
- Episode metadata from the public RSS feed (if acceptable).  
- Listen reminders (push where supported) with settings, and members can mark "I listened."  
- Auto-created weekly discussion threads and a chat-style (live chat) Space.

**Later**

- SMS reminders with recorded consent (email stays the reminder fallback).  
- Embedded audio (only with permission).  
- Bema trips card and preregistration reminder (next tours 2028), and BEMA Messenger ingestion (only with permission).  
- Scripture videos via the Refuge courses/video module (Jan 1 port).

## 7\. Dependencies on the existing stack

- **Flutter app (web and Android; no native iOS app, so iPhone members use Safari, and iOS push \#165 and Safari/PWA calls are unproven):** new This Week view, planner, settings.  
- **Spaces, posts, comments, reactions:** discussion threads, prayer requests, scripture videos. Spaces are hardcoded in the app (two Dart lists), so new rooms or her channel names are a code change, and a second community needs white-label work (\#924/\#925). Comments rely on PR \#981 (unmerged); comment saves can fail on dev (build ci-dbfcc70) and prod until it merges.  
- **GetStream calls:** recurring call link; guest invites (\#982 invite-mint hardening is merged and on dev web, but the mint edge function needs a human deploy, revokeMyInvites is on main but not exposed by the preview edge function, and the ban reader is unwired; the guest/token fixes for \#914–\#920 are already on main and dev). Dev (ci-dbfcc70) needs a flagged rebuild to show calls.  
- **Notifications:** existing in-app notifications; large-text notification UI in PR \#984.  
- **Backend (Supabase/Firebase):** **Open question:** which backend stores weekly plans, episodes, and consent records? Refuge is hosted on Firebase; the course POCs use Supabase.  
- **Courses/video (Jan 1):** feature\_courses and feature\_video (Mux) port; still needs tenant scoping, progress, weekly unlock, signed playback, webhooks.  
- **Ops:** a closed GCP billing account blocks Storage and some backups; link-based videos shouldn't be affected, but file uploads might. Prod is still the Nov 4 v0.9.9 build (dc99aaa); \#765 is the v1.0 checklist (closed Nov 1), and the current prod-deploy blocker is unverified.  
- **New:** email/SMS provider (not chosen).

## 8\. Licensing, brand & privacy

* Bema's site has no terms-of-use page that we found, only a "© 2026 BEMA Discipleship" copyright notice. Treat episodes, show notes, and artwork as theirs.  
* Use only official Fireside embeds and links (episode pages, the per-episode embed player, and the MP3 link Bema provides). Don't re-host audio or copy show notes.  
* Don't brand the community as BEMA or use Bema's name or logo as branding without permission; describe it as a group that discusses The BEMA Podcast.  
* Bema could be asked for permission through its contact form (https\://www\.bemadiscipleship.com/contact). This has not been done yet.  
* Must-haves before real use: prayer privacy (a members-only prayer Space and delete-own-post, \#776) and guest-link hardening (\#982 edge function deploy, ban reader, revokeMyInvites).

## 9\. Open questions

1. Is embedding Bema audio permitted? Should we ask Bema through its contact form (see section 8; not done yet)?  
2. May we use metadata from Bema's public RSS and JSON feeds, and link or embed its episode player?  
3. How does Carina plan episodes today, and how many per week is typical?  
4. Group size, devices, and time zones?  
5. Email, SMS, or push first? Which provider?  
6. Where are weekly plans and consent records stored (Supabase or Firebase)?  
7. Should Bema be its own community (needs white-label work \#924/\#925) or a set of Spaces inside Belong (a code change, since Spaces are hardcoded)?  
8. Which calendar invite format suits the group (MVP \#1 includes one), and does the call need a fixed weekly time?  
9. Beyond members-only and delete-own-post (\#776), how private should prayer requests be?  
10. How many members use iPhones, given there is no native iOS app?
