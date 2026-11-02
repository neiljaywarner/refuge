# Soft-launch coverage

Issue [#796](https://github.com/neiljaywarner/refuge/issues/796). Line coverage comes from unit and widget tests, including headless Patrol widget tests. Maestro and device Patrol guard the critical path. They are not the line-coverage driver.

## Default report (no device, no live backend)

From the repository root, with Flutter on `PATH`:

```bash
dart run tool/run_soft_launch_coverage.dart
```

The same command is `rps coverage`.

What it does:

1. Runs every file in `tool/ci_widget_test_manifest.txt` with `flutter test --coverage`.
2. Prints an overall percentage and soft-launch slices (auth, spaces, vote & feedback, home, reflections, appwrite, install links) via `tool/lcov_summary.dart`.
3. Checks the 40% floor with `tool/check_line_coverage.dart`.

The percentage is the share of lines **loaded by that run**, not every Dart line in the repository. Pull request CI runs the same manifest and the same floor.

`charlatan` 0.5.0 on pub.dev declares `sdk: <3.0.0` and does not resolve on the Dart 3.13 pin. HTTP fixtures use [`nock`](https://pub.dev/packages/nock) plus JSON cassettes in `test/fixtures/http/`. Nock replaces `dart:io` `HttpClient`, which is what `package:http` and the Appwrite SDK use. The feedback-forward function and TablesDB reflection rows are covered that way. Tests must not call live Firebase or Appwrite.

## Patrol

Headless cases use `patrolWidgetTest` from `patrol_finders` and already sit in the manifest, so they are in `coverage/lcov.info`:

- `test/features/soft_launch/soft_launch_critical_path_patrol_test.dart` — Home chrome, Spaces → Links → pending Community Guidelines, Vote & Feedback, and the unsigned sign-in wall.
- Existing `patrolWidgetTest` files that were already on the manifest (feed round trip, voting sheet, and others).

Device Patrol still needs a phone or emulator and is **not** part of the default percentage:

```bash
patrol test --target integration_test/patrol_ftl_home_shell_test.dart
```

`integration_test/` also has `patrolTest` flows for Firebase Test Lab. Run those with `dart run tool/run_firebase_test_lab.dart` when a device or lab target is available.

## Maestro critical smoke

Maestro does not write `lcov.info`. The soft-launch smoke set is:

| Flow | What it guards |
| --- | --- |
| `.maestro/sign_in_wall_unsigned.yaml` | Auth soft-gate. A signed-out launch stays on the sign-in wall. No saved account. |
| `.maestro/spaces_navigation_and_monogram_flow.yaml` | Spaces, the Links section (Community Guidelines, DFW Church, Android app), then the member directory. Does not tap links that leave the app. |
| `.maestro/feature_voting_flow.yaml` | Vote & Feedback opens. Read-only of the vote counts; it does not cast a vote. |

```bash
maestro test .maestro/sign_in_wall_unsigned.yaml \
  .maestro/spaces_navigation_and_monogram_flow.yaml \
  .maestro/feature_voting_flow.yaml
```

The spaces and vote flows sign in through `.maestro/subflows/dev_saved_account_home.yaml`. Credentials stay in the environment (`BELONG_DEV_E2E_EMAIL`, `MAESTRO_TEST_PASSWORD`). Do not commit them. Do not create extra production accounts or post into the live community from these flows.

Web smoke, when a local release server is up, is documented in [Maestro-UI-Tests.md](Maestro-UI-Tests.md). `feature_voting_web.yaml` covers Vote & Feedback on the web build.
