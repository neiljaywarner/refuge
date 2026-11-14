# Line coverage

Line coverage is the share of instrumented lines hit by `tool/ci_widget_test_manifest.txt`. It is not every Dart line in the repository. Device Patrol and Maestro do not write `coverage/lcov.info`.

Flutter is pinned to 3.47.7, the same version as pull-request CI.

## Baseline on main

Measured on `d02979c` before these test pull requests, with:

```bash
mapfile -t CI_TEST_FILES < <(grep -v '^#' tool/ci_widget_test_manifest.txt | grep -v '^[[:space:]]*$')
flutter test --coverage --reporter compact "${CI_TEST_FILES[@]}"
dart run tool/check_line_coverage.dart --file coverage/lcov.info
dart run tool/lcov_summary.dart coverage/lcov.info
```

**72.6% (10,407 / 14,326)** across 200 files. The command above reported 746 passed tests and 6 skipped.

| Folder | Lines hit | Lines found | Coverage |
| --- | ---: | ---: | ---: |
| features/reflections | 1,936 | 2,810 | 68.9% |
| features/profile | 947 | 1,440 | 65.8% |
| core | 1,134 | 1,543 | 73.5% |
| features/notifications | 452 | 837 | 54.0% |
| features/auth | 814 | 1,175 | 69.3% |
| features/feedback | 1,085 | 1,358 | 79.9% |
| features/group_call | 727 | 918 | 79.2% |
| features/messages | 991 | 1,160 | 85.4% |
| home_screen.dart | 349 | 510 | 68.4% |
| features/account_deletion | 103 | 244 | 42.2% |
| features/admin | 177 | 313 | 56.5% |
| features/search | 39 | 63 | 61.9% |
| features/memes | 605 | 672 | 90.0% |
| core/appwrite (soft-launch slice) | 303 | 526 | 57.6% |

Soft-launch slices from `tool/lcov_summary.dart`: auth 69.3%, spaces 92.7%, vote & feedback 79.9%, home 68.4%, reflections 68.9%, appwrite 57.6%, install links 83.8%.

## Combined result

The test pull requests each branch from that same `main`. Together they add unit and widget tests, and they add passing tests that were already in the tree but not in the manifest. A local run of the union (every manifest entry from those pull requests, one `coverage/lcov.info`) is:

**80.5% (11,528 / 14,326)** across the same 200 files.

That is **+7.8 percentage points**. The denominator did not grow: 1,121 lines that were already instrumented are now hit. 914 tests passed and 6 were skipped.

| Folder | Lines hit | Lines found | Coverage |
| --- | ---: | ---: | ---: |
| features/reflections | 2,365 | 2,810 | 84.2% |
| features/profile | 962 | 1,440 | 66.8% |
| core | 1,331 | 1,543 | 86.3% |
| features/notifications | 538 | 837 | 64.3% |
| features/auth | 884 | 1,175 | 75.2% |
| features/feedback | 1,171 | 1,358 | 86.2% |
| features/group_call | 798 | 918 | 86.9% |
| features/messages | 1,009 | 1,160 | 87.0% |
| home_screen.dart | 374 | 510 | 73.3% |
| features/account_deletion | 202 | 244 | 82.8% |
| features/admin | 191 | 313 | 61.0% |
| features/search | 50 | 63 | 79.4% |
| features/memes | 605 | 672 | 90.0% |
| core/appwrite (soft-launch slice) | 484 | 526 | 92.0% |

Soft-launch slices after the union: auth 75.2%, spaces 92.7%, vote & feedback 86.2%, home 73.3%, reflections 84.2%, appwrite 92.0%, install links 83.8%.

HTTP, Firebase, and Serverpod are faked or pointed at a closed local port. No live token endpoint is called, and no API secret is compiled into these tests.

Screen sharing is not on `main` (it is still an open pull request). The call tests cover guest seat refresh, mint errors, a camera-off and microphone-off join, and Start/Stop of the microphone and camera controls that exist today.

Issue #956's drawer is not on `main`. Large-text home coverage opens the Spaces section, which is the on-main stand-in, at text scale 2.0.

## Patrol on an Android emulator

One `patrolTest` walks the sign-in wall, Skip for now, the home feed at text scale 2.0, Spaces, the composer, a muted lobby join, and microphone/camera Start/Stop. It pumps a local repository. It does not need a password or a Stream secret.

```bash
flutter pub get
adb shell settings put system font_scale 2.0
patrol test --target integration_test/coverage_journeys_patrol_test.dart
adb shell settings put system font_scale 1.0
```

`patrol` must be on `PATH` (`dart pub global activate patrol_cli` if it is not). The emulator is the device Patrol selects. This VM has no emulator, so the target was analyzed with `flutter analyze` and was not executed here.

## Maestro on an Android emulator

Install a dev debug build (`com.belongonthespectrum.refuge.dev`). Do not commit `BELONG_DEV_E2E_EMAIL` or `MAESTRO_TEST_PASSWORD`. The home, composer, and call flows read those from the environment through `.maestro/subflows/dev_saved_account_home.yaml`. The sign-in flow does not.

```bash
adb shell settings put system font_scale 2.0
maestro test .maestro/coverage_sign_in_guest_skip.yaml
maestro test .maestro/coverage_home_font_scale_and_composer.yaml
adb shell settings put system font_scale 1.0
maestro test .maestro/coverage_call_lobby_camera_mic.yaml
```

`Join call` is in the binary only when it was built with `STREAM_VIDEO_PREVIEW=true` and a `STREAM_TOKEN_ENDPOINT`. A normal dev APK skips the lobby steps. Do not put a Stream API secret in the build. There is no screen-share control on `main`; the call flow asserts that, then toggles the microphone and camera when those buttons are on screen.
