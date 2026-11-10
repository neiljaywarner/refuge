# 🎯 Refuge Platform: Circle.so Half-Price Competitor Scorecard & 90-Day Co-Builder Playbook

> **Prepared for:** November 2026 Co-Builder / Business Partner Strategy Session  
> **Platform Hierarchy:**  
> - **Refuge Platform:** The white-label all-in-one Circle.so (\$89–\$199/mo) + Zoom (\$18/mo) + Courses competitor at half the price (\$49/mo).  
> - **Live Demo 1 — Community #1 on Refuge (`Belong on the Spectrum`):** [`https://belongonthespectrum.web.app`](https://belongonthespectrum.web.app) & [`https://dev-belongonthespectrum.web.app`](https://dev-belongonthespectrum.web.app)  
> - **Live Demo 2 — Our Courses, Workbooks & Directus Non-Tech CMS Codebase (`Course Demo POC`):** [`https://coursedemo-auxano-poc.web.app`](https://coursedemo-auxano-poc.web.app)  
> - **Live Demo 3 — Built-In "Zoom-Style" Live Video Rooms (`GetStream` in Refuge):** [PR #905 Stream Video Preview](https://github.com/neiljaywarner/refuge/pull/905)

![Refuge Platform — Circle.so Competitor & Partnership Infographic](images/business-partner-infographic.svg)

---

## 1. Executive Answer: Are We Holistically ~69% of the Way to a Circle.so Competitor at Half the Price?

**Yes — weighted by what paying organizations actually use, we are at `70.5%` (`~69%`) holistic completion today, with 100% of the hard technical risk already retired.**

Why do churches, ministries, coaching guilds, and care communities pay **Circle.so \$89–\$199/month (\$1,068–\$2,388/year)** plus **Zoom (\$180–\$240/year)**? Because they want **five core pillars** under one roof without Facebook's ads or Discord's chaos:

| Core Pillar | What Circle.so + Zoom Charges For | What We Have Working Today | Readiness | Weight | Weighted Score | What's Left to Reach 100% |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **1. Community Spaces, Feed, Directory, DMs & Push** | Discussion spaces, member directory, DMs, mobile/web notifications | **Live in Production (`v0.9.9`)**: 8+ rooms, 1-tap Prayer Sanctuary, compulsory intent tags (`[Comfort Only]`, `[Prayer Request]`, `[Fellowship]`), care reactions, private bookmarks, opt-in DMs, Giphy, 4 sensory palettes. Left Circle Oct 31! | **92%** | 35% | **32.20%** | Minor multi-organization switcher polish |
| **2. Video Courses, Workbooks & Non-Technical Authoring** | Course modules, hosted video lessons, downloadable handouts | **Live POC (`coursedemo-auxano-poc.web.app`)**: HD video streaming via **Mux**, recording playlist switcher, interactive disciple workbooks saved to Postgres, and **Directus** web admin where non-tech leaders drag-and-drop `.mp4` files in one tab. | **65%** | 25% | **16.25%** | Embed the `Courses` tab inside the main app shell + host Directus on a \$5/mo cloud VM |
| **3. Built-In Live Video Rooms ("Zoom Replacement")** | Circle Live Rooms / Zoom links for small groups & cohorts | **Working Preview (`PR #905` via GetStream)**: Up to 10-person video/audio calls, **no 40-minute cutoff**, calm muted/camera-off defaults, and **1-tap Guest Invite Links** (join by typing a name—no account required). | **70%** | 20% | **14.00%** | Fix 2-way audio unmute state bug (`#909`/`#919`) + add scheduled meeting calendar links (`#903`) |
| **4. Migration, Moderation & Safety** | CSV imports, member bans, admin controls | **Working Tools**: Circle.so CSV Audit/Parser CLI (`tool/import_circle_csv.dart`), admin ban rules (`#804`), Remote Config banners, and automated SQL backups. | **55%** | 10% | **5.50%** | Extend CSV CLI from audit to Firestore batch writer + self-serve "Create New Org" screen |
| **5. Stripe Billing & Subscriptions** | Org SaaS billing & paid member paywalls | **Web/PWA Architecture Ready**: Zero 30% Apple App Store commission; ready for standard Stripe Hosted Checkout. | **25%** | 10% | **2.50%** | 1 Stripe Checkout link + 1 webhook function (~3 days of work) |
| **HOLISTIC TOTAL** | **\$1,250 – \$2,600+/year** | **\$49/mo (\$588/yr) — Half the Price, 10x Calmer** | **~70.5%** | **100%** | **`70.45%`** | **~3–4 weeks of low-cost AI-assisted glue work** |

### Why "70% Built" Is Even Stronger Than It Sounds
In software, the hardest 70% is **proving the architecture and user experience across real devices**:
1. **Can non-technical pastors, teachers, and ministry leaders add courses and videos without a programmer?**
   - **Solved via Directus + Mux:** **Directus** is an open-source, visual web dashboard that sits directly on top of our PostgreSQL database. Instead of building a complicated custom "Teacher Studio" from scratch, we plugged Directus into **Mux** (the gold-standard video streaming engine). A non-technical leader opens Directus in their browser, types the lesson title and handout, drags an `.mp4` video onto the page, and switches the dropdown from `Draft` to `Published`. Seconds later, it streams in HD on every phone and computer.
2. **Can small groups, prayer circles, and classes meet live on video without paying for Zoom or forcing guests to create accounts?**
   - **Solved via GetStream Video (Preview):** Our built-in group video rooms let a member tap **Create Guest Link** and text it to a friend or visitor. The guest clicks the link, types their first name, and joins the video room right in their browser or phone—starting calmly with mic and camera off until they tap to unmute, with **no 40-minute limit** and **33,000–66,000 free participant-minutes per month** included on GetStream's monthly credit.
3. **Can we charge \$49/month (half of Circle's \$89–\$199/mo tiers) and still make software-grade margins?**
   - **Yes — 82% to 94% Gross Margins:** Within our Firebase, Supabase Postgres, Mux (100k free delivery mins/mo), and GetStream monthly credits, our hard infrastructure cost for an early 100-member church or ministry is **under \$3/month (~94% gross margin)**. Even past the free tier at steady-state paid usage (e.g., four 1-hour calls of 10 people/month = 2,400 participant-minutes × \$0.003/min = \$7.20 + ~\$1.50 DB/Mux storage = **~\$8.70/month**), a **\$49/month** plan still yields an **82%+ software gross margin** before adding **\$1,500–\$5,000** white-glove setup fees.

---

## 2. How to Pitch Customers AND Venture/Grants in Parallel (The 85% Overlap)

Pitching paying customers (churches, ministries, coaching guilds, neurodiversity/recovery non-profits) and pitching capital providers (angel investors, Christian family offices, disability/faith innovation grants) **do not require two separate products or two separate decks**. They overlap by **85%** around the **exact same 3-Minute Unified Demo** and **Founding 5 Customer Cohort**:

```mermaid
flowchart TD
    DEMO["3-Minute Unified Demo\n1. Calm Community (belongonthespectrum.web.app)\n2. Directus 1-Tab Video Courses (coursedemo-auxano-poc.web.app)\n3. 1-Tap Zoom-Style Video Rooms (GetStream)"]
    
    DEMO --> TRACK_A["TRACK A: Paying Customers\n• $1,500–$5,000 White-Glove Setup\n• $49–$99/mo Hosted Community + Courses"]
    DEMO --> TRACK_B["TRACK B: Capital, Angels & Grants\n• Faith & Disability Foundations\n• Values-Aligned Angels / Seed"]
    
    TRACK_A -->|"3–5 Paying 'Founding Orgs'\n+ Video Testimonials"| PROOF["Undeniable Market Proof\n• Immediate Cash Flow\n• Proven Willingness to Pay\n• Zero Desperation at the Investor Table"]
    PROOF --> TRACK_B
```

### The Shared 3-Minute Demo Script (Works for Both Pastors/Leaders AND Investors)
1. **Minute 1 — The Calm Community (`belongonthespectrum.web.app`):**
   - *"Look at how noisy Facebook Groups, Discord, and Circle are. Now look at Belong on Refuge: zero red unread badges, four soothing visual modes, compulsory intent tags like `[Comfort Only]` and `[Prayer Request]`, and a 1-tap Prayer Sanctuary. Our own church community left Circle.so on October 31 and lives here today."*
2. **Minute 2 — Courses & Non-Technical Content Studio (`coursedemo-auxano-poc.web.app`):**
   - *"Ministry leaders and coaches don't just chat—they teach courses and discipleship cohorts. Here is our Course & Workbook experience streaming HD video with interactive reflection inventories. And behind the scenes, non-technical staff don't touch code: they use Directus to drag-and-drop an `.mp4` video and publish a new lesson in one tab."*
3. **Minute 3 — Built-In Zoom-Style Live Rooms + The Half-Price Offer:**
   - *"Instead of juggling a separate Zoom subscription and broken links, hosts generate a 1-tap Guest Invite Link right inside the app—visitors join by typing their name with no 40-minute cutoff. Circle + Zoom costs \$1,400 to \$2,500+ a year. We offer the entire calm suite for **\$49/month**, plus optional white-glove setup."*

### How Each Track Builds the Other
- **Why Customers Care:** They save 50%+ every month, stop losing sensitive members to social media noise, and get human help setting up their spaces and first course.
- **Why Investors & Grantmakers Care:** Nothing convinces an angel investor, venture partner, or ministry foundation faster than hearing: *"Our first community already cut the cord on Circle.so, our marginal cost is under \$3/month per organization, and our business/ministry partner is onboarding our Founding 5 paying organizations right now."*

---

## 3. Talking to Tonight's Potential Partner (Marketing, Management, Leadership & Sales Pro with Ministry Background)

A seasoned leader in **marketing, management, leadership, and sales with a ministry background** brings the exact half of the company that an AI coding agent *cannot* build: **trust, relational credibility with pastors/leaders, clear packaging, curriculum storytelling, and repeatable human onboarding.**

### A. How to Open the Conversation Tonight (Suggested Framing)
> *"Right now, the software is holistically about 70% of the way to replacing Circle.so, Zoom, and course platforms at half the price. Our home community already left Circle on October 31, our video course engine with non-technical authoring is live in proof-of-concept, and our built-in Zoom-style video rooms are working in preview. With AI coding workflows, finishing the remaining 30% of technical glue—like wiring Stripe checkout and merging the course tab into the main screen—costs pennies and takes weeks, not years.*
>
> *What technology cannot do is build relationships with ministry and community leaders, shape an irresistible offer, design life-giving course templates, and lead organizations through a warm transition. That is where your gift in marketing, leadership, management, and ministry shines. I'd love to explore how we could team up over the next 90 days—in a 100% non-technical lane—to turn this into real traction."*

### B. 5 High-Impact Non-Technical Ways They Can Drive Real Progress in 90 Days

| Month | Focus Area | Concrete Non-Technical Actions the Partner Can Own | Tangible 30-Day Outcome |
| :--- | :--- | :--- | :--- |
| **Month 1 (Days 1–30)** | **Positioning, Packaging & "Zero-Code" Flagship Content** | 1. **Leader Discovery Calls (10–15 warm conversations):** Interview pastors, ministry directors, Christian coaches, and non-profit leaders on their current frustration with Facebook, Circle, Zoom, and Sunday-only church apps.<br>2. **Sharpen the "Founding 5" Offer:** Package a clear, no-brainer charter offer (e.g., **\$1,500 White-Glove Setup + \$49/mo Hosted Community & Courses**).<br>3. **Author 2 Turnkey Starter Courses in Directus:** Use the visual Directus dashboard (zero code!) to create two plug-and-play course templates every church/ministry wants (*"New Member Welcome & DNA"* and *"Small Group / Mentor Leadership 101"*). | • Validated 1-page sales sheet<br>• 2 live turnkey courses ready to clone for any new customer<br>• Pipeline of 10+ warm prospects |
| **Month 2 (Days 31–60)** | **Closing & Onboarding the "Founding 5" Cohort** | 1. **Close First 3–5 Paying Organizations:** Run live 20-minute demos showing Community + Courses + Built-In Video Rooms.<br>2. **Lead Concierge "White-Glove" Onboarding:** Guide each organization's leader through a 60-minute kickoff call: choosing their 5–6 room names, uploading their welcome video into Directus, and inviting their first 20 core members.<br>3. **Collect Feedback & Testimonials:** Capture before/after stories and quotes from the leaders and members. | • **\$4,500–\$15,000** in upfront setup revenue + first recurring SaaS MRR<br>• 3–5 active communities live on the platform |
| **Month 3 (Days 61–90)** | **Repeatable Sales Playbook, Networks & Capital/Grant Pitch** | 1. **Turn Founding 5 into Case Studies:** Record two 90-second video stories with pastors/organizers explaining why their people love the calm experience and how much money they saved.<br>2. **Pitch Regional Multipliers:** Approach church networks, denominations, coaching guilds, and disability ministries where 1 relationship = 10–50 local chapters.<br>3. **Co-Pitch Grants & Values-Aligned Capital:** Present the live revenue, retention, and case studies to faith/disability grant foundations and values-aligned angel investors. | • Repeatable onboarding playbook<br>• Regional network pipeline<br>• Ready for seed/angel round or profitable self-funded scaling |

---

## 4. Five Questions to Ask Your Potential Partner Tonight

Instead of pitching at them for an hour, show the 3-minute demo and ask these five questions to invite their leadership instincts:

1. **The Gut-Check Question:** *"When you look at a church, ministry, or coaching community getting Calm Spaces + Video Courses + Built-In Zoom Rooms for \$49/month instead of paying \$150+/month across Circle and Zoom, who are the first three leaders in your network who would immediately want to see this?"*
2. **The Packaging Question:** *"With your sales and ministry background, how would you package the 'White-Glove Setup + Turnkey Discipleship/Leadership Course' offer so a busy pastor or executive director says 'Yes, do it for us' on the first call?"*
3. **The Content Moat Question:** *"Since Directus lets you add courses and videos without touching code, what 2 or 3 'pre-loaded' ministry or leadership courses could we include out-of-the-box so a church isn't buying an empty software shell, but a ready-to-run ministry toolkit?"*
4. **The 90-Day Rhythm Question:** *"If we set a simple 90-day goal together—say, onboarding 5 founding organizations and generating our first \$10k–\$20k in setup and recurring revenue—what weekly rhythm and role would feel energizing and life-giving for you?"*
5. **The Alignment & Incentives Question:** *"What structure feels fairest to you for a 90-day sprint that grows into a long-term partnership—for example, taking the lion's share (e.g., 50–70%) of every White-Glove Setup fee you close and onboard right away, alongside meaningful co-founder/partner equity milestones as we hit our first 5 and 20 organizations?"*

---

## 5. Summary of the Remaining ~30% Technical Glue (Already Specced for Low-Cost AI Execution)

To reassure your partner that engineering won't bottleneck their sales:
- **Week 1 (`~45 mins` AI agent run):** Fix the GetStream 2-way audio unmute state sync (`#919`) and merge the Zoom-style guest video rooms into the main preview build.
- **Week 2 (`~2 hours` AI agent run):** Embed the `Courses` tab directly inside the main navigation bar behind an organization feature toggle and host the Directus authoring dashboard on a persistent cloud URL so the partner can log in from their laptop anytime.
- **Week 3 (`~2 hours` AI agent run):** Connect a 1-click **Stripe Checkout** link for the \$49/mo plan and \$1,500 white-glove onboarding package so customers can pay by card or ACH in 60 seconds.
