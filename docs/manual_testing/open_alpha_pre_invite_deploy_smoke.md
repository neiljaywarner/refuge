# Open Alpha Pre-Invite Production Deploy & Guest Smoke Runbook

> **Target Release**: `v0.8.0-alpha`  
> **Parent Milestone**: Epic [#616](https://github.com/neiljaywarner/refuge/issues/616) (Path to 93%+)  
> **Long-Term Automation Note**: GitHub Actions deploy-on-merge ([#493](https://github.com/neiljaywarner/refuge/issues/493)) is the long-term continuous deployment infrastructure. This manual runbook serves as the verified bridge ensuring that community playtesters hit a fresh, authenticated production build for the 3-day open alpha playtest.

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
     - **Version tag**: `v0.8.0-alpha`
     - **Git Commit SHA**: 7-character short commit hash matching `git rev-parse --short HEAD`
     - **Build Time**: UTC timestamp corresponding to your deployment run.

---

## 4. 15-Minute Guest Smoke Checklist (≤10 Steps)

A calm, low-stress smoke checklist designed for an organizer to verify guest experience in under 15 minutes before broadcasting the invite link:

| # | Check | Action | Expected Result |
|---|---|---|---|
| **1** | **Home Feed Arrival** | Load `https://belongonthespectrum.web.app` as an unauthenticated guest. | Feed renders smoothly with quiet, calming reflections. No infinite spinners. |
| **2** | **Dark theme contrast** | Toggle theme to **Dark** (Sensory menu / palette icon). | Deep charcoal background (`#0D0F11`) with crisp, readable text (`#F0F3F6`) and high-contrast chips (`#28313B`). Zero washed-out gray text. |
| **3** | **Narrow Web Hit Targets** | Open developer tools at 360px–400px phone width; tap **Vote & Feedback**. | Bottom sheet opens cleanly; does **not** trigger or pop up the `+` Create Post menu. |
| **4** | **Space Title & Navigation** | Tap **Spaces** in the sub-header bar, then tap any room (e.g., *Sensory Sanctuary* or *Coding & Tech*). | Space room title is displayed at top (`# Coding & Tech`). Back button or "All Spaces" returns cleanly to directory. |
| **5** | **Sign In Sheet** | Tap the profile / Sign In button in the AppBar. | Authentication modal opens cleanly displaying Sign In with Google, Magic Link, and credentials. Cancel / Close returns to feed. |
| **6** | **Browser Back Button** | From inside a Space or modal sheet, press the browser's Back button. | App navigates back cleanly within the client rather than exiting or reloading into a blank screen. |
| **7** | **Zero Test-Junk Scrub** | Scroll through the initial feed posts. | All visible reflections are genuine community anchor posts. No test artifacts (`test 123`, `asdf`, debug gibberish). |
| **8** | **Guest Reaction & Read Only** | Tap a reaction or attempt to post without signing in. | Clean, non-intrusive sign-in prompt invites the user without jarring error toasts. |
| **9** | **PWA Installability** | On Chrome (desktop or Android), verify install icon in address bar; on iOS Safari, check "Add to Home Screen". | Web App Manifest resolves cleanly with Belong icon and calm theme color. |
| **10** | **Feedback Sheet Access** | Tap **Vote & Feedback** and confirm feedback options appear. | In-app feedback form displays clearly; instructions note that in-app feedback is the primary communication channel during open alpha. |

---

## 5. Post-Deployment Record Template

Copy and record these details in the deployment audit log or ticket comment:
```markdown
- **Deployment Timestamp**: YYYY-MM-DD HH:MM UTC
- **Deployed Version**: v0.8.0-alpha
- **Commit SHA**: <7-char-sha>
- **Hosting URL**: https://belongonthespectrum.web.app
- **Guest Smoke Status**: 10/10 PASS
- **Verified By**: @neiljaywarner
```
