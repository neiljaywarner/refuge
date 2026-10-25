# CI/CD FAQ and troubleshooting

This page is for people and agents shipping Belong. Member-facing deploy steps stay in [DEPLOYMENT.md](https://github.com/neiljaywarner/refuge/blob/main/DEPLOYMENT.md).

Parent epic: [#513](https://github.com/neiljaywarner/refuge/issues/513).

## What runs where

| Check | Local hook | Pull request CI | Merge to `main` |
| --- | --- | --- | --- |
| `dart format` on staged Dart | pre-commit | files owned by the pipeline, until #519 | |
| `dart analyze` for Belong lint rules | pre-commit | fails on `no_print_use_app_logger`, `prefer_use_text_editing_controller`, and `dispose_controllers` | |
| Unit and widget tests | optional, see below | compiling slice, with a 40% line-coverage floor on the lines that slice loads | |
| Privacy scan | pre-push | | |
| Firebase Hosting preview, then production | | | deploy workflow |
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

CI currently runs a compiling slice (`test/core/build`, `test/core/theme`, `test/features/about`, and the coverage-tool test) because `flutter test` of the whole tree fails to compile: `lib/src/home_screen.dart` and `lib/src/features/messages/presentation/calm_notifications_view.dart` are out of date with the widgets they call. The 40% floor applies to the lines that slice loads (about 75% when this landed). It is not a measurement of the whole app. Widen the `flutter test` list in `.github/workflows/ci.yml` once the app compiles again. Integration tests, Patrol, and Maestro stay outside this floor.

`tool/check_line_coverage.dart` reads `coverage/lcov.info` and exits non-zero under the floor.

### Why did CI fail on `dart format`?

The format step checks the files the pipeline owns, at the SDK default line length. It does not format the whole repository yet. About 168 Dart files still differ from `dart format`, so a repo-wide check would be red. That sweep is [#519](https://github.com/neiljaywarner/refuge/issues/519). A 100-character page width lands in the same sweep.

Fix a format failure on a guarded file with `dart format <file>`. The pre-commit hook formats staged Dart files.

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

`prefer_expression_function_bodies` and `prefer_single_quotes` would fail on the current tree. They land with the mechanical sweep in [#519](https://github.com/neiljaywarner/refuge/issues/519). Switch expressions are preferred in review. There is no built-in lint that requires them.

### Why did the deploy workflow fail before the Flutter build?

The job needs one of these repository secrets, and neither is committed:

- `FIREBASE_SERVICE_ACCOUNT`: JSON for a Google service account that can deploy Firebase Hosting for project `belongonthespectrum`.
- `FIREBASE_TOKEN`: a Firebase CI token, used when the service account secret is absent.

Optional: `FIREBASE_ANDROID_APP_ID` when a manual run uploads an APK. Without it, the script tries to detect an Android app in the Firebase project.

A dry run does not need those secrets:

GitHub Actions → Deploy → Run workflow → dry run enabled.

### What does a merge to `main` deploy?

The deploy workflow checks out the commit, then runs `tool/deploy_release.dart`. That script builds Flutter web with `GIT_COMMIT_SHA`, `BUILD_TIME_MS`, and `RELEASE_TAG`, writes `build/web/version.json`, deploys a Hosting preview channel kept for 14 days, and then deploys production Hosting (`https://belongonthespectrum.web.app`).

It does not create a GitHub Release on every commit. Releases stay on `dart run tool/deploy_release.dart --version <tag> --github-release` from a trusted machine, or a later change. App Distribution runs only when someone starts the workflow by hand with "distribute Android" enabled.

The version string for an automatic deploy is `ci-` plus the first seven characters of the commit SHA. The About screen still shows the full 40-character SHA from the dart-define.

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
| Preview channel deploy returns 403 | The service account needs Hosting admin on project `belongonthespectrum`. |
| Coverage job fails around the floor | Look at the printed `hit/found` line. Add tests or, if the suite shrank for a good reason, change `--min` in `.github/workflows/ci.yml` in a reviewed PR. |
| Format CI and your editor disagree | Both should use `dart format` with no `-l` flag until #519. |
