# Open Alpha Pre-Invite Production Deploy & Members-Only Smoke Runbook

> **Target Release**: `v0.8.0-alpha` (update tag per deploy)  
> **Parent Milestone**: Epic [#616](https://github.com/neiljaywarner/refuge/issues/616) (Path to 93%+)  
> **Related**: [#664](https://github.com/neiljaywarner/refuge/issues/664) (open alpha smoke + seed acceptance)  
> **Long-Term Automation Note**: GitHub Actions deploy-on-merge ([#493](https://github.com/neiljaywarner/refuge/issues/493)) is the long-term continuous deployment infrastructure. This manual runbook serves as the verified bridge ensuring that community playtesters hit a fresh, **members-only** production build for the open alpha playtest.

---

## 1. Prerequisites & Environment Verification

Deployments are executed using the unified release tool `tool/deploy_release.dart`.

### Environment Variables
Ensure the following standard environment variables are configured in your shell (no secrets are committed or printed):
- `APTABASE_KEY` *(Optional)*: Aptabase analytics app key for privacy-preserving community telemetry. Leave unset or empty for mock mode.
- `POSTHOG_KEY` *(Optional)*: PostHog analytics key. Leave unset or empty for mock mode.
- `FIREBASE_TOKEN` or active Google / Firebase CLI session (`firebase login`).

Verify current git branch and status before deploying:
```bash
git checkout main
git pull origin main
git status
```
Ensure working tree is clean and points to the latest merged commit on `origin/main`.

---

## 2. Deployment Steps

### Step 2A: Dry Run (Optional Validation)
Preview the release notes and actions without building or touching Firebase:
```bash
dart run tool/deploy_release.dart --version v0.8.0-alpha --dry-run
```

### Step 2B: Deploy Preview Channel First (Recommended)
Before promoting directly to live production, deploy a short-lived Firebase Hosting preview channel:
```bash
dart run tool/deploy_release.dart --version v0.8.0-alpha --channel pre-invite-rc
```
This builds Flutter Web in release mode targeting `lib/main_prod.dart` with `FLAVOR=prod`, sets `GIT_COMMIT_SHA`, `BUILD_TIME_MS`, and `RELEASE_TAG`, and deploys to `https://belongonthespectrum--pre-invite-rc-<hash>.web.app`.

### Step 2C: Deploy Live Production
Once preview is confirmed, execute the live production deployment to `https://belongonthespectrum.web.app`:
```bash
dart run tool/deploy_release.dart --version v0.8.0-alpha --prod
```
The deploy script:
1. Compiles Flutter Web release bundle (`-t lib/main_prod.dart`, `--dart-define=FLAVOR=prod`, plus git commit SHA & build time).
2. Generates `build/web/version.json` containing `git_sha`, `build_time_ms`, and `build_time_utc`.
3. Deploys Firebase Hosting configuration to production site `belongonthespectrum`.
4. Outputs the live URL: `https://belongonthespectrum.web.app`.

---

## 3. Build Stamp Verification

Immediately after deployment completes, verify that the live site is serving the fresh build:

1. **Check Live Version JSON via curl**:
   ```bash
   curl -s https://belongonthespectrum.web.app/version.json
   ```
   Confirm that `"git_sha"` matches the latest commit on `main`.

2. **Check In-App About Stamp**:
   - Open [https://belongonthespectrum.web.app](https://belongonthespectrum.web.app) in an incognito/private browser window.
   - Click the **About** (`info_outline`) button in the top AppBar.
   - Verify the displayed:
     - **Version tag**: matches your deploy tag (e.g. `v0.8.0-alpha`)
     - **Git Commit SHA**: 7-character short commit hash matching `git rev-parse --short HEAD`
     - **Build Time**: UTC timestamp corresponding to your deployment run.

---

## 4. 15-Minute Unauthenticated Smoke Checklist (≤10 Steps)

A calm, low-stress smoke checklist designed for an organizer to verify **members-only** behavior in under 15 minutes before broadcasting the invite link. There is **no guest browsing** and **no Demo Mode** banner after [#668](https://github.com/neiljaywarner/refuge/pull/668).

| # | Check | Action | Expected Result |
|---|---|---|---|
| **1** | **Sign-in wall on arrival** | Load `https://belongonthespectrum.web.app` in an incognito/private window (not signed in). | **Sign In** wall appears (Google, email/password, magic link). No community feed, no Demo Mode banner, no sample “guest” reflections. |
| **2** | **Monastic Dark Contrast** | From the sign-in wall, open sensory/theme controls if exposed, or sign in on a test account and toggle Monastic Dark. | Deep charcoal background with crisp, readable text and high-contrast chips. Zero washed-out gray text. |
| **3** | **Narrow Web hit targets** | At 360px–400px width, confirm primary actions on the sign-in wall are tappable without layout overlap. | Controls respond cleanly; no accidental navigation off-site. |
| **4** | **Verified member reaches home** | Sign in with a **verified** production test account (see internal test roster). | Home feed or calm empty state loads; profile avatar visible; no `auth_gate_sign_in_wall`. |
| **5** | **Unverified prod gate** | Sign in with an **unverified** prod test account (if available). | Verify-email wall appears until the inbox link is confirmed (prod-only policy). |
| **6** | **Browser Back Button** | From a space room or modal sheet, press the browser Back button. | App navigates back cleanly within the client rather than exiting or reloading into a blank screen. |
| **7** | **Zero test-junk scrub** | Scroll the signed-in feed (or empty state). | No test artifacts (`test 123`, `asdf`, debug gibberish). *Empty-space starter seed is tracked separately in #664.* |
| **8** | **Members-only actions** | While signed out, attempt to react or post via deep links or stale tabs. | User remains on sign-in or verify-email wall; no silent guest posting. |
| **9** | **PWA Installability** | On Chrome (desktop or Android), verify install icon; on iOS Safari, check “Add to Home Screen”. | Web App Manifest resolves with Belong icon and calm theme color. |
| **10** | **Feedback Sheet Access** | Signed in, tap **Vote & Feedback** and confirm feedback options appear. | In-app feedback form displays clearly; primary channel during open alpha. |

---

## 5. Post-Deployment Record Template

Copy and record these details in the deployment audit log or ticket comment:
```markdown
- **Deployment Timestamp**: YYYY-MM-DD HH:MM UTC
- **Deployed Version**: v0.8.0-alpha
- **Commit SHA**: <7-char-sha>
- **Hosting URL**: https://belongonthespectrum.web.app
- **Members-Only Smoke Status**: 10/10 PASS (sign-in wall + verified path)
- **Verified By**: @neiljaywarner
```
