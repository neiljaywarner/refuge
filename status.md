# 🔖 Save for Later (`#669`) — Plan, Mini-Milestones, Results, Troubleshooting & FAQ (`status.md`)

> **Last Updated**: `2026-10-28T00:13:00-05:00`  
> **GitHub Issue**: [`neiljaywarner/refuge#669`](https://github.com/neiljaywarner/refuge/issues/669)  
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
| **M6: GitHub MCP Push, PR, CodeRabbit & Visual Proof** | Push atomic commit via GitHub MCP `push_files`, open PR closing `#669`, trigger `@coderabbitai review`, poll CodeRabbit, and post full verification audit on `#669` and the PR. | `2026-10-28 00:13:00` | `IN-PROGRESS` | `IN-PROGRESS` | PR & Issue `#669` audit comment |

---

## 4. Where We Are Right Now & Next 3 Priorities (For Any Follow-Up LLM)

### Current State
- Code, unit tests, Patrol widget tests, BDD `.txt` spec, and clean-frame Before/After screenshots are complete and verified in `.worktrees/issue-669-save-for-later-ux`.

### Next 3 Immediate Tactical Priorities (If a Lower-Cost LLM Iterates Next)
1. **Monitor & Triage CodeRabbit Review on the PR for `#669`**:
   - Use `call_mcp_tool(ServerName: 'github', ToolName: 'pull_request_read', Arguments: {method: 'get_comments', owner: 'neiljaywarner', repo: 'refuge', pullNumber: <PR>})` and `method: 'get_review_comments'`.
   - Wait until CodeRabbit finishes its review (`90–180s`), fix any blocker findings in `.worktrees/issue-669-save-for-later-ux`, and squash-merge via `merge_pull_request`.
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

---

## 7. Appendix: Verification Commands & MCP Snippets

```bash
# 1. Fetch dependencies via Dart MCP (0 prompts):
# call_mcp_tool(ServerName: 'dart', ToolName: 'pub', Arguments: {command: 'get', roots: [{root: 'file://<workspace>/.worktrees/issue-669-save-for-later-ux'}]})

# 2. Static analysis via Dart MCP (0 prompts):
# call_mcp_tool(ServerName: 'dart', ToolName: 'analyze_files', Arguments: {roots: [{root: 'file://<workspace>/.worktrees/issue-669-save-for-later-ux', paths: ['lib/src/features/reflections/', 'test/features/reflections/save_for_later_bookmarks_test.dart']}]})

# 3. Run Save for Later & Space Routing tests:
cd <workspace>/.worktrees/issue-669-save-for-later-ux
flutter test test/features/reflections/save_for_later_bookmarks_test.dart test/features/reflections/space_routing_and_isolation_test.dart
```
