# 📱 Driving Pixels (and other real devices)

How humans and AI agents run, drive, and verify **Belong on the Spectrum** on physical phones. **Update this file whenever you learn something.** (Issue #73)

## 1. Tool priority (most preferred first)

| Priority | Tool | Use it for | Notes |
| :---: | :--- | :--- | :--- |
| 1 | **Marionette MCP / `marionette` CLI** | Interactive driving of a running **dev/debug** build: list widgets, tap, type, scroll, hot reload | Needs `MarionetteBinding` (only in `lib/main_dev.dart`, non-release). Prefer `get_interactive_elements` (~200 tokens) over screenshots (~1,500+). |
| 2 | **Patrol** (`patrol test`, Patrol MCP) | Repeatable native E2E tests; auto video + failure screenshots | `patrol test --record-video` → attach video to PRs. |
| 3 | **`flutter test integration_test -d <device>`** | On-device integration tests | Needs `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`. **`run_tests` (Dart MCP) does NOT run `integration_test/`.** |
| 4 | **Maestro** (`.maestro/*.yaml`) | Black-box flows against the installed app | Not installed yet (`brew install maestro`) |
| last | **`adb`** | Install, launch, screenshot, logcat, wake. **Not** for tapping. | Use the SDK adb (see §4). |

## 2. Device

| Device | Serial | Notes |
| :--- | :--- | :--- |
| Pixel 9a / Android Device | Auto-detected (`adb devices`) | USB; turn on Developer options → **Stay awake** |

## 3. Recipes

```bash
# Auto-detect device ID
DEVICE=$(adb devices | grep -v "List" | grep "device$" | head -n 1 | awk '{print $1}')

# Run the dev build (Marionette-drivable) on the Pixel / Android device
flutter run -t lib/main_dev.dart -d "$DEVICE"

# On-device integration tests
flutter test integration_test -d "$DEVICE"

# Install + launch the release APK (smoke test what testers get)
flutter build apk --release
adb -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-release.apk
adb -s "$DEVICE" shell monkey -p com.belongonthespectrum.sanctuary -c android.intent.category.LAUNCHER 1

# Screenshot for a PR / wiki (never commit to the main repo; use the wiki assets or PR uploads)
adb -s "$DEVICE" exec-out screencap -p > shot.png
```

## 4. Learnings & troubleshooting (newest first)

| Date | Symptom | Cause | Fix |
| :--- | :--- | :--- | :--- |
| Oct 18 | Marionette can't connect to the app | App had no `marionette_flutter` binding | Added `MarionetteBinding.ensureInitialized()` to `lib/main_dev.dart` (non-release only) (#73) |
| Oct 18 | The integration test from #61 had never run | `integration_test` wasn't a dev dependency, and `run_tests` skips `integration_test/` | Added the dep + binding; run with `flutter test integration_test -d <device>` (#73) |
| Oct 18 | `adb: device ... not found`, though the phone is plugged in | Two adb binaries (Homebrew cask + SDK) fighting over port 5037 | `adb kill-server` for both, then start only `~/Library/Android/sdk/platform-tools/adb` |
| Oct 18 | Release APK build fails: `Could not find com.google.firebase:firebase-inappmessaging` | Unused `firebase_in_app_messaging` with unresolvable artifacts | Removed (#69); re-add properly in #72 |
| Oct 18 | `LicenceNotAcceptedException` / `sdkmanager not found` | Flutter pointed at Homebrew platform-tools (not a full SDK) | Install the SDK via Android Studio; `flutter config --android-sdk ~/Library/Android/sdk`; maintainer accepts licenses |
| Oct 18 | `JAVA_HOME is set to an invalid directory` | Stale JDK path in Flutter config | `flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"` |

## 5. Verified on device

| Date | Build | What was checked | Result |
| :--- | :--- | :--- | :--- |
| Oct 18 | v0.2.0 (2) release APK (pre-alpha) | Install + cold launch; header, Feed/Spaces, Vote & Feedback button, organizer banner, composer, bottom nav render | ✅ No crash |
