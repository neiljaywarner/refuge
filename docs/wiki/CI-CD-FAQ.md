# CI/CD FAQ and troubleshooting

This page is for people and agents shipping Belong. Member-facing deploy steps stay in [DEPLOYMENT.md](https://github.com/neiljaywarner/refuge/blob/main/DEPLOYMENT.md).

Parent epic: [#513](https://github.com/neiljaywarner/refuge/issues/513).

## What runs where

| Check | Local hook | Pull request CI | Merge to `main` |
| --- | --- | --- | --- |
| `dart format -l 100` on staged Dart | pre-commit | `lib`, `test`, `tool`, `packages/belong_lints` at 100 columns | |
| `dart analyze` for Belong lint rules | pre-commit | fails on `no_print_use_app_logger`, `prefer_use_text_editing_controller`, and `dispose_controllers` | |
| Unit and widget tests | optional, see below | manifest in `tool/ci_widget_test_manifest.txt` (81 files on `main` as of Oct 2026), 40% floor on `lcov.info` from that run | |
| Privacy scan | pre-push | | |
| Firebase Hosting (dev site on `main`; production on release) | | | deploy workflow |
| Patrol, Maestro, Firebase Test Lab | | | manual or a later workflow |
| GitHub Release and App Distribution | | | manual, or a deploy `workflow_dispatch` input for Android |

Install hooks once per clone:

```bash
dart run tool/install_git_hooks.dart
```

That sets `core.hooksPath` to `.githooks` for this clone only. Do not pass `--no-verify` unless a hook is broken and you are fixing the hook in the same push.

Full `flutter test` is not on pre-commit. The suite is larger than the two-minute commit budget. CI runs it. To run a small slice before push:

```bash
REFUGE_PRE_PUSH_TESTS=1 git push
```

## FAQ

### Why is coverage not 100%?

The floor is 40% line coverage. Very Good Ventures workflows default to 100% and a spell checker. We do not. The goal is to stop large untested drops, not to chase a perfect number.

CI runs the largest passing subset of `flutter test` (81 `*_test.dart` files listed in `tool/ci_widget_test_manifest.txt`). The full tree compiles on `main`, but some cases in other files still fail (Patrol/BDD/UI drift). The widened manifest run records line coverage in `coverage/lcov.info` from those tests. Integration tests, Patrol, and Maestro stay outside this floor. Shrink or grow the manifest in a reviewed pull request when failures are fixed or new ones appear.

`tool/check_line_coverage.dart` reads `coverage/lcov.info` and exits non-zero under the floor.

### Why did CI fail on `dart format`?

CI runs `dart format --output=none --set-exit-if-changed -l 100` on `lib`, `test`, `tool`, and `packages/belong_lints`. `analysis_options.yaml` sets `formatter.line_length: 100` so editors match.

Fix a format failure with `dart format -l 100 <path>`. The pre-commit hook formats staged Dart files at the same width.

### Why did analyze fail on `no_print_use_app_logger`?

Under `lib/`, call `AppLogger.debug`, `AppLogger.info`, `AppLogger.warning`, or `AppLogger.error`. Do not call `print` or `developer.log`. `tool/` command-line scripts may still write to stdout.

`custom_lint` 0.8.1 cannot be added on this SDK. It supports analyzer 8, and Dart 3.13 loads analyzer plugins through `analysis_server_plugin`. The same checks live in `packages/belong_lints`. Run `dart analyze` from the repository root to see them. `flutter analyze` on this SDK does not report those plugin diagnostics. Restart the analysis server after pulling the plugin.

CI runs `dart analyze` and fails the job when `no_print_use_app_logger`, `prefer_use_text_editing_controller`, or pyramid_lint `dispose_controllers` appears. Other analyzer errors already on `main` do not fail that step.

### Why did analyze fail on `prefer_use_text_editing_controller`?

Inside a hook widget (`HookWidget`, `HookConsumerWidget`, or hook state), create text fields with `useTextEditingController()`. Do not construct `TextEditingController()` there.

A `StatefulWidget` that keeps a controller and disposes it in `dispose` is allowed. pyramid_lint `dispose_controllers` is the check that the controller is disposed. pyramid_lint 3 does not ship a separate "prefer useTextEditingController" rule, so Belong's plugin owns that one.

### Why did analyze fail on `dispose_controllers`?

A `ChangeNotifier` controller (`TextEditingController`, `ScrollController`, `AnimationController`, and similar) was created and not disposed. Dispose it in `State.dispose`, or switch the widget to a hook and `useTextEditingController`.

### Why are fat-arrow bodies and single quotes not required yet?

`prefer_expression_function_bodies` and `prefer_single_quotes` are enabled in `analysis_options.yaml` after the [#519](https://github.com/neiljaywarner/refuge/issues/519) sweep. CI still fails only on the three Belong plugin rules above; run `dart fix --apply` locally when analyze reports these style hints. Switch expressions are preferred in review when they stay readable.

### Primary constructors (#609)

On Dart 3.13+ (our SDK pin), use **primary constructors** for small immutable value types: declare `final` fields in the class header instead of repeating them in a constructor body.

Example (synthetic test type only):

```dart
class const Point(final int x, final int y);
```

Production pilots include `CalmPushDisplay`, `AvatarCropResult`, and `lib/src/core/geometry/point.dart`. Do not use primary constructors on widgets, repositories, or types with heavy `factory` / side-effect logic. A custom `belong_lints` rule is optional later ([#609](https://github.com/neiljaywarner/refuge/issues/609)).

### Dot shorthands (#610)

When the context type is known (for example `padding:` expects `EdgeInsets`), prefer constructor dot-shorthands: `const .symmetric(...)`, `const .all(...)`, `.circular(...)`, and enum-style `.start` on `CrossAxisAlignment`. Pilot started in `lib/src/core/presentation/`; most other `lib/` files use shorthands after [#632](https://github.com/neiljaywarner/refuge/issues/632). `home_screen.dart` may lag during parallel agent work. Skip shorthands when the analyzer reports `dot_shorthand_missing_context`. A custom `belong_lints` rule is deferred ([#610](https://github.com/neiljaywarner/refuge/issues/610)).

### Why did the deploy workflow fail before the Flutter build?

The job needs one of these repository secrets, and neither is committed:

- `FIREBASE_SERVICE_ACCOUNT`: JSON for a Google service account that can deploy Firebase Hosting for project `belongonthespectrum`.
- `FIREBASE_TOKEN`: a Firebase CI token, used when the service account secret is absent.

Optional: `FIREBASE_ANDROID_APP_ID` when a manual run uploads an APK. Without it, the script tries to detect an Android app in the Firebase project.

A dry run does not need those secrets:

GitHub Actions → Deploy → Run workflow → dry run enabled.

### How is the private feedback GitHub token created?

`FEEDBACK_GITHUB_PAT` is a fine-grained personal access token created in the GitHub web UI, then stored as a secret on the Appwrite function `feedback-forward`. The steps, including the Firebase Admin JSON secret and the preview stamp check, are in [Feedback forward function](Feedback-Forward-Function). Do not commit the token or the service-account JSON.

### What does a merge to `main` deploy?

Since [#586](https://github.com/neiljaywarner/refuge/issues/586), a **push to `main`** runs `tool/deploy_dev_web.dart`. That builds Flutter web for the **dev** site and deploys **`https://dev-belongonthespectrum.web.app`**. The workflow also uploads a **`refuge-dev-release-apk`** artifact (and may distribute a dev APK when `FIREBASE_ANDROID_DEV_APP_ID` is set). It does **not** update production Hosting.

**Production** (`https://belongonthespectrum.web.app`) deploys only when:

- someone pushes a **`v*` tag** (the workflow runs `tool/deploy_release.dart --prod`), or
- someone starts **Deploy → Run workflow** with **Publish production Hosting** enabled (`workflow_dispatch` with `production: true`).

Preview channels from `tool/deploy_release.dart` are short-lived release candidates, not the dev site. GitHub Releases and App Distribution still follow DEPLOYMENT.md or the manual workflow inputs.

The version string for an automatic **dev** deploy is `ci-` plus the first seven characters of the commit SHA. The About screen still shows the full 40-character SHA from the dart-define when the binary was built with one.

### Hosting is up, but About still shows `unknown` or an old SHA

`unknown` means that binary was not built with the dart-defines. A local `flutter run` does that on purpose. A Hosting deploy from the GitHub workflow should show the full SHA and a UTC build time.

If production shows an older SHA than `main`, the deploy job failed or a newer commit has not finished deploying. Compare the About SHA with the commit on `main`. Do not invent a SHA in the client. Rollback steps are in DEPLOYMENT.md.

### How do we handle Dependabot pull requests?

Dependabot opens weekly pull requests for pub packages and GitHub Actions. Minor and patch updates are grouped. There is no auto-merge. CI must pass. Read the changelog on a major update before merging. Do not merge a dependency PR that fails analyze or tests.

### When do we run Firebase Test Lab or App Distribution?

Not on every pull request. Test Lab needs a built Android test APK and cloud device time. The steps are in [Firebase Test Lab and Patrol](Firebase-Test-Lab-and-Patrol-Guide). App Distribution is the manual deploy input above, or `tool/deploy_release.dart --distribute-android` locally. Tester emails stay in the Firebase console, not in git.

### Text styles

Prefer `BelongTextStyles.of(context)` (`title`, `body`, `caption`, `emphasis`) over a new inline `TextStyle` with a raw font size and color. The extension is attached in `SensoryThemeData`. Widgetbook and a separate design-system package are not part of this pass.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Hook says `dart: command not found` | Flutter's `bin` directory is on `PATH` in the hook's shell. |
| Plugin diagnostics never appear in the IDE | Restart the Dart analysis server after `flutter pub get`. |
| `flutter analyze` warns that a plugin failed to load | Run `flutter pub get` at the repo root so `packages/belong_lints` is fetched. |
| Deploy log stops at "Missing Firebase credentials" | Add `FIREBASE_SERVICE_ACCOUNT` or `FIREBASE_TOKEN` in repository secrets. |
| Preview channel or Hosting deploy returns 403 | The service account needs Firebase Hosting admin on project `belongonthespectrum`, plus **`roles/serviceusage.serviceUsageConsumer`** so the Firebase CLI can call Google APIs ([#627](https://github.com/neiljaywarner/refuge/issues/627)). |
| Coverage job fails around the floor | Look at the printed `hit/found` line. Add tests or, if the suite shrank for a good reason, change `--min` in `.github/workflows/ci.yml` in a reviewed PR. |
| Format CI and your editor disagree | Both should use `dart format -l 100` (or `formatter.line_length: 100` in analysis_options). |
