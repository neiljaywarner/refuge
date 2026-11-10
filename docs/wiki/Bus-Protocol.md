# 🚌 Bus Protocol & Organizational Continuity Guide

> **Plain-English Promise**: If the founding maintainer (Neil) is ever unavailable, hospitalized, or "hit by a bus," **Belong on the Spectrum does not disappear, shut down, or hold the community hostage.**  
> Core Belong runs on a **\$0/month serverless tier with no expiring credit card**, and **100% of the source code and security rules are public on GitHub**.

This guide is written for two readers working side by side:
1. **Non-Technical Leaders**: **Belong on the Spectrum's Administrator** and **DFW Church (`dfwchurch.org`) Leadership** (start with the **First-Hour Reassurance** below and **Scenario 3**).
2. **A Trusted Developer or Church IT Volunteer**: Anyone helping maintain, take over, or rebuild the community (see **Scenario 1** and **Scenario 2**).

---

## 🕊️ First-Hour Reassurance for Organizers (Read This First in an Emergency)

If you just learned that Neil is unreachable and you are worried about members losing their community tonight:

1. **Belong stays online automatically**: `https://belongonthespectrum.web.app/` runs on Google Firebase's free Spark tier (**\$0/month**, no credit card required). **There is no monthly server bill that will bounce and shut the site down next week.**
2. **Everyday moderation keeps working**: Anyone already signed in with an organizer account listed in Belong's admin settings (and `rules_admins`) can continue welcoming members and removing harmful accounts right inside the app—see **[Ban a Member](Admin-Pause-and-Restore)**.
3. **Only Appwrite extras pause after 7 days without Console development activity**: Appwrite Cloud handles closed-app phone alerts (`dm-push`), the direct-message mirror (`dm-mirror`), and the spare copy. The Free plan pauses that project after 7 days with no development activity in the Appwrite Console. Opens of Belong, and API calls, do not count. Signing in, reading spaces, posting, replying, and sending Direct Messages inside Belong stay on Firebase. See [Leave-alone free backends](Leave-Alone-Free-Backends.md).
4. **Nothing is locked in a private vault to rebuild**: Because `https://github.com/neiljaywarner/refuge` is completely open-source, any Flutter/web developer recruited by **DFW Church** or **Belong leadership** can recreate a brand-new working deployment from source in **about 90 minutes** (**Scenario 1**) even before legal account transfers finish (**Scenario 3**).

---

## 🛡️ Section 0: 15-Minute "Pre-Bus" Prevention Checklist (Do While Healthy)

Completing these six 2-minute steps eliminates 95% of emergency paperwork before an emergency ever happens:

| # | System | Live Identifier | Preventive Action (While Healthy) |
| :--- | :--- | :--- | :--- |
| **1** | **Google / Firebase (`belongonthespectrum`)** | GCP Project `belongonthespectrum` | Open `https://console.cloud.google.com/iam-admin/iam?project=belongonthespectrum` and grant **Owner** (or **Editor** + **Firebase Admin**) to both the **Belong Administrator** Google account and a designated **DFW Church (`dfwchurch.org`)** staff/elder Google account. |
| **2** | **Firestore Admin Rules (`rules_admins`)** | Collection `rules_admins/{uid}` | In Firebase Console → **Authentication → Users**, copy each organizer's **User UID**. In **Firestore Database → Data**, create `rules_admins/<uid>` with `{ "role": "organizer" }`, and verify their email is in Remote Config `admin_emails_csv`. |
| **3** | **Google Inactive Account Manager** | Founder Google Account | Configure `https://myaccount.google.com/inactive` (e.g., 3-month inactivity window) to notify the Belong Administrator and DFW Church contact with instructions. |
| **4** | **GitHub Repository & Successor** | `neiljaywarner/refuge` & private `neiljaywarner/belong_feedback` | Set a designated **GitHub Account Successor** at `https://github.com/settings/admin` (*Successor settings*), and invite the successor as a collaborator on `refuge` and `belong_feedback` (or transfer both to a shared `belongonthespectrum` GitHub Organization with 2+ Owners). |
| **5** | **Domain Registrar (`belongonthespectrum.com`)** | Registrar: **Porkbun (`porkbun.com`)** | In Porkbun → **Account → Authorized Users**, add the Belong Administrator or DFW Church IT contact as an authorized user for `belongonthespectrum.com`, and keep multi-year auto-renew enabled. |
| **6** | **Shared Emergency Vault / Envelope** | 1Password / Bitwarden Emergency Access | Store recovery notes for: (a) Appwrite Cloud project `6adae5c40013c409e109` (note: Appwrite Free `tier-0` allows only 1 owner seat and pauses after 7 days with no Console development activity; an API call does not reset that clock), (b) Remote Config Giphy keys, and (c) weekly encrypted Firestore JSON snapshots. |

---

## 🛠️ Scenario 1: Recreate Everything From Source (`Zero-Access Cold Rebuild` in ~90 Minutes)

**Use this scenario when**: You have **zero access** to the original Firebase, Appwrite, GitHub secrets, or domain accounts—only the public repository `https://github.com/neiljaywarner/refuge`—and want a 100% functional Belong community running on a brand-new **\$0/month** Firebase account.

### 1.1 Architecture Truth Table (What Lives in Git vs. Cloud)

| Component | Source of Truth in Git | Required on Day 1? | Cold-Rebuild Strategy |
| :--- | :--- | :---: | :--- |
| **Web PWA & Android Client** | `lib/`, `web/`, `android/`, `pubspec.yaml` | **Yes** | Builds cleanly with Flutter `3.47.7`. Android release APK builds without a proprietary `.jks` keystore (`android/app/build.gradle.kts` falls back to local signing until Play Store upload key creation). |
| **Auth & Primary Database** | `firestore.rules`, `firestore.indexes.json` | **Yes** | Create a new free **Firebase Spark** project (`\$0/mo`), enable Email/Password Auth, create `(default)` Firestore DB, and deploy rules. |
| **Storage Rules (Optional Media)** | `storage.rules` | Optional | Presets + Giphy GIFs work with **zero** Cloud Storage bucket. Only enable Firebase Blaze (with a \$5 budget alert) if you want custom binary photo uploads (`storage.rules`). |
| **Organizer Welcome & Giphy Config** | Keys documented in §1.5 below + `config/remote_config/backup_mirroring.json` | **Yes** | Paste the 7 non-secret parameters + organizer email list into Firebase Remote Config Console. |
| **Legacy Serverpod Code** | `sanctuary_server/` | **No (Off)** | `ENABLE_SERVERPOD` defaults to `false` across all build scripts. Ignore completely. |
| **Appwrite Push & Mirror** | `appwrite/functions/dm-push/`, `appwrite/functions/dm-mirror/` | **No (Optional)** | Pass `--dart-define=APPWRITE_ENDPOINT=` on Day 1 to run **100% pure Firebase** (in-app DMs still work via Firestore!). Optionally stand up a free Appwrite project later (§1.8). |

### 1.2 Prerequisites (15 Minutes)

Install on macOS, Linux, or Windows:
- **Git** + **Flutter `3.47.7`** (stable channel, Dart `^3.13.5`)
- **Node.js `22`** + Firebase CLI: `npm install -g firebase-tools`
- **FlutterFire CLI**: `dart pub global activate flutterfire_cli`

Clone the public repository:
```bash
git clone https://github.com/neiljaywarner/refuge.git
cd refuge
flutter pub get
```

### 1.3 Create the New Firebase Project (`\$0` Spark Tier — 15 Minutes)

1. Sign in to `https://console.firebase.google.com/` using an **organizational Google account** owned by Belong or DFW Church (for example, an account managed under your church Google Workspace—never a single person's private inbox alone), and immediately add a **second Owner** in Project Settings → Users and permissions.
2. Click **Create a project** (for example, `belong-community-prod`). Leave billing on the free **Spark (\$0/mo)** plan.
3. Enable **Authentication**:
   - **Build → Authentication → Get started → Sign-in method** → Enable **Email/Password** (and optionally *Email link*).
   - Under **Authentication → Settings → Authorized domains**, verify `<your-project>.web.app` (and your custom domain if attaching one) are listed.
4. Create **Cloud Firestore**:
   - **Build → Firestore Database → Create database** → Choose `(default)` in `nam5` (`us-central`) → Start in production mode (we deploy `firestore.rules` in §1.5).
5. Create **Firebase Hosting** sites:
   - **Build → Hosting → Get started** creates your primary production site (`<prod-site>`).
   - Optional dev staging site: At the bottom of Hosting, click **Add another site** → `dev-<prod-site>`.
6. Register Apps in **Project Settings → General → Your apps**:
   - **Web app**: Register `Belong on the Spectrum (Web)` and note its `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`, and `storageBucket`.
   - **Android apps** (if building APKs): Register `com.belongonthespectrum.sanctuary` (prod) and `com.belongonthespectrum.refuge.dev` (dev), and download `google-services.json` to `android/app/google-services.json` (gitignored by design).

### 1.4 Repoint the 8 Project Configuration Files (15 Minutes)

Update these exact repository files from `belongonthespectrum` to your `<new-project-id>` and `<prod-site>`:

1. **`.firebaserc`**: Replace `"belongonthespectrum"` under `default`, `prod`, and `dev` with `"<new-project-id>"`.
2. **`firebase.json`**: Update `"site": "<prod-site>"`.
3. **`firebase.dev.json`**: Update `"site": "dev-<prod-site>"`.
4. **`lib/src/core/firebase/firebase_initializer.dart`**: Replace the client `FirebaseOptions` constants in `webOptions` and `androidOptions` (`apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`, `storageBucket`) with the values from your new Firebase Project Settings (or run `flutterfire configure --project=<new-project-id>`).
5. **`web/firebase-messaging-sw.js`**: Replace the `firebase.initializeApp({...})` Web config block with the same new Web `FirebaseOptions`.
6. **`tool/deploy_release.dart`**: Update `_project`, `_prodUrl`, and `_repo` (if building from your new GitHub org fork).
7. **`tool/deploy_dev_web.dart`**: Update `_project`, `_siteId`, and `_devUrl`.
8. **Pure-Firebase Day-1 Switch (Skip Appwrite)**: Either pass `--dart-define=APPWRITE_ENDPOINT=` at build time (shown in §1.7) or set the default `_defaultEndpoint` in `lib/src/core/appwrite/appwrite_config.dart` to `''` so the client runs 100% on Firebase with zero calls to the old Appwrite project.

### 1.5 Deploy Security Rules & Seed Remote Config (15 Minutes)

Authenticate Firebase CLI and deploy Firestore rules + indexes:
```bash
firebase login
firebase deploy --only firestore:rules,firestore:indexes --project <new-project-id>
```
*(Only run `firebase deploy --only storage --project <new-project-id>` if you enabled a Cloud Storage bucket.)*

Next, open **Firebase Console → Run → Remote Config** and publish these parameters:

| Parameter Key | Type | Recommended Initial Value | Purpose |
| :--- | :--- | :--- | :--- |
| `organizer_banner_enabled` | Boolean | `true` | Shows the calm welcome banner at the top of Feed. |
| `organizer_welcome_title` | String | `Welcome to Belong on the Spectrum` | Heading on the community welcome card. |
| `organizer_welcome_message` | String | `Take your time exploring the spaces—no pressure to post until you feel ready.` | Editable organizer welcome note (see [Update the Welcome Message](Organizer-Remote-Config-Guide)). |
| `dfw_church_url` | String | `https://dfwchurch.org` | Partner church link in the Spaces directory. |
| `admin_emails_csv` | String | `<comma-separated organizer emails>` | Controls which signed-in accounts see the in-app **Ban Member** controls. |
| `giphy_content_rating` | String | `pg` | Locks GIF search to family/sensory-safe `pg` rating. |
| `giphy_api_key_web` | String | `<optional free key from developers.giphy.com>` | Enables in-app GIF picker on Web (gracefully hidden if blank). |
| `giphy_api_key_android` | String | `<optional free key from developers.giphy.com>` | Enables in-app GIF picker on Android. |
| `backup_mirroring_config` | JSON | Copy `config/remote_config/backup_mirroring.json` | Keeps secondary mirroring safely off until configured. |

### 1.6 Seed Organizer `rules_admins/{uid}` & Optional Circle History (10 Minutes)

1. Build or run Web locally (`flutter run -d chrome --dart-define=APPWRITE_ENDPOINT=`), register your first **Organizer** account with Email/Password, and verify the email link.
2. In **Firebase Console → Authentication → Users**, copy that organizer's **User UID**.
3. In **Firestore Database → Data**, create collection `rules_admins`, document ID `<organizer_uid>`, with `{ "role": "organizer" }`. *(Without this document, `firestore.rules` blocks `Ban Member` writes with `PERMISSION_DENIED`!)*
4. *(Optional)* If you have a Circle.so CSV export or want warm starter posts, follow **[Bring Past Posts Over](Circle-CSV-Migration-Guide)** (`dart run tool/import_circle_csv.dart --help`).

### 1.7 Build & Deploy Web PWA + Android APK (15 Minutes)

Deploy live Production Web PWA (pure-Firebase mode, zero Appwrite dependency):
```bash
flutter build web --release \
  --dart-define=FLAVOR=prod \
  --dart-define=ENABLE_SERVERPOD=false \
  --dart-define=APPWRITE_ENDPOINT= \
  --dart-define=APP_VERSION=v1.0.0

firebase deploy --only hosting --config firebase.json --project <new-project-id>
```

Build shareable Android Release APK:
```bash
flutter build apk --release \
  --dart-define=FLAVOR=prod \
  --dart-define=ENABLE_SERVERPOD=false \
  --dart-define=APPWRITE_ENDPOINT=
```
The signed APK is output at `build/app/outputs/flutter-apk/app-release.apk`.

### 1.8 Optional Phase 2: Restore Closed-App Push (`Appwrite`) & GitHub Actions CI/CD

Whenever you want closed-app phone push alerts (`dm-push`) and secondary DM mirroring (`dm-mirror`):
1. Create a free Appwrite Cloud project (`https://cloud.appwrite.io`), create database `belong_community_db` with tables `push_devices` and `direct_messages`, and deploy `appwrite/functions/dm-push` and `appwrite/functions/dm-mirror` following their `README.md` guides (`docs/wiki/Direct-Message-Push-Function.md`).
2. In your GitHub fork's **Settings → Secrets and variables → Actions**, add `FIREBASE_SERVICE_ACCOUNT` (a GCP service account JSON with `Firebase Hosting Admin` + `Service Usage Consumer` roles) so `.github/workflows/deploy.yml` deploys automatically on every push to `main` and every `v*` tag.

---

## 🔑 Scenario 2: Operate, Export & Deploy With Existing Firebase Access (`Warm Takeover`)

**Use this scenario when**: Neil granted your Google account access to Firebase project **`belongonthespectrum`** (or you recovered access via Scenario 3), and you want to run, back up, or deploy updates to the live community.

### 2.1 Verify Access & Immediately Export Full Backups (10 Minutes)

```bash
npm install -g firebase-tools
firebase login
firebase projects:list
# Confirm you see: belongonthespectrum
```

Before changing anything, pull a local safety copy of Auth accounts and Remote Config:
```bash
# 1. Export Firebase Authentication user list (UIDs, emails, password hashes)
firebase auth:export belong_auth_users_backup.json \
  --format=json \
  --project belongonthespectrum

# 2. Export live Firebase Remote Config template
firebase remoteconfig:get \
  -o belong_remote_config_backup.json \
  --project belongonthespectrum
```
> **Security Note**: Store both exported `.json` files in an encrypted church/organization vault—**never** inside the git repository.

### 2.2 Day-to-Day Organizer Operations (No Coding Needed)

- **Change the Welcome Banner**: Follow **[Update the Welcome Message](Organizer-Remote-Config-Guide)** in Firebase Console → Remote Config (`organizer_welcome_title`, `organizer_welcome_message`, `organizer_banner_enabled`).
- **Add or Remove an Organizer (Two Places Required!)**:
  1. **UI visibility**: Add/remove their email in Remote Config → `admin_emails_csv` → **Publish changes**.
  2. **Database enforcement**: Add/delete empty document `rules_admins/<their_firebase_auth_uid>` in **Firestore Database → Data**.
- **Ban a Harmful Account**: Follow **[Ban a Member](Admin-Pause-and-Restore)** from inside the app.

### 2.3 Deploy Code, Security Rules, or Roll Back Hosting

Clone `https://github.com/neiljaywarner/refuge.git` (or fork it to a new church/Belong GitHub Organization if GitHub write access hasn't transferred yet—Firebase deployments run from **any** clone as long as `firebase login` has access to `belongonthespectrum`!):

```bash
# Deploy updated Firestore security rules
firebase deploy --only firestore:rules --project belongonthespectrum

# Deploy to Staging / Dev Web (https://dev-belongonthespectrum.web.app)
dart run tool/deploy_dev_web.dart --version dev-check

# Dry-run Production Release Plan first
dart run tool/deploy_release.dart --version v1.0.1 --prod --dry-run

# Publish to Production Web (https://belongonthespectrum.web.app)
dart run tool/deploy_release.dart --version v1.0.1 --prod
```

**1-Minute Emergency Hosting Rollback**:
- Open `https://console.firebase.google.com/project/belongonthespectrum/hosting/sites/belongonthespectrum` → **Release history** → click the three-dot menu on the previous healthy release → **Rollback**.

### 2.4 Mint a Fresh `FIREBASE_SERVICE_ACCOUNT` for a New GitHub Organization

If you forked `neiljaywarner/refuge` to a new `belongonthespectrum` or `dfwchurch` GitHub Organization:
1. Open `https://console.cloud.google.com/iam-admin/serviceaccounts?project=belongonthespectrum`.
2. Create service account `github-hosting-deployer`, grant roles **`Firebase Hosting Admin`** (`roles/firebasehosting.admin`) and **`Service Usage Consumer`** (`roles/serviceusage.serviceUsageConsumer`), and download a JSON key.
3. Paste that JSON into your new GitHub repo's **Settings → Secrets and variables → Actions → `FIREBASE_SERVICE_ACCOUNT`**. Every push to `main` now deploys `dev-belongonthespectrum.web.app` automatically, and every `v*` tag deploys `belongonthespectrum.web.app`.

### 2.5 What If Appwrite (`6adae5c40013c409e109`) Pauses While You Only Have Firebase Access?

- Appwrite Cloud Free (`tier-0`) pauses after **7 days with no Console development activity**. Runtime, API, SDK, and end-user traffic do not count ([changelog, 20 February 2026](https://appwrite.io/changelog/entry/2026-02-20-1)).
- **Impact**: Core Belong (`belongonthespectrum.web.app`, sign-in, all 8 rooms, comments, reactions, bookmarks, in-app Direct Messages, voting, and feedback) **stays on Firebase**. The pause stops `dm-push`, `dm-mirror`, and the spare/mirror path.
- **Clean Fix**: Either deploy with an empty `--dart-define=APPWRITE_ENDPOINT=` for a pure-Firebase build, or stand up a new Appwrite project from `appwrite/functions/dm-push` and `appwrite/functions/dm-mirror` and pass both `--dart-define=APPWRITE_ENDPOINT=<regional-api-endpoint>` and `--dart-define=APPWRITE_PROJECT_ID=<new-id>`. The client default endpoint is `https://nyc.cloud.appwrite.io/v1`. A project id alone still calls NYC, so push and mirror can fail when the new project is in another region. An empty endpoint skips Appwrite. Firestore can still accept the direct message, and the client can then log `Direct message mirror failed`. That line is the mirror diagnostic, not a Firebase write failure. Restore the same project from the Appwrite Console when you still have that login. A new leave-alone free backend, when one is needed, prefers Supabase Free ([Leave-alone free backends](Leave-Alone-Free-Backends.md)). That preference is not a cutover of the live site.

---

## 🚨 Scenario 3: Emergency "Hit by a Bus" Recovery Without Prior Access (For DFW Church & Belong's Administrator)

**Use this scenario when**: Neil is incapacitated or deceased, forgot to grant you Firebase/domain/GitHub access beforehand, and you are **Belong on the Spectrum's Administrator** and/or **DFW Church (`https://dfwchurch.org`) Leadership** stepping in to protect the community.

### 3.1 Immediate Stabilization (Hours 0–2 — Zero Vendor Wait Required)

1. **Verify the live community is up**: Open `https://belongonthespectrum.web.app/`. Because it runs on Firebase Spark (`\$0/mo`, no credit card on file), it will continue serving members indefinitely while you complete formal account transfers below.
2. **Fork the public codebase & wiki immediately**:
   - Have any trusted developer or church IT volunteer create a free GitHub Organization (e.g., `belong-community` or `dfwchurch-tech`) and click **Fork** on `https://github.com/neiljaywarner/refuge` (and `git clone https://github.com/neiljaywarner/refuge.wiki.git`).
   - You now hold 100% of the code, tests, security rules, and documentation in an organization you control—**zero waiting on support tickets**.
3. **Coordinate with Neil's family / next-of-kin / estate representative**:
   - Google, Porkbun, and GitHub will **not** hand over a personal account on a third party's word alone (which protects the community from social-engineering hijackers!). Every provider below has a standard **Incapacitated / Deceased Account Holder** legal process that moves smoothly when **Neil's spouse/next-of-kin/executor** signs alongside **DFW Church / Belong leadership**.

---

### 3.2 Track A — Recovering Google / Firebase Project `belongonthespectrum`

1. **Check Google Inactive Account Manager First**:
   - Ask the **Belong Administrator**, **DFW Church office**, and **Neil's family** to search their email inboxes for automated messages from Google's **Inactive Account Manager** (`no-reply@accounts.google.com`). If configured, Google automatically notifies trusted contacts after the inactivity period.
2. **If Family / Estate Has Device or Recovery Access**:
   - Have Neil's authorized family representative open `https://console.cloud.google.com/iam-admin/iam?project=belongonthespectrum`, click **Grant access**, and add the organizational Google account for **Belong's Administrator** and **DFW Church** as **`Owner`**. Once added, switch immediately to **Scenario 2** above!
3. **Formal Google Incapacitated / Deceased Account Request (When Nobody Has Login Access)**:
   - Open Google's official form: search *"Submit a request regarding a deceased user's account — Google Account Help"* (`https://support.google.com/accounts/troubleshooter/6357590`).
   - Submit jointly with **next-of-kin / executor documentation** (government ID + proof of authority / power of attorney / death certificate as applicable) **plus** an organizational continuity letter on **DFW Church (`dfwchurch.org`) letterhead** signed by church leadership and Belong's Administrator stating:
     - **Google Cloud / Firebase Project ID**: `belongonthespectrum`
     - **Live Firebase Hosting URLs**: `https://belongonthespectrum.web.app` and `https://dev-belongonthespectrum.web.app`
     - **Public Proof of Organizational Partnership**: `https://github.com/neiljaywarner/refuge` (which publicly names **Belong on the Spectrum** and partner **[DFW Church](https://dfwchurch.org)** in `docs/wiki/Home.md` and Remote Config `dfw_church_url`)
     - **Requested Action**: Grant GCP/Firebase Project `Owner` IAM role on project `belongonthespectrum` to your designated organizational Google Workspace account so the ministry community can continue operating safely without accessing personal Gmail messages.

---

### 3.3 Track B — Recovering Domain `belongonthespectrum.com` (Registrar: Porkbun)

The public domain **`belongonthespectrum.com`** (`https://www.belongonthespectrum.com/`) is registered at **Porkbun (`https://porkbun.com`)**. Unlike Firebase Spark, a `.com` domain **does** have an annual registration renewal (~`\$11/year`), so recover this before its annual expiration date:

1. Check `whois belongonthespectrum.com` (or `https://lookup.icann.org`) to see the exact domain `Registry Expiry Date` so you know your timeline (typically months away).
2. Contact **Porkbun Support** (`support@porkbun.com`, `https://porkbun.com/support`) with the subject: **`Deceased / Incapacitated Account Holder — Domain Continuity Request for belongonthespectrum.com`**.
3. Attach next-of-kin / estate authorization alongside DFW Church / Belong organizational verification requesting domain transfer into an organizational Porkbun account with church/ministry billing enabled.
4. Once inside Porkbun DNS, you can also point `app.belongonthespectrum.com` (or root `belongonthespectrum.com`) to either the recovered `belongonthespectrum` Firebase Hosting site or a fresh **Scenario 1** Firebase Hosting site at any time.

---

### 3.4 Track C — Recovering GitHub (`neiljaywarner/refuge` & Private `belong_feedback`)

1. **Immediate Continuity (Day 1)**: Fork `https://github.com/neiljaywarner/refuge` into an organizational GitHub account (§3.1)—you never need to wait on GitHub Support to ship fixes or deploy to Firebase.
2. **Formal GitHub Successor / Deceased User Policy**:
   - Contact **GitHub Support** (`https://support.github.com/contact`) under GitHub's **Deceased User Policy**.
   - Provide the link to `https://github.com/neiljaywarner/refuge` (and private issue tracker `neiljaywarner/belong_feedback`), next-of-kin authorization, and the designated GitHub Successor username so GitHub can transfer repository ownership cleanly.

---

### 3.5 Track D — Replacing Secondary Free Services (Appwrite, Giphy, PostHog, Aptabase)

**Do not waste weeks filing legal recovery tickets for these secondary free-tier developer accounts**—none of them hold irreplaceable primary community data (`ADR-0011` keeps all primary posts, profiles, votes, feedback, and messages in Firestore):

- **Appwrite Cloud (`6adae5c40013c409e109`)**: Free org plan `tier-0` pauses after 7 days with no Console development activity. API traffic does not keep it awake. Disable Appwrite (`--dart-define=APPWRITE_ENDPOINT=`) or deploy a fresh Appwrite project from `appwrite/functions/` in 20 minutes (§1.8). Details: [Leave-alone free backends](Leave-Alone-Free-Backends.md).
- **Giphy (`developers.giphy.com`)**: Any organizer or developer can create a free Giphy app in 3 minutes and paste the new key into Firebase Remote Config (`giphy_api_key_web`, `giphy_api_key_android`).
- **PostHog & Aptabase Analytics**: Optional `--dart-define` telemetry keys (`POSTHOG_KEY`, `APTABASE_KEY`); leaving them blank disables external analytics cleanly with zero impact on members.

---

### 3.6 Track E — When to Trigger the "Lifeboat Cutover" (If Legal Recovery Takes Weeks)

If an urgent security or app change cannot wait 2–4 weeks for Google Support to finish Track A:
1. Have a volunteer developer execute **Scenario 1** above (~90 minutes) to stand up a fresh organizational Firebase project (`belong-community-prod.web.app`).
2. Post a calm announcement banner inside the existing `belongonthespectrum.web.app` (using any active organizer account in **Announcements** and **Start Here**) sharing the new link (or swap DNS once Porkbun Track B completes) so members step smoothly into the new home.

---

## 🔗 Related Operational Guides

- **[🚦 Ops / Deploy Readiness](Ops-Deploy-Readiness)** — Current Firebase Spark/Blaze status, deployed rules, and pre-release checks
- **[📣 Update the Welcome Message](Organizer-Remote-Config-Guide)** — Non-technical Firebase Remote Config steps for organizers
- **[🚫 Ban a Member](Admin-Pause-and-Restore)** — How organizer moderation works (`admin_emails_csv` + `rules_admins/{uid}`)
- **[🗄️ One Database Plus a Backup (ADR-0011)](Reflection-Redundancy-and-Backup)** — Why Firestore is the single source of truth
- **[🗄️ Leave-alone free backends](Leave-Alone-Free-Backends.md)** — Prefer Supabase Free when a vendor console visit cannot be the keepalive. Appwrite Free still hosts `dm-push`, `dm-mirror`, and the spare copy.
- **[🧪 CI/CD FAQ and Troubleshooting](CI-CD-FAQ)** — GitHub Actions pipelines (`ci.yml`, `deploy.yml`, `sync-wiki.yml`)
