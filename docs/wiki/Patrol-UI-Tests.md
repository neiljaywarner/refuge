# Patrol UI tests

Patrol runs a build of this repo. It does not open `https://belongonthespectrum.web.app` or the dev site. A signed-out visit to those sites stops on the sign-in wall, and the home, composer, spaces directory, and Vote & Feedback screens are behind it. Patrol's read-only harness builds those screens in-process with a local post list and a guest profile, with sign-in turned off. Nothing in that harness is written to Firestore.

Maestro is the runner that can open the hosted URL. See [Maestro UI tests](Maestro-UI-Tests).

Android device farms and the daily workflow stay in [Firebase Test Lab & Patrol](Firebase-Test-Lab-and-Patrol-Guide). This page is how to run the same tests on a machine you have.

## Install

CI installs `patrol_cli` 4.8.0, which matches the `patrol` 4.10 dependency in `pubspec.yaml`.

```bash
dart pub global activate patrol_cli 4.8.0
# macOS and Linux. On Windows add %LOCALAPPDATA%\Pub\Cache\bin instead.
export PATH="$PATH:$HOME/.pub-cache/bin"
export PATROL_ANALYTICS_ENABLED=false
patrol doctor
```

`patrol doctor` wants `adb` and `ANDROID_HOME` for an emulator. Chrome-only runs still work when those are missing; the doctor prints the Android gap and continues.

Flutter on CI is 3.47.7 (`Dart` 3.13.5). Use that version when a newer stable SDK is not what `pubspec.yaml` asks for (`flutter: ">=3.47.7"`, `sdk: ^3.13.5`).

## Run on Chrome

`flutter devices` lists `chrome` when Google Chrome is installed.

```bash
patrol test -t integration_test/patrol_ftl_home_shell_test.dart -d chrome \
  --dart-define=FLAVOR=dev \
  --dart-define=BACKEND=local
```

`FLAVOR=dev` keeps the binary off the production package. `BACKEND=local` is extra safety for any code path that would otherwise open Firestore. The home-shell harness does not use that repository; it passes `LocalPostRepository` itself.

`flutter test integration_test/patrol_ftl_home_shell_test.dart` does not run the test body. `patrolTest` treats host `flutter test` as discovery (`PATROL_TEST_DISCOVERY`) and registers an empty case so the native runner can list tests. Use `patrol test`.

A file that uses `patrolWidgetTest` from `patrol_finders` (for example `integration_test/feed_sort_options_patrol_test.dart`) is a widget test. `flutter test` runs that body. It is not the same as `patrol test`.

Chrome runs print a Playwright summary and write `playwright-report/` and `test_bundle.dart` in the repo root. Do not commit those. The gitignore entry is `integration_test/test_bundle.dart`, which is the file Patrol tells you not to commit; the root `test_bundle.dart` from a web run is the same kind of generated file.

## Run on an Android emulator or phone

```bash
patrol test -t integration_test/patrol_ftl_home_shell_test.dart \
  --dart-define=FLAVOR=dev
```

With no `-d`, Patrol uses the first device `flutter devices` returns. Pass `-d emulator-5554` (or the hardware id) when more than one is connected. Native commands such as `pressHome` and the microphone permission dialog need this target. They do not run on Chrome.

Firebase Test Lab build and upload:

```bash
dart run tool/run_firebase_test_lab.dart --dry-run
dart run tool/run_firebase_test_lab.dart \
  --target integration_test/patrol_ftl_home_shell_test.dart
```

Details, IAM, and the panther matrix are in the [Test Lab guide](Firebase-Test-Lab-and-Patrol-Guide).

## What each file covers

| File | What it does | Chrome | Android |
| --- | --- | --- | --- |
| `integration_test/patrol_ftl_home_shell_test.dart` | Home branding, tone filter, sort control, Vote & Feedback. No post and no sign-in. | Yes | Yes, including the daily Test Lab smoke |
| `integration_test/patrol_ftl_bottom_nav_readonly_test.dart` | Search, Notifications, and Home via the bottom-nav keys. | Yes | Yes |
| `integration_test/large_text_patrol_test.dart` | Home, Direct Messages, and the Vote & Feedback sheet, then reads the text scale. It does not submit feedback. | Yes | Yes. The font-scale script is `tool/run_large_text_device_checks.sh` and is Android-only |
| `integration_test/patrol_ftl_attach_media_test.dart` | Attach-media sheet with an in-memory GIF search. Does not publish and does not call Giphy. | Yes | Yes. Dev APK only on Test Lab |
| `integration_test/patrol_hello_world_test.dart` | Legacy alias of the home-shell smoke. | Yes | Yes |
| `integration_test/patrol_ftl_native_resume_test.dart` | `pressHome` and `openApp` for the `.dev` package. | No | Yes |
| `integration_test/patrol_group_call_mic_test.dart` | Skips unless the binary was built with `STREAM_VIDEO_PREVIEW` and `STREAM_TOKEN_ENDPOINT`. Even then the guest harness hides Join call, so this file never reaches the microphone control. See [Stream video preview](Stream-Video-Preview). | The skip path runs. The permission dialogs do not. | The skip path runs. The on-device mute walk is not reached from this file. |
| `integration_test/feed_sort_options_patrol_test.dart` | `patrolWidgetTest` of every sort chip on a local home. | `flutter test`, not `patrol test` | Same |
| `integration_test/account_return_patrol_test.dart` | `patrolWidgetTest` of the return panel against an in-memory deletion sink. It does not call Firebase or the hosted site. | `flutter test` | `flutter test` |

`integration_test/patrol_app_harness.dart` is the shared setup: `RefugeApp` with `LocalPostRepository`, `enforceSignIn: false`, and a guest profile. A desktop-width window is forced to 390×844 so the phone composer stays on screen. A phone-width window is left alone (a forced 390×844 frame detaches the surface on panther).

## Group call preview

The public site does not compile the preview on. A signed-out page, on production or dev hosting, does not show Join call. Patrol's guest harness does not show it either. To exercise mute and camera you need a preview build and a signed-in member or a guest invite link, which this harness does not open. The headless mute cycles live in the Gherkin scenario under `test/features/group_call/`.

## Checked on Chrome, 2026-11-14

`patrol test -d chrome` with `FLAVOR=dev` and `BACKEND=local`, Flutter 3.47.7, `patrol_cli` 4.8.0:

| Target | Result |
| --- | --- |
| `patrol_ftl_home_shell_test.dart` | Passed |
| `patrol_ftl_bottom_nav_readonly_test.dart` | Passed |
| `large_text_patrol_test.dart` | Passed (home, messages, Vote & Feedback sheet) |
| `patrol_ftl_attach_media_test.dart` | Passed (GIF search and the Open Giphy stub, no publish) |

`patrol_ftl_native_resume_test.dart` was not run. This machine had Chrome and no Android SDK. `patrol_group_call_mic_test.dart` was not run against a preview binary.
