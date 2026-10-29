# 🔖 Save for Later (`#669`) — Plan, Mini-Milestones, Results, Troubleshooting & FAQ (`status.md`)

> **Last Updated**: `2026-10-28T00:27:00-05:00`  
> **GitHub Issue**: [`neiljaywarner/refuge#669`](https://github.com/neiljaywarner/refuge/issues/669)  
> **GitHub Pull Request**: [`neiljaywarner/refuge#670`](https://github.com/neiljaywarner/refuge/pull/670)  
> **Isolated Worktree**: `<workspace>/.worktrees/issue-669-save-for-later-ux`  
> **Branch**: `feat/#669-save-for-later-ux`  
> **Target Files Owned (Zero Conflict with `home_screen.dart`)**:
> - `lib/src/features/reflections/domain/post.dart`
> - `lib/src/features/reflections/data/saved_posts_store.dart` *(new)*
> - `lib/src/features/reflections/data/local_post_repository.dart`
> - `lib/src/features/reflections/data/appwrite_post_repository.dart`
> - `lib/src/features/reflections/presentation/reflection_card.dart`
> - `firestore.rules`
> - `test/features/reflections/save_for_later_feature.txt` *(new BDD Gherkin spec)*
> - `test/features/reflections/save_for_later_bookmarks_test.dart`

---

## 1. TL;DR

**What was broken / missing in Save for Later (`saved_for_later`) — and what is now fixed?**
1. **Bookmarks vanished on app restart / browser refresh (`FIXED`)**:
   - Previously, `LocalPostRepository` stored `_savedPostIds` only in an in-memory `Set<String>`.
   - Now, `SavedPostsStore` (`lib/src/features/reflections/data/saved_posts_store.dart`) persists saved post IDs (`belong_saved_post_ids_v1`) and full `Post` JSON snapshots (`belong_saved_posts_cache_v1`) to `SharedPreferences` and mirrors them to `users/{uid}/saved_posts/{postId}` in Cloud Firestore when signed in.
2. **Live Cloud Posts lost their bookmark state (`FIXED`)**:
   - Previously, `preferPost(current, incoming)` overwrote `current.isSaved == true` with `incoming.isSaved == false` when Firestore or Appwrite streams emitted, and cloud-origin posts weren't cached in `_fallback`.
   - Now, `AppwritePostRepository` registers incoming cloud reflections via `_fallback.cacheExternalPosts(...)`, stamps `_fallback.isPostSaved(post.id)` on merged streams via `_applySavedState(...)`, and `preferPost` preserves `current.isSaved || incoming.isSaved`.
3. **Quiet Digest in `Saved for Later` queried the wrong source (`FIXED`)**:
   - Previously, `getQuietDigest(spaceKey: 'saved_for_later')` queried `spaceKey == 'saved_for_later'` (0 posts) instead of `getSavedPosts()`.
   - Now, `getQuietDigest(spaceKey: 'saved_for_later')` returns a warm, accurate summary of the member's saved reflections (`"Private sanctuary • N saved reflections kept for quiet, unhurried reading."`).
4. **Expected UX & Calm Surprise-and-Delight (`FIXED`)**:
   - Tapping `Key('save_post_button_${post.id}')` displays a calm floating `SnackBar` (`Key('save_for_later_snackbar_${post.id}')`) with `"🔖 Saved to your private Saved for Later space."` (or `"Removed from Saved for Later."`) and a 1-tap **`Undo`** action.
   - Saved cards display a subtle origin space badge (`Key('saved_post_origin_space_${post.id}')`, e.g. `🔖 Saved from 🙏 Prayer Sanctuary`) so members browsing `Saved for Later` always know which room a reflection came from.

---

## 2. Executive Summary & Verification Metrics

- **Dart MCP Static Analysis (`analyze_files`)**: `No errors` (0 warnings, 0 errors across `lib/src/features/reflections/` and `test/features/reflections/`).
- **Automated Unit & Patrol BDD Widget Tests**: **12 / 12 passing (`100% green`)** in `test/features/reflections/save_for_later_bookmarks_test.dart` and `test/features/reflections/space_routing_and_isolation_test.dart`.
- **Real Hardware Verification (Maestro MCP on Google Pixel)**:
  - Executed 7-step declarative Maestro flow via `call_mcp_tool(ServerName: 'maestro', ToolName: 'run')`: tapped `"Save for Later (Private)"`, opened `"Spaces"`, selected `"Saved for Later"`, verified `"Your private bookmarks sanctuary"` and the saved reflection by `"David M. (UK)"`.
  - Captured clean-frame 1080x2160 Before (`doc/screenshots/issue_669_before_feed.png`) and After (`doc/screenshots/issue_669_after_saved_for_later.png`) screenshots with status bars and nav pills stripped.

---

## 3. Mini-Milestones Table (For Fast Iteration by Any LLM Tier)

| Milestone ID & Title | Scope / Description | Start Time | End Time | Status | Proof / Verification Artifact |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **M1: Audit & Issue Creation** | Audit all Save for Later files (`post_repository.dart`, `local_post_repository.dart`, `appwrite_post_repository.dart`, `reflection_card.dart`, `home_screen.dart`), file GitHub Issue `#669`, claim row in `team_of_agents.md`, create branch `feat/#669-save-for-later-ux` & worktree `.worktrees/issue-669-save-for-later-ux`. | `2026-10-28 00:00:00` | `2026-10-28 00:02:00` | `COMPLETE` | Issue [`#669`](https://github.com/neiljaywarner/refuge/issues/669), branch `feat/#669-save-for-later-ux` |
| **M2: Domain JSON & `SavedPostsStore`** | Add `toJson()` / `Post.fromJson()` to `Post`; create `SavedPostsStore` (`SharedPreferences` + owner-only Firestore `users/{uid}/saved_posts/{postId}`) with `_safePrefs()` `runZonedGuarded` wrapper; add `saved_posts` rule in `firestore.rules`. | `2026-10-28 00:02:00` | `2026-10-28 00:05:00` | `COMPLETE` | `post.dart`, `saved_posts_store.dart`, `firestore.rules` |
| **M3: Repository Persistence & Cloud Merge Fix** | Wire `SavedPostsStore` into `LocalPostRepository`; add `isPostSaved`, `cacheExternalPosts`, and `saved_for_later` Quiet Digest; fix `AppwritePostRepository` & `preferPost` to preserve `isSaved` across cloud merges and bookmark cloud-only posts. | `2026-10-28 00:05:00` | `2026-10-28 00:06:00` | `COMPLETE` | `local_post_repository.dart`, `appwrite_post_repository.dart` |
| **M4: Calm UX Polish in `ReflectionCard`** | Add calm floating `SnackBar` with `Undo` action on bookmark toggle and origin space badge (`saved_post_origin_space_<id>`) on saved reflections. | `2026-10-28 00:06:00` | `2026-10-28 00:07:00` | `COMPLETE` | `reflection_card.dart` |
| **M5: BDD Spec, Automated Tests & Maestro Hardware Flow** | Create `test/features/reflections/save_for_later_feature.txt`, expand `test/features/reflections/save_for_later_bookmarks_test.dart`, verify `12/12` green tests & `0` analyzer warnings, and drive physical Pixel via Maestro MCP (`7/7` steps green). | `2026-10-28 00:07:00` | `2026-10-28 00:13:00` | `COMPLETE` | `12/12` tests green, `analyze_files` `No errors`, Maestro flow `success: true` |
| **M6: GitHub MCP Push, PR, CodeRabbit & Visual Proof** | Push atomic commit via GitHub MCP `push_files`, open PR `#670` closing `#669`, trigger `@coderabbitai review`, and post full verification audit on `#669` and PR `#670`. | `2026-10-28 00:13:00` | `2026-10-28 00:27:00` | `COMPLETE` | PR [`#670`](https://github.com/neiljaywarner/refuge/pull/670) & Issue [`#669`](https://github.com/neiljaywarner/refuge/issues/669#issuecomment-6461344917) audit comment |

---

## 4. Where We Are Right Now & Next 3 Priorities (For Any Follow-Up LLM)

### Current State
- Code, unit tests, Patrol widget tests, BDD `.txt` spec, and clean-frame Before/After screenshots are complete and verified in `.worktrees/issue-669-save-for-later-ux`.
- PR [`neiljaywarner/refuge#670`](https://github.com/neiljaywarner/refuge/pull/670) is open, formatted with `dart format -l 100`, and linked to Issue [`#669`](https://github.com/neiljaywarner/refuge/issues/669).

### Next 3 Immediate Tactical Priorities (If a Lower-Cost LLM Iterates Next)
1. **Monitor & Triage CodeRabbit Review on PR `#670`**:
   - Use `call_mcp_tool(ServerName: 'github', ToolName: 'pull_request_read', Arguments: {method: 'get_comments', owner: 'neiljaywarner', repo: 'refuge', pullNumber: 670})` and `method: 'get_review_comments'`.
   - Once CodeRabbit finishes its review and CI `analyze-and-test` is green, squash-merge via `merge_pull_request`.
2. **Optional Follow-Up Enhancement — Saved Count Badge in Spaces Directory**:
   - Once `lib/src/home_screen.dart` is released by other active branches in `team_of_agents.md`, watch `savedPostsStreamProvider` in the `Spaces` directory row for `saved_for_later` to show a subtle count badge (e.g., `🔖 Saved for Later (3)`) and an `"Explore Community Feed"` button in the empty state.
3. **Optional Follow-Up Enhancement — Search/Filter Inside Saved for Later**:
   - Allow filtering saved reflections by origin space (`#prayer-sanctuary`, `#special-interests`, etc.) when a member accumulates 10+ saved bookmarks.

---

## 5. FAQ (For Humans & Lower-Cost LLMs)

### Q1: Why didn't we edit `lib/src/home_screen.dart` for `#669`?
**A:** Per `team_of_agents.md`, other active worktrees (`#441`, `#632`, `#624`) have `home_screen.dart` marked as "Leave alone" to prevent merge conflicts. `home_screen.dart` *already* delegates `selectedSpace.value == 'saved_for_later'` to `activeRepository.watchSavedPosts()`, `activeRepository.getQuietDigest(spaceKey: 'saved_for_later')`, and renders `ReflectionCard` items. By implementing persistence, cloud-merge fixes, `getQuietDigest('saved_for_later')`, the `Undo` SnackBar, and the origin space badge inside `lib/src/features/reflections/`, we deliver the complete end-to-end UX with **zero merge conflicts**.

### Q2: Why are bookmarks stored in `users/{uid}/saved_posts/{postId}` instead of a boolean field on `reflections/{postId}`?
**A:** `reflections/{postId}` is a shared public document read by all fellowship members. If `isSaved` were written to `reflections/{postId}`, one member's bookmark would be visible to everyone (violating privacy) and would fail Firestore security rules (`request.auth.uid == resource.data.authorId`) whenever a member bookmarks someone else's post! Storing bookmarks in `SharedPreferences` locally + `users/{uid}/saved_posts/{postId}` in Firestore keeps bookmarks 100% private to the member across their devices.

### Q3: Why does `SavedPostsStore` store full `Post` JSON snapshots in addition to `savedPostIds`?
**A:** In `AppwritePostRepository`, `watchPosts(spaceKey: ...)` only subscribes to one space at a time (e.g. `prayer`). If a member bookmarks a post from `special_interests`, closes the app, reopens it, and goes straight to `Saved for Later`, `special_interests` hasn't been fetched yet. Caching the `Post` JSON snapshot in `SavedPostsStore` guarantees that `getSavedPosts()` and `watchSavedPosts()` immediately return every bookmarked reflection across all spaces, even offline!

---

## 6. Troubleshooting Guide

| Symptom / Error Signature | Root Cause | Diagnostic Check | Exact Fix |
| :--- | :--- | :--- | :--- |
| Bookmark icon flashes filled (`Icons.bookmark_rounded`) then reverts to outline (`Icons.bookmark_border_rounded`) in live feed | `preferPost(current, incoming)` in `appwrite_post_repository.dart` returned `incoming` from Firestore/Appwrite which had `isSaved: false`. | Check `preferPost` and `AppwritePostRepository.watchPosts` in `lib/src/features/reflections/data/appwrite_post_repository.dart`. | Stamp `isSaved: _fallback.isPostSaved(post.id)` on merged posts via `_applySavedState` in `AppwritePostRepository` and preserve `current.isSaved \|\| incoming.isSaved` in `preferPost`. |
| Bookmarking a live Firestore post does not show it in `Saved for Later` | The post existed in Firestore stream `latest`, not in `_fallback._store`, so `_fallback.toggleSavePost` couldn't find it in `_store`. | Check if `AppwritePostRepository.getPosts` / `watchPosts` calls `_fallback.cacheExternalPosts(...)`. | Call `_fallback.cacheExternalPosts(cloudPosts)` whenever Firestore or Appwrite delivers posts so `_fallback` always has the post snapshot ready to bookmark. |
| `MissingPluginException(No implementation found for method getAll on channel plugins.flutter.io/shared_preferences)` in `FakeAsync` widget tests | In `package:shared_preferences` (`shared_preferences_legacy.dart` line 88), `SharedPreferences.getInstance()` calls `completer.completeError(e, s)` and sets `_completer = null` before anyone awaits `completer.future`, leaking an uncaught error to `FakeAsync` when a widget test doesn't call `SharedPreferences.setMockInitialValues({})`. | Run `flutter test` on a widget test that constructs `LocalPostRepository` without `SharedPreferences.setMockInitialValues({})`. | Use `SavedPostsStore._safePrefs()` which wraps `SharedPreferences.getInstance()` inside `runZonedGuarded`, trapping the internal `Completer.completeError` inside the child zone and resolving cleanly to `null`. |
| `Finder "Found 0 widgets with key [<'reflection_composer_card'>]"` in widget tests | In `home_screen.dart` line 251 & 336, `isDesktop = constraints.maxWidth >= 768` and `showInlineComposer = (kIsWeb \|\| !isDesktop) && selectedSpace.value != 'saved_for_later'`. On non-web desktop viewports (`width >= 768`), the inline composer is hidden in favor of the top-bar `(+)` button. | Check `$.tester.view.physicalSize` in the widget test (`devicePixelRatio = 1.0`). | Set `$.tester.view.physicalSize = const Size(600, 1600)` (width `< 768`) when testing mobile inline composer visibility. |
| `flutter pub get` fails in sandbox with `update_engine_version.sh: engine.stamp.tmp: Operation not permitted` | Homebrew Flutter tries to write `engine.stamp` inside `/opt/homebrew/share/flutter/bin/cache/` which is outside the workspace sandbox. | Check tool output for `update_engine_version.sh`. | Use the Dart MCP tool `call_mcp_tool(ServerName: 'dart', ToolName: 'pub', Arguments: {command: 'get', roots: [{root: 'file:///...'}]})` which runs with zero terminal prompts! |
| GitHub Actions `analyze-and-test` fails on `dart format --output=none --set-exit-if-changed -l 100` | CI enforces `-l 100` (`--line-length 100`), whereas default `dart format` uses `80` or editor line width. | Run `/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart --suppress-analytics format --output=none --set-exit-if-changed -l 100 lib test`. | Format inside the sandbox with `/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart --suppress-analytics format -l 100 lib/src/features/reflections test/features/reflections`. |

---

## 7. Appendix: Complete Testing Playbook & Copy-Paste Runbook for a Lower-Cost LLM

This appendix is designed so a fast, lower-cost model (e.g., Gemini Flash / Flash-Lite, Claude Haiku, GPT-4o-mini) can take over testing, debugging, extending, or merging `#669` / PR `#670` without guessing selectors, viewport sizes, or sandbox workarounds.

### 7.1 Semantic Keys & Widget Selectors Reference Table

Never guess widget text or coordinates. Use these exact `Key(...)` and text selectors:

| UI Element | File | Exact `Key` or Text Selector | Notes |
| :--- | :--- | :--- | :--- |
| Bookmark / Save for Later button on a reflection card | `reflection_card.dart` | `Key('save_post_button_${post.id}')` | Tooltip: `'Remove from Saved for Later'` when saved, `'Save for Later (Private)'` when unsaved. |
| Floating confirmation SnackBar after tapping Save | `reflection_card.dart` | `Key('save_for_later_snackbar_${post.id}')` | Text: `'🔖 Saved to your private Saved for Later space.'` or `'Removed from Saved for Later.'` |
| SnackBar Undo button | `reflection_card.dart` | Text: `'Undo'` | Reverses the toggle via `onToggleSave!(post.id)`. |
| Origin space pill on a saved reflection card | `reflection_card.dart` | `Key('saved_post_origin_space_${post.id}')` | Text: `'🔖 Saved from ${spaceInfo.emoji} ${spaceInfo.title}'` (e.g. `'🔖 Saved from 🙏 Prayer Sanctuary'`). |
| Top sub-navigation `Spaces` tab | `home_screen.dart` | `Key('subnav_spaces_tab')` | Opens the Spaces directory sheet/view. |
| `Saved for Later` card in Spaces directory | `home_screen.dart` | Text: `'Saved for Later'` | Subtitle: `'Your private bookmarks sanctuary'`. |
| Top-right `(+)` Create Post button | `home_screen.dart` | `Key('home_top_bar_create_post_button')` | Opens popup menu with `Key('menu_item_create_post')`. |
| Inline composer card (mobile viewports `< 768px`) | `home_screen.dart` | `Key('reflection_composer_card')` | Hidden when `selectedSpace == 'saved_for_later'` or when `!kIsWeb && width >= 768`. |

---

### 7.2 Step-by-Step Verification Runbook (Zero Terminal Prompts)

#### Step 1: Fetch Dependencies via Dart MCP (`0` prompts)
Do **not** run `flutter pub get` in the shell (it fails on `/opt/homebrew/share/flutter/bin/cache/engine.stamp.tmp` inside the sandbox). Instead, call the Dart MCP tool:
```json
{
  "ServerName": "dart",
  "ToolName": "pub",
  "Arguments": {
    "command": "get",
    "roots": [
      { "root": "file://<workspace>/.worktrees/issue-669-save-for-later-ux" }
    ]
  }
}
```

#### Step 2: Check Formatting (`-l 100`) Inside the Sandbox (`0` prompts)
GitHub Actions CI runs `dart format --output=none --set-exit-if-changed -l 100 lib test tool packages/belong_lints`.
To run `dart format` inside the sandbox without triggering `update_engine_version.sh` or telemetry permission errors, invoke the Dart SDK binary directly with `--suppress-analytics`:
```bash
/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart --suppress-analytics format --output=none --set-exit-if-changed -l 100 \
  <workspace>/.worktrees/issue-669-save-for-later-ux/lib/src/features/reflections \
  <workspace>/.worktrees/issue-669-save-for-later-ux/test/features/reflections
```
- **Expected Output**: `Formatted 34 files (0 changed)` and exit code `0`.

#### Step 3: Run Static Analysis via Dart MCP (`0` prompts)
```json
{
  "ServerName": "dart",
  "ToolName": "analyze_files",
  "Arguments": {
    "roots": [
      {
        "root": "file://<workspace>/.worktrees/issue-669-save-for-later-ux",
        "paths": [
          "lib/src/features/reflections",
          "test/features/reflections/save_for_later_bookmarks_test.dart",
          "test/features/reflections/space_routing_and_isolation_test.dart"
        ]
      }
    ]
  }
}
```
- **Expected Output**: `No errors`.

#### Step 4: Run the 12 Automated Unit & Patrol Widget Tests
```bash
cd <workspace>/.worktrees/issue-669-save-for-later-ux && flutter test test/features/reflections/save_for_later_bookmarks_test.dart test/features/reflections/space_routing_and_isolation_test.dart
```
- **Expected Output**: `00:01 +12: All tests passed!`

---

### 7.3 What Each of the 12 Tests Verifies

| # | Test File | Test Name | Type | What It Verifies |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `save_for_later_bookmarks_test.dart` | `Post model equality, copyWith, and JSON serialization include isSaved (#669)` | Unit | `Post.toJson()` and `Post.fromJson()` round-trip `isSaved`, `specialInterestTag`, `reactions`, and `timestamp`. |
| 2 | `save_for_later_bookmarks_test.dart` | `SavedPostsStore & LocalPostRepository persist bookmarks across restarts (#669)` | Unit | Saving post `'1'` writes to `SharedPreferences`, returns the private Quiet Digest for `'saved_for_later'`, and a brand-new `LocalPostRepository` instance restores post `'1'` with `isSaved: true`. |
| 3 | `save_for_later_bookmarks_test.dart` | `AppwritePostRepository & preferPost preserve isSaved across cloud merges and bookmark cloud-only posts (#669)` | Unit | Cloud-only post `'cloud_77'` is cached via `cacheExternalPosts`, bookmarked via `toggleSavePost`, returned by `getSavedPosts()`, and retains `isSaved: true` on subsequent `getPosts(spaceKey: 'prayer')` cloud fetches. |
| 4 | `save_for_later_bookmarks_test.dart` | `LocalPostRepository toggles saved post and streams saved posts correctly` | Unit | Toggling save on `'1'` adds and removes it from `getSavedPosts()`. |
| 5 | `save_for_later_bookmarks_test.dart` | `Tapping bookmark ribbon toggles saved state and displays in Saved for Later space` | Patrol Widget | Tapping `Key('save_post_button_1')` shows SnackBar `'🔖 Saved to your private Saved for Later space.'`, renders `Key('saved_post_origin_space_1')` (`'🔖 Saved from 🙏 Prayer Sanctuary'`), and navigating to `Spaces` -> `Saved for Later` displays the post. |
| 6 | `save_for_later_bookmarks_test.dart` | `Tapping Undo on the Save for Later SnackBar reverses the bookmark toggle (#669)` | Patrol Widget | Tapping `'Undo'` on the SnackBar immediately removes post `'1'` from `repo.getSavedPosts()`. |
| 7 | `save_for_later_bookmarks_test.dart` | `Super easy (+) button in upper right opens Create Reflection or Image Post modal` | Patrol Widget | Tapping `Key('home_top_bar_create_post_button')` -> `Key('menu_item_create_post')` opens `'Create Reflection Post'`. |
| 8 | `save_for_later_bookmarks_test.dart` | `Composer is hidden when in Saved for Later space (#446)` | Patrol Widget | At mobile viewport `Size(600, 1600)`, `Key('reflection_composer_card')` is visible in the main feed and hidden (`findsNothing`) inside `Saved for Later`. |
| 9 | `save_for_later_bookmarks_test.dart` | `Prettier offline / test authentication view renders with calm styling` | Patrol Widget | Verifies `SimpleAuthScreen` and `Key('auth_offline_sign_in_button')`. |
| 10–12 | `space_routing_and_isolation_test.dart` | `Space Routing, Isolation & Sub-Navigation Verification (#154)` (3 tests) | Unit + Widget | Ensures `SavedPostsStore._safePrefs()` never leaks unhandled `MissingPluginException` errors into `FakeAsync` when `SharedPreferences.setMockInitialValues` is not called. |

---

### 7.4 Copy-Paste Templates for Adding New Tests

#### Template A: Adding a Unit Test for `SavedPostsStore` / `AppwritePostRepository`
```dart
test('Descriptive test name (#669)', () async {
  SharedPreferences.setMockInitialValues({});
  final fallback = LocalPostRepository(isDevMode: true);
  final repo = AppwritePostRepository(
    fallback: fallback,
    mirror: _FakeReflectionMirror([
      Post(
        id: 'cloud_99',
        authorName: 'Test Member',
        spaceKey: 'special_interests',
        toneTag: '[Special Interest]',
        content: 'Testing bookmark persistence.',
        timestamp: DateTime.utc(2026, 10, 28, 12, 0),
      ),
    ]),
    isDevMode: true,
  );

  await repo.getPosts(spaceKey: 'special_interests');
  await repo.toggleSavePost(postId: 'cloud_99');

  final saved = await repo.getSavedPosts();
  expect(saved.map((p) => p.id), contains('cloud_99'));
});
```

#### Template B: Adding a `patrolWidgetTest` UI Test
> **IMPORTANT**: Use `Size(1200, 2400)` for desktop/tablet layout tests, or `Size(600, 1600)` (width `< 768`) if your test checks `Key('reflection_composer_card')`!
```dart
patrolWidgetTest('Descriptive UI behavior test (#669)', ($) async {
  SharedPreferences.setMockInitialValues({});
  $.tester.view.devicePixelRatio = 1.0;
  $.tester.view.physicalSize = const Size(600, 1600);
  addTearDown(() {
    $.tester.view.resetPhysicalSize();
    $.tester.view.resetDevicePixelRatio();
  });

  final repo = LocalPostRepository(isDevMode: true);
  await $.pumpWidget(RefugeApp(repository: repo, homeOverride: const RefugeHomeScreen()));
  await $.pumpAndSettle();

  await $(Key('save_post_button_1')).tap();
  await $.pumpAndSettle();

  expect($(Key('saved_post_origin_space_1')), findsOneWidget);
});
```

---

### 7.5 Real Hardware Verification via Maestro MCP (`0` Prompts)

1. **Discover Connected Devices**:
   ```json
   { "ServerName": "maestro", "ToolName": "list_devices", "Arguments": {} }
   ```
   *(Look for Pixel `56091JEBF14039`, Pixel `58221JEBF20835`, or `emulator-5554` with `"connected": true`.)*

2. **Run the 7-Step Save for Later Maestro Flow**:
   ```json
   {
     "ServerName": "maestro",
     "ToolName": "run",
     "Arguments": {
       "device_id": "56091JEBF14039",
       "flow_yaml": "appId: com.belongonthespectrum.refuge.dev\n---\n- launchApp:\n    clearState: false\n- assertVisible: \"Belong on the Spectrum\"\n- tapOn:\n    text: \"Save for Later\"\n    index: 0\n- assertVisible: \"Saved\"\n- tapOn: \"Spaces\"\n- tapOn:\n    text: \"Saved for Later.*\"\n- assertVisible: \"Saved for Later\"\n"
     }
   }
   ```

3. **Capture Zero-Prompt Screenshots**:
   - **Option 1 (Maestro MCP)**:
     ```json
     {
       "ServerName": "maestro",
       "ToolName": "take_screenshot",
       "Arguments": { "device_id": "56091JEBF14039" }
     }
     ```
   - **Option 4 (Clean-Frame 1080x2160 Script — Strips Status & Nav Bars)**:
     ```bash
     <workspace>/refuge/tool/capture_device.sh screenshot /tmp/issue_669_verify.png
     ```

---

### 7.6 How to Check CI, Triage CodeRabbit, and Merge PR `#670`

1. **Check GitHub Actions Check Runs on PR `#670`**:
   ```json
   {
     "ServerName": "github",
     "ToolName": "pull_request_read",
     "Arguments": {
       "method": "get_check_runs",
       "owner": "neiljaywarner",
       "repo": "refuge",
       "pullNumber": 670
     }
   }
   ```
2. **Check CodeRabbit Comments on PR `#670`**:
   ```json
   {
     "ServerName": "github",
     "ToolName": "pull_request_read",
     "Arguments": {
       "method": "get_comments",
       "owner": "neiljaywarner",
       "repo": "refuge",
       "pullNumber": 670
     }
   }
   ```
   *(If CodeRabbit was rate-limited earlier, comment `@coderabbitai review` via `add_issue_comment` on `issue_number: 670` once the rate-limit window resets.)*
3. **Push Any Follow-Up Fixes with Zero Terminal Prompts**:
   Always use `call_mcp_tool(ServerName: 'github', ToolName: 'push_files', Arguments: {owner: 'neiljaywarner', repo: 'refuge', branch: 'feat/#669-save-for-later-ux', files: [...], message: '...'})`.
4. **Squash-Merge When Ready**:
   Once `analyze-and-test` is `success` and CodeRabbit review is complete:
   ```json
   {
     "ServerName": "github",
     "ToolName": "merge_pull_request",
     "Arguments": {
       "owner": "neiljaywarner",
       "repo": "refuge",
       "pullNumber": 670,
       "merge_method": "squash",
       "commit_title": "feat(reflections): persist Save for Later bookmarks & add calm Undo + origin space UX (#669)"
     }
   }
   ```
