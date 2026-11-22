Source: https://docs.google.com/document/d/1xi-Eb9sOGUwXZG5eO2R94NxCzacFKRVNkkCY8bsvEPI/edit

# Refuge – Bema Feature Wish List

*Review draft for an AI reviewer (Gemini, Neon, or Argon) to critique · Sat Nov 21, 2026 · Effort: S \= days, M \= 1–2 weeks, L \= more (rough guesses). Facts about Bema come from bemadiscipleship.com and bemaevents.com, linked inline. Items marked **Open question** need a decision.*

## 1\. What Bema offers today (from its website)

- **The BEMA Podcast** from BEMA Discipleship, a ministry of Impact Campus Ministries, hosted by Marty Solomon with Brent Billings, Reed Dent, and Elle Grover Fricks. Main body of work is Sessions 1–5 (episodes \-1 to 204); Bema encourages listening in order. Sessions 6–10 continue from episode 205\. [https\://www\.bemadiscipleship.com/about](https://www.bemadiscipleship.com/about)  
- **Cadence:** recent new episodes about every one to two weeks (e.g. 518 on Nov 5, 519 on Nov 19, 2026). A reboot re-records earlier sessions; the Session 2 reboot began May 4, 2026, one episode each Monday, replacing originals in the feed. [https\://www\.bemaevents.com/](https://www.bemaevents.com/)  
- **Per-episode show notes**, with transcripts and **The Companion** study tool on rebooted episodes, plus presentation PDFs on some. Example: [https\://www\.bemadiscipleship.com/0](https://www.bemadiscipleship.com/0)  
- **Feeds:** RSS [https\://www\.bemadiscipleship.com/rss](https://www.bemadiscipleship.com/rss) and JSON [https\://www\.bemadiscipleship.com/json](https://www.bemadiscipleship.com/json). Each episode page also offers an embeddable audio player and a direct MP3 URL.  
- **Referenced Resources** (books by episode) and a **glossary**: [https\://www\.bemadiscipleship.com/resources](https://www.bemadiscipleship.com/resources). Marty's books: [https\://www\.martysolomon.com/books](https://www.martysolomon.com/books)  
- **Events / where Marty is:** [https\://www\.bemaevents.com/](https://www.bemaevents.com/) (for example, a Live Q\&A on Nov 18; Marty in Pennsylvania Nov 30 – Dec 8; Live Q\&A (GMT Edition) on Jan 10). Bema's contact page says Bible questions are funneled to monthly Live Q\&A sessions.  
- **BEMA Messenger:** a monthly email newsletter. Sign up: [https\://lp.constantcontactpages.com/su/fynneO7/bemamessenger](https://lp.constantcontactpages.com/su/fynneO7/bemamessenger). **Public archive:** [https\://www\.bemadiscipleship.com/messenger](https://www.bemadiscipleship.com/messenger) (links to each edition on Constant Contact; latest listed is \#90, November 2026).  
- **Community:** BEMA Slack ([https\://www\.bemadiscipleship.com/slack](https://www.bemadiscipleship.com/slack)), a discussion-groups map and a guide to starting a group ([https\://www\.bemadiscipleship.com/groups](https://www.bemadiscipleship.com/groups)), BEMA Virtual Campus for college students, study tours to Israel and Turkey in even-numbered years (https\://www\.bemaevents.com/tours; preregistration windows are announced through the Messenger, then participants are randomly selected), and the BEMA Liturgy ([https\://www\.bemaliturgy.com/](https://www.bemaliturgy.com/), also as YouVersion reading plans).  
- **Other:** merch store, donations via Impact Campus Ministries, the Covered in His Dust blog ([https\://www\.bemadiscipleship.com/articles](https://www.bemadiscipleship.com/articles)), and YouTube ([https\://www\.youtube.com/@thebemapodcast](https://www.youtube.com/@thebemapodcast)).

**Licensing note for all items:** Bema content is © 2026 BEMA Discipleship. Linking to official pages is low-risk; copying or republishing content (audio, show notes, transcripts, newsletter text) needs permission. **Open question:** should Neil ask Bema directly? See the PRD's section 8, "Licensing, brand & privacy" (Bema could be asked through its contact form; not done yet).

## 2\. Wish list

| \# | Feature | One-line description | Value | Effort | Dependencies / licensing | Recommendation |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| 1 | Resources Space | A Space or page linking to Bema's official resources: show notes, Referenced Resources, glossary, Marty's books, events, Messenger archive and signup (https\://lp.constantcontactpages.com/su/fynneO7/bemamessenger), Slack, groups guide, Liturgy, events and study tours (see item 20), Virtual Campus | High: one place instead of many bookmarks | S | Links only; no copying | **Recommend now (MVP \#5, the Resources Space) — cheap; adding a Space is a small code change, since Spaces are hardcoded** |
| 2 | Where Marty is / upcoming events | Show Bema's upcoming events (Live Q\&As, Marty's travel) or link to the events page | Medium | S (link) / M (parsed list) | Events page has no feed we found; parsing HTML is brittle. **Open question** | **Later (a plain link in the Resources Space is fine anytime)** |
| 3 | Marty's recommended reading | Link to the Referenced Resources list and Marty's books; optionally tag books to the week's episodes | Medium | S (link) / M (per-episode tags) | Resources page lists episode numbers per book; Bema notes affiliate links | **Recommend now** (link); Later (per-episode) |
| 4 | Easier show notes per episode | The episode deep link in the This Week post (MVP \#2) and links in the Resources Space (MVP \#5) go straight to the episode page, transcript, and Companion | High: members prep for discussion | S–M | RSS/JSON feed metadata; show-notes text in-app needs permission | **Recommend now** (links) |
| 5 | Embedded episode player | Play the episode inside Refuge | Medium: convenience | M | Bema offers an embed player and MP3 URL per episode; in-app use needs permission. Deep links to Pocket Casts/Overcast/Apple are the safe default | **Later** — deep-link first, embed after permission |
| 6 | Weekly episode planner | Leader assigns episode(s) per week, sees count and total length, splits across days or weeks | High: core rhythm for her group | M | Episode list from the feed; reboot episodes replace originals in the feed | **Later (Phase 2); the MVP uses a hand-made This Week post instead** |
| 7 | Email and SMS reminders | Opt-in reminders before the call or listen-by date | Medium–High | M–L | Email/SMS provider not chosen; SMS consent rules; cost | **Later — email first, as the fallback for the MVP call reminder; SMS later** |
| 8 | Listen-reminder notifications | In-app/push nudge to listen to this week's episode (the call reminder itself is MVP \#4) | High | S–M | Existing notifications; push support to verify; iOS push (\#165) unproven | **Later (Phase 2\)** |
| 9 | "This Week" post with discussion questions | A hand-made weekly post with the episode deep link, listen-by date, and call link, pre-filled with the eight questions from Bema's group-start guide; auto-creating it is Phase 2 | High | S–M | Spaces and comments (needs comment fix \#981 shipped) | **Recommend now (MVP \#2)** |
| 10 | Prayer-request channel | Prayer Space with "praying" reactions | High | S (exists in Belong as Prayer Sanctuary) | Spaces are hardcoded, so a Bema prayer Space is a code change. Must-haves: members-only and delete-own-post (\#776) | **Recommend now (MVP \#3)** |
| 11 | Scripture videos | Space for video links; later Mux video via the courses track | Medium | S (links) / L (Mux) | Courses/video port planned for Jan 1 | **Recommend now** (links); Later (Mux) |
| 12 | Recurring weekly call | Stable call link plus a calendar invite, shown in the This Week post and reminders | High | S–M | GetStream preview; flagged dev rebuild; \#982 invite hardening | **Recommend now (MVP \#1)** |
| 13 | BEMA Messenger in Refuge | Surface Bema's monthly newsletter (see section 3\) | Medium | S–M | Public archive exists; republishing needs permission | **Recommend now — link only, in the Resources Space (option 1); ingestion Later** |
| 14 | Live Q\&A reminders | Remind members of Marty's monthly Live Q\&A and link to it | Low–Medium | S | Event dates from the events page (manual entry) | **Later** |
| 15 | BEMA Liturgy / Church calendar | Link to the BEMA Liturgy and YouVersion plans, maybe surface the current season | Low–Medium | S (link) | Links only | **Later** |
| 16 | Session progress map | Show where the group is in Sessions 1–10 (e.g. "Session 2: Prophets & Writings, episode 41") | Medium: motivation and context | S–M | Session ranges from the About page | **Later** |
| 17 | Glossary lookup | Quick link or search into Bema's glossary of Hebrew/Greek terms | Low–Medium | S (link) | Copying glossary needs permission | **Later** (link in Resources Space) |
| 18 | Group-finder / BEMA Slack links | Point members to Bema's groups map and Slack for the wider community | Low | S | Links only | **Recommend now** (inside Resources Space) |
| 19 | "I listened" check-off | Members mark episodes listened | Medium | S | Could feel like pressure. **Open question** | **Later** |
| 20 | Bema events and trips | A "Bema events and trips" card in the Resources Space linking to the events page and the Israel and Turkey study-tours page, plus an optional reminder when tour preregistration opens | Low now; Medium when tours open: short preregistration windows are easy to miss | S (card) / M (reminder) | Tours page https\://www\.bemaevents.com/tours: tours run in even-numbered years; preregistration windows (about a month in 2025\) are announced via the Messenger, then participants are randomly selected and contacted by GTI Tours. No feed found, so dates would be entered by hand. Reminder reuses item 8 notifications | **Later (card and reminder): tours run in even-numbered years, so the next ones are in 2028 and nothing is needed for the MVP** |
| 21 | Merch / donate links | Link to merch store and donations | Low | S | Links only | **Skip** unless Carina wants it |

## 3\. BEMA Messenger in Refuge (detail)

**What we found:** The BEMA Messenger is a monthly email "with the latest news and stories." People sign up through a Constant Contact form: [https\://lp.constantcontactpages.com/su/fynneO7/bemamessenger](https://lp.constantcontactpages.com/su/fynneO7/bemamessenger). Bema keeps a **public archive** on its own site, [https\://www\.bemadiscipleship.com/messenger](https://www.bemadiscipleship.com/messenger), listing each edition with a Constant Contact link (for example, \#90 for November 2026: [https\://conta.cc/4jPC0iN](https://conta.cc/4jPC0iN)). The events page calls it "the best way to find out what we're doing as soon as we announce it."

**Options**

1. **Link to the public archive (and the latest edition).** A Resources Space card: "BEMA Messenger — latest edition" plus "Sign up." Effort S. Risk: none; it's linking. Could be refreshed by checking the archive page for the newest entry. **Open question:** manual update or automated check?  
2. **Dedicated inbox that subscribes or auto-forwards the newsletter, ingested into a Resources feed.** A Refuge-owned address (or Neil's Gmail with a forwarding rule) receives each edition; the app or a bot (for example via the Gmail connector) parses it and posts it to a Resources Space. Effort M. Risks: republishing the full newsletter text is a copyright question; parsing email HTML is brittle; one more account to maintain.  
3. **Signup capture into the Refuge database.** Refuge offers its own "subscribe to the Messenger" button and stores the request. Effort M. Problems: Refuge can't actually subscribe someone to Bema's Constant Contact list on their behalf without Bema's involvement, and storing emails adds consent and privacy obligations. Better: a button that opens Bema's official signup form.

**Permission and copyright:** Linking to the archive and signup form is fine. Republishing newsletter content inside Refuge (option 2\) should wait for Bema's permission; a short summary with a link back is a middle ground still worth asking about.

**Recommendation:** **Option 1 now** (link to the archive's latest edition and the official signup form). **Option 2 (ingestion) Later, and only with Bema's permission**, and then post a title, date, and link rather than the full text. **Skip option 3**; just link to Bema's own signup.

## 4\. Top 5: the MVP list (same ranked list as the PRD)

1. **Weekly call room with a calendar invite** — one stable, reusable call link plus an .ics invite.  
2. **"This Week" post** — a hand-made weekly post with the episode deep link, listen-by date, and call link, pre-filled with the eight discussion questions from Bema's group-start guide.  
3. **A private prayer Space** — members-only, with delete-own-post (\#776); a code change, since Spaces are hardcoded.  
4. **A call reminder** — an in-app notification before the weekly call, with email as a fallback.  
5. **A Resources Space** — links to show notes, Referenced Resources, glossary, Marty's books, events, the Messenger archive and signup, Slack, and the groups guide.

Phase 2 or later: the weekly episode planner, "I listened" tracking and listen reminders, SMS, and live chat. Later still: Bema trips (card and reminder) and Messenger ingestion (only with permission). Real group use also needs \#982 guest-link hardening finished, and iPhone support (Safari only; iOS push \#165 unproven) is a risk.

## 5\. Open questions for the reviewer

1. Are the value and effort ratings reasonable?  
2. Should Neil ask Bema for permission to embed audio and show notes, or stay link-only?  
3. Is anything on Bema's site more useful to a group leader than what's listed?  
4. Email/SMS reminders: worth it for a small group, or is push enough?  
5. Does Carina's group use Bema's study tools (Companion, transcripts) today?
