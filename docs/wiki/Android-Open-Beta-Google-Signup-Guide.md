# Android open beta and Google signup

> **Updated**: Sunday, November 1, 2026 (America/Chicago).  
> **In the app**: **Spaces → Links → Download the Android App** (same words as [Get Belong on your phone](Get-Belong-on-Your-Phone)).  
> **Tracks**: [#737](https://github.com/neiljaywarner/refuge/issues/737), [#746](https://github.com/neiljaywarner/refuge/pull/746), [#788](https://github.com/neiljaywarner/refuge/issues/788).

---

## TL;DR

On your **Android phone**, tap **Open the Android beta** in Belong. The **first time only**, Google may ask you to sign in and tap **Sign up** on a card that says it will **share your email address with the developer**. **Developer means Belong.** That is not a waitlist and you are not creating a Firebase account. After that, tap **Download** and install. **Google Play** is still **Pending**.

---

## Summary

Belong’s Android app is in an **open beta** through **Firebase App Distribution** (Google’s pre–Play Store handout page). Anyone with the link can join; Google still requires a one-time signup so Belong knows which Google account may receive the build.

Members see calm copy **before** they leave Belong, an **info** control that explains Google’s email sentence, and two links:

| Button | When to use | URL (Belong `belongonthespectrum`) |
| --- | --- | --- |
| **Open the Android beta** | Everyday download (ongoing beta) | `https://appdistribution.firebase.google.com/testerapps/1:207506875171:android:e578634c4bc21da2b96296` |
| **First time? Sign up with Google** | Google says you have no apps yet, or you have not completed Sign up | `https://appdistribution.firebase.google.com/i/be440f5ac9684d13` |

Play Store, App Store, and TestFlight stay **Pending** in **Spaces → Links** until real store listings exist.

---

## For members (plain language)

You do not need to know what “beta,” “Firebase,” or “pre-release” mean.

### What you will see

1. In Belong, open **Spaces → Links → Download the Android App**.
2. Read the short Android section. It says the first visit may include Google **Sign up**. That is normal.
3. On your **Android phone** (not a computer), tap **Open the Android beta**.
4. If Google asks you to **Sign in**, use the Google account already on the phone (Gmail is fine).
5. If Google shows:

   > Sign up to share your email address with the developer and get access.

   **Developer = Belong on the Spectrum.** Tap **Sign up**. You are not joining a waiting list. You are not signing up for a product called Firebase.
6. Tap **Download**, then **Install**. If Android warns about **unknown apps**, follow the steps in the guide (allow only for this install; you can turn it off again). **Leave Play Protect on.**
7. Next time, **Open the Android beta** should go straight to **Download**.

### If Google says you have no apps yet

Tap **First time? Sign up with Google**, complete **Sign up**, then tap **Open the Android beta** again.

### Official help from Google (optional)

- [Get set up as a tester (Android)](https://firebase.google.com/docs/app-distribution/get-set-up-as-a-tester?platform=android)
- [If the phone blocks the install](https://firebase.google.com/docs/app-distribution/troubleshooting?platform=android)
- [Download apps from other sources (Pixel help)](https://support.google.com/pixelphone/answer/7391672?hl=en)
- [About Play Protect](https://support.google.com/android/answer/2812853?hl=en)

### Pictures

When a volunteer captures a **real** Google signup screen, crop out names, emails, and avatars before adding it under `docs/wiki/images/android-beta-signup/`. Do not use a generic sign-in screenshot or a drawn mockup.

---

## For organizers and developers (technical)

### What “open beta” means here

- **Open**: Belong’s invite link has **no email-domain restriction** in Firebase (anyone with the link can self-register as a tester).
- **Not frictionless**: Google **always** runs first-time tester acceptance (sign-in + optional “share email with developer”). Belong cannot embed or skip that UI in the PWA.
- **Not Play Store**: `android_app_download_url` in Remote Config remains reserved for a future Play listing ([#45](https://github.com/neiljaywarner/refuge/issues/45)).

### Canonical URLs in code

Defined in `lib/src/features/install/domain/phone_install_links.dart`:

| Constant | Purpose |
| --- | --- |
| `PhoneInstallLinks.androidBeta` | Durable **testerapps** URL for the Belong Android app (all future beta builds on that app id) |
| `PhoneInstallLinks.androidBetaSignup` | **Invite link** `/i/be440f5ac9684d13` for first-time Google signup |

Firebase Android app id (must match `google-services.json` / `firebase_initializer.dart`):

`1:207506875171:android:e578634c4bc21da2b96296`

Project: **belongonthespectrum** (project number `207506875171`).

### HTTP behavior (unsigned browser)

Both URLs redirect to `accounts.google.com` when the browser has no Google session, then return to App Distribution. That is expected; the in-app copy should say so.

### UI implementation (#788)

- `PhoneInstallGuideView`: blurb + `Wrap` (filled button + info `IconButton`) + signup `TextButton`; details in `_AndroidBetaMore`.
- No webview, no in-app email field, no new routes.
- Widget tests: `test/features/install/phone_install_guide_test.dart` (CI manifest).

### Verification commands

```bash
dart format --output=none --set-exit-if-changed -l 100 \
  lib/src/features/install/domain/phone_install_links.dart \
  lib/src/features/install/presentation/phone_install_guide_view.dart \
  test/features/install/phone_install_guide_test.dart
dart analyze lib/src/features/install test/features/install/phone_install_guide_test.dart
flutter test test/features/install/phone_install_guide_test.dart
```

### When to rotate links

- Regenerate the **invite link** in Firebase Console → App Distribution → **Invite links** if it is revoked or tied to the wrong group.
- Update `PhoneInstallLinks.androidBetaSignup` and this wiki in the same PR.
- Do **not** change `androidBeta` unless the Firebase **Android app id** changes (new Firebase app registration).

---

## Related pages

- [Get Belong on your phone](Get-Belong-on-Your-Phone) — full member install guide (iPhone website, pending stores)
- [Why we are not in the app stores yet](Why-No-App-Store-App)
- [QA and Beta Testing Guide](QA-and-Beta-Testing-Guide) — organizer distribution commands
