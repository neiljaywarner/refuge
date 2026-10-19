# 🌙 Unattended Session: Sun Oct 18, 9:08 PM → ~1 AM (`unattended_session_908pm.md`)

> Live web: https://belongonthespectrum.web.app · Repo: https://github.com/neiljaywarner/refuge
> Companion docs: `neil_to_review_sunday_night.md` (review by milestone), `refuge/DEPLOYMENT.md` (release runbook), `refuge/docs/driving_pixels.md` (device testing), `refuge/docs/wiki/Refuge-CLI.md` (CLI)
> Last updated: **10:38 PM**

---

## TL;DR

- ✅ **Web is live** at belongonthespectrum.web.app (v0.6.0 → v0.6.1). Each release also has a preview channel and a GitHub Release with corrected, truthful notes.
- ✅ **First Android build delivered** via Firebase App Distribution to the **Pre-Alpha Testers** group (v0.2.0 build 2). Check your email for the invite.
- ✅ **Driving the real app on the Pixel 9a** with Marionette found and fixed two bugs that unit/widget tests missed: a **red-screen Riverpod crash** in debug builds and **squeezed feedback chips**.
- ✅ **First on-device integration test passed** (Feature Voting). It had never actually run before tonight.
- ⚠️ **CodeRabbit free-tier review limit reached** (about 1 review/hour). Per Neil (10:35 PM): merge after local checks pass, then request a single full-codebase review later and turn its findings into issues.
- 🧭 **Decision (10:32 PM):** use **Firestore + Firebase Auth** for the shared alpha backend now (speed), with careful migration docs toward Appwrite (ADR-0009).
- 🎯 **Next:** merge #73 / #69 / #67 → Firestore + Firebase Auth behind the existing repository seams → v0.8.0-alpha release (web + APK).

---

## Summary

### Shipped (merged to `main`)
| PR | Issue | What | Reviewed by CodeRabbit? |
|---|---|---|---|
| #60 | #56 | Deploy script, `DEPLOYMENT.md`, ADR-0009 | ❌ (old 3-second auto-merge bug; tracked in #36) |
| #61 | #52 | Feature Voting repository seam + tests | ❌ (same) |
| #62 | #26 | Stage 1 sign-in (name + email), sign out | ❌ (same) |
| #68 | #65 | Truthful release notes + Android App Distribution flag | ❌ (same) |

### Open / in progress
| PR / branch | Issue | Status |
|---|---|---|
| #67 | #66 | CLI docs + review gate. All 10 CodeRabbit findings fixed; re-review rate-limited → merge after local checks |
| #71 | #69 | Remove unused In-App Messaging (unblocks APK) + Flutter version in pubspec → merge after local checks |
| `test/#73-device-driving` | #73 | Marionette binding, integration_test, Riverpod crash fix, chip fix, `driving_pixels.md` → PR next |

### Releases
| Version | Web | Preview | GitHub Release | Android (App Distribution) |
|---|---|---|---|---|
| v0.6.0 | ✅ | ✅ | ✅ (notes corrected) | — |
| v0.6.1 | ✅ | ✅ | ✅ (notes corrected) | ✅ build 0.2.0 (2) to pre-alpha-testers |

### Issues created tonight
#56–#59 (deploy, CI/CD, release ops, `week1` audio notes), #63 (release screenshots/video/audio), #64 (privacy path scrub), #65 (Android + web together), #66 (CLI docs + gate), #69 (In-App Messaging build break), #70 (FVM), #72 (re-add In-App Messaging, v1.1), #73 (device driving). #41 (Circle CSV importer) moved to v0.9.0-rc.

### Mini-milestones
| # | Milestone | Status |
|---|---|---|
| MM-1 | Firebase project + hosting + auth for tools | ✅ |
| MM-2 | Release pipeline + issues + first web release | ✅ |
| MM-3 | Feature Voting seam + tests | ✅ (Appwrite/Firebase adapters are **stubs**) |
| MM-4 | Stage 1 sign-in | ✅ (local only) |
| MM-5 | Android SDK + first APK to testers | ✅ |
| MM-6 | Real-device driving (Marionette, integration_test) | 🔄 PR pending (#73) |
| MM-7 | Firestore + Firebase Auth shared backend | ⏳ next |
| MM-8 | Msgs / Notifications / Events (#27/#28) | ⏳ |
| MM-9 | v0.8.0-alpha release (web + APK + notes) | ⏳ |

---

## FAQ

**Is the app usable by a group yet?** Not yet. Posts, votes and sign-ins live only on each device ("Resilient" mode). The Firestore + Firebase Auth work (MM-7) makes it shared.

**Why Firestore/Firebase Auth when ADR-0009 says Appwrite?** Speed for the Oct 24 overlap. The repository seams (`AuthRepository`, `FeatureVotingRepository`, `PostRepository`) keep the later move contained. Migration notes will live in an ADR addendum + issue.

**Why was In-App Messaging removed?** It was unused, and its Android libraries didn't resolve, which broke every APK build. It's coming back properly in #72 (v1.1).

**Were all merged PRs reviewed by CodeRabbit?** No. #60, #61, #62 and #68 weren't (a CLI bug merged them after 3 seconds). The gate is fixed (#67), and those diffs are on the #36 audit list plus the upcoming full-codebase review.

**How do I install the Android build?** Accept the Firebase App Distribution email on the Pixel, then install from the link/app.

**Where are screenshots?** `scratch/screens/` in the agent artifacts for now. They'll be attached to PRs/wiki per #63; they never go into the main repo.

---

## Troubleshooting (zero-stall guide for any model)

| Symptom | Fix |
|---|---|
| `gh`/`firebase`/`git push` → 401 or prompt | Needs keychain → run that **single** command outside the sandbox. Don't chain with `&&` (breaks "always allow" matching). |
| CodeRabbit "Review limit reached" | Free OSS limit (~hourly). Merge after local `analyze_files` + `run_tests` + device check; later post `@coderabbitai full review` on one PR and turn findings into issues. |
| `refuge_cli ship-pr` exits 4 | No review yet. Expected under rate limits; use `merge-pr N` after the limit resets, or merge manually per Neil's 10:35 PM instruction. |
| Running `ship-pr` from an old worktree | That worktree may still have the old CLI. Run the CLI from up-to-date `main` (lesson from #68). |
| Red screen "Tried to read … where one of its dependencies were overridden" | Nested `ProviderScope`. There must be only one (inside `SanctuaryApp`). Fixed in #73. |
| `adb: device not found` but phone plugged in | Two adb binaries. `adb kill-server` for both; use `~/Library/Android/sdk/platform-tools/adb`. |
| APK build: `firebase-inappmessaging` not found | Fixed by #69 (remove the package). |
| `run_tests` passes but the app is broken | `run_tests` doesn't run `integration_test/` or the real `main()`. Always drive the dev build on the device (Marionette) before calling something done. |
| Marionette MCP tools not visible in the agent | Use the stdio client at `scratch/marionette_drive.dart` (`list` / `run '[...]'`), or refresh MCP servers in the UI. |
| Marionette `compaction` arg error | Omit it; valid values aren't documented in the tool list. |
| Element list shows 1 element after opening a sheet | Animation still running. Re-run `get_interactive_elements`. |

---

## Appendix A: Questions for Neil (human)

1. **Firebase Auth sign-in methods for alpha:** Email link (passwordless) + Google? Or Google only? (Recommend: Google + email link. No passwords to forget.)
2. **Who can post in alpha?** Anyone signed in, or an allowlist (pre-alpha testers only)? (Recommend: allowlist via Firestore rules until Oct 24.)
3. **Dev build header shows "Live"** on the Pixel. Is a Serverpod server running somewhere reachable from the phone, or is that a false positive? (I'll investigate either way.)
4. **CodeRabbit:** stay on the free tier (hourly limit) or upgrade for the cutover weeks?
5. **App Distribution:** add more testers to `pre-alpha-testers` now, or after v0.8.0-alpha?

## Appendix B: Questions for a more capable / expensive model

1. **Firestore data model + security rules** for Spaces/Posts/Reactions/Votes with an allowlist, written so it maps 1:1 to Appwrite Collections + Teams later. Review the rules for privilege escalation.
2. **Auth migration plan Firebase Auth → Appwrite:** keep user IDs stable? Export hashes (Firebase uses modified scrypt; does Appwrite import it)? Or force re-login with Google (simplest for neurodivergent users)?
3. **Riverpod scoping audit:** search for other nested `ProviderScope`/override hazards and providers missing `dependencies:`; add a test that boots the real `main()` widget tree in debug mode.
4. **Release signing:** the APK is debug-signed. Plan the upload key, Play App Signing, and CI secrets without leaking anything in the public repo.
5. **Full-codebase CodeRabbit triage:** when the review lands, cluster findings into ≤10 well-scoped issues with acceptance criteria.

## Appendix C: Model routing
Mechanical loops (worktree → edit → analyze → test → PR) are fine on **Gemini 3.8 Flash / Argon Medium**. Use **Claude Opus / Argon High** for Appendix B items, security rules, and migration design.
