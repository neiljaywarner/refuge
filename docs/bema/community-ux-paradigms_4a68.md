Source: https://docs.google.com/document/d/1i2z0UFbILiXragfnA0j6qDPE6bJHQEssM74js0vs_d0/edit

# Refuge – Community UX Paradigms: Discord, Circle-Style Spaces, and Others

*Review draft for an AI reviewer (Gemini, Neon, or Argon) · Sat Nov 21, 2026 · Purpose: describe how the main community-app paradigms differ, and where Refuge might benefit from borrowing from each. Items marked **Open question** need a decision. This is analysis, not a decision.*

## 1\. Why this doc

Neil's instinct is that Refuge could replace Carina's Discord for her Bema group, since both are community apps and the GetStream call works on the proven device path. The gap is bigger than configuration: Spaces are hardcoded in the app, comment saves depend on PR \#981, there is no native iOS app, and moving a group has real switching costs. The open question is **which interaction model fits a weekly Bema discussion group best**, and whether Refuge should move toward Discord, stay Circle-style, borrow from other models, or complement Discord rather than replace it.

## 2\. Where Refuge is today

Refuge is the platform; Belong on the Spectrum is its first live community. It is **Circle-style**: a Feed, Spaces (topic rooms such as Start Here, Announcements, General Chat, Weekly Study, Prayer Sanctuary, and Online Resources / Videos), posts with comments, reactions (including praying/relate), Giphy, DMs, a member directory, notifications, sensory themes and large text, Vote & Feedback, and an organizer welcome message. A GetStream preview video call with guest links and screen share is on main. Spaces are hardcoded in the app (two Dart lists), not organizer-configurable; Prayer Sanctuary and Weekly Study sit in the feed space bar, and Online Resources / Videos is in the Spaces directory. Refuge runs on web and Android; there is no native iOS app, so iPhone members would use Safari.

## 3\. The paradigms

### 3.1 Discord: real-time chat channels

- **Shape:** a server with a sidebar of channels. Text channels are continuous chat streams, but messages can branch into threads, and forum channels hold one post per topic with its own replies (much like Spaces). Scheduled events with reminders (members mark "Interested" and are notified) can cover a weekly call, and voice channels are always-on rooms people drop into.  
- **Strengths:** feels live and casual; quick back-and-forth; drop-in voice; familiar to many younger users.  
- **Weaknesses:** plain chat channels scroll away and make last week's discussion hard to find (forum channels and threads help, if the server uses them); can feel noisy and busy; many channels and unread badges; less calm.

### 3.2 Circle-style Spaces (Refuge today)

- **Shape:** topic rooms holding posts; each post has its own comment thread; a combined feed.  
- **Strengths:** calmer; each topic (a prayer request, a week's episode) stays together and findable; good for people who check in a few times a week; fits accessibility and sensory goals.  
- **Weaknesses:** less "live"; quick chatter needs a post first; no drop-in voice.

### 3.3 Slack-style channels with threads

- **Shape:** chat channels like Discord, but replies can branch into threads. (Bema itself runs a BEMA Slack community with channels per session: [https\://www\.bemaevents.com/](https://www.bemaevents.com/))  
- **Strengths:** live chat plus threads to keep topics tidy.  
- **Weaknesses:** threads are easy to miss; workplace feel.

### 3.4 Group-chat apps (WhatsApp, GroupMe, Signal)

- **Shape:** one chat per group, mobile-first, push notifications.  
- **Strengths:** simplest possible; everyone already knows it; fast for reminders and prayer requests.  
- **Weaknesses:** everything in one stream; no structure for episodes or resources.

### 3.5 Forum / message board (Discourse-style)

- **Shape:** categories with long-lived topics.  
- **Strengths:** best for searchable, lasting discussion.  
- **Weaknesses:** feels slow and formal for a small group.

### 3.6 Rhythm-first / course or reading-plan apps (e.g. YouVersion plans, cohort courses)

- **Shape:** content is organized by day or week; you see "this week" first. (The BEMA Liturgy is also available as YouVersion reading plans.)  
- **Strengths:** matches a weekly listen-then-discuss rhythm; tells members what to do next.  
- **Weaknesses:** needs planning tools; less open-ended conversation.

### 3.7 Church-group apps (e.g. Church Center with Planning Center Groups, Subsplash, Faithlife Groups; or Zoom plus WhatsApp)

* **Shape:** apps built for church small groups, or the common low-tech combo of a Zoom call plus a WhatsApp group chat.  
* **Strengths:** made for small groups; many members may already use one through their church; Zoom plus WhatsApp needs no new app at all.  
* **Weaknesses:** usually tied to a church's account and setup; less control over calm design and accessibility. Open question: the specific feature sets of these apps were not verified for this doc.

### 3.8 Complement Discord rather than replace it

* **Shape:** Carina keeps Discord for chat and the call, and Refuge adds what Discord lacks: a "This Week" post with the episode, listen-by date, and Bema's discussion questions, plus a calmer prayer and resources space.  
* **Strengths:** no switching cost; members keep their habits; Refuge can earn its place one feature at a time.  
* **Weaknesses:** two places to check; the group may never fully move.

## 4\. Comparison

| Dimension | Discord | Refuge Spaces (Circle-style) | Slack-style | Group chat | Forum | Rhythm-first |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Feel | Live, busy | Calm, organized | Live, tidy | Simple, live | Slow, lasting | Guided |
| Finding last week's discussion | Hard in plain chat; Medium with forum channels or threads | Easy (post per topic) | Medium | Hard | Easy | Easy (by week) |
| Quick chatter | Excellent | Fair | Good | Excellent | Poor | Fair |
| Prayer requests | Scroll away in plain chat; a forum post or thread keeps each request together | Each request is a post with "praying" reactions | Threads | Scroll away | Topics | Could attach to the week |
| Weekly call | Voice room, or a scheduled event with reminders | Call joined by link (a preview link today; a stable weekly link is planned) | Huddles | External link | External link | Call is part of "this week" |
| Sensory load | High | Low | Medium | Medium | Low | Low |
| Fit for Bema weekly group | Good | Good | Good | Fair | Fair | Very good (if built) |

**Open question:** these ratings are judgment calls; the reviewer should challenge them. The Sensory load row reflects Belong's sensory-friendly priorities, which may matter less to a Bema group. The table leaves out 3.7 (church-group apps) and 3.8 (complementing Discord); for any option, the cost of switching (re-inviting members, new habits, iPhone support) counts as much as features.

## 5\. What Refuge might borrow

1. **From rhythm-first apps:** start with a hand-made "This Week" post (MVP \#2: episode deep link, listen-by date, call link, and Bema's discussion questions); a "This Week" home view is Phase 2\. This rhythm is likely Refuge's biggest differentiator for Bema groups.  
2. **From Discord:** a lighter, faster reply experience in a "General Chat" Space (live updates, quick replies without opening a post). Live chat is Phase 2 or later. **Open question:** chat-style Space type, or just faster threaded comments?  
3. **From Discord:** a persistent "Weekly Call" room with a stable link and a calendar invite (MVP \#1) rather than drop-in voice. Always-on voice rooms are probably not needed for a weekly group. **Open question:** confirm with Carina.  
4. **From group chat:** a gentle call reminder (MVP \#4); listen reminders are Phase 2\.  
5. **From Slack/forums:** keep threading per topic so prayer requests and episode discussions stay findable.

## 6\. Recommendation for review

Keep Refuge's calm, Circle-style Spaces as the core (they already map to Discord text channels), add a **rhythm-first "This Week" layer** on top, and borrow Discord's **live feel only where chatter happens** (General Chat) plus a **stable weekly call room**. Don't copy always-on voice channels unless Carina's group actually uses them. If Carina isn't ready to switch, complementing Discord (3.8) is a reasonable first step: pilot one weekly call in Refuge with Discord as the backup.

## 7\. Open questions

1. Does Carina's group chat live during the week, or mainly post and reply?  
2. Do they ever use Discord voice channels outside the weekly call?  
3. Would a chat-style Space type be worth the build cost versus faster comments?  
4. Should "This Week" be the home screen for a Bema community?  
5. How many members check in daily versus weekly?  
6. Would Carina rather complement Discord than replace it?  
7. How many of her members use iPhones?
