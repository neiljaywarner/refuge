# Pixel 9a — Android Giphy SDK QA (best case)

**Device:** Pixel 9a (`58221JEBF20835`) · **App:** `com.belongonthespectrum.refuge.dev` (debug APK, `FLAVOR=dev`, PR #715 worktree)  
**Run:** 2026-10-31 ~2:00 PM Central · **Flow:** `.maestro/giphy_pixel9a_android_sdk_full.yaml`  
**Remote Config:** `giphy_api_key_android` + `giphy_content_rating=pg` (Firebase console only — not in git)

## TL;DR

Maestro **passed end-to-end** on physical Pixel 9a: signed-in Memes space → **Search GIFs** in-app panel → **Open Giphy** official SDK → **GIF / Sticker / Clips / Emoji** tabs captured → dismiss → second SDK open with `quiet` search. **You** validate motion and Clips audio in the MP4 below.

## Video (Neil validates)

| File | Size | What to check |
| --- | --- | --- |
| `pixel_giphy_sdk_full_walkthrough.mp4` | ~53 MB | Clips playback/sound in picker, tab transitions, SDK search typing |

Older shorter captures: `pixel_giphy_walkthrough.mp4`, `pixel_giphy_clips_walkthrough.mp4` (partial runs).

## Screenshots (agent + Neil)

| File | Agent read | Notes |
| --- | --- | --- |
| `pixel_01_home_signed_in.png` | ✅ | DEV app, feed composer visible |
| `pixel_02_memes_space.png` | ✅ | Spaces → Memes |
| `pixel_03_gallery_curated_tab.png` | ✅ | Curated tab default |
| `pixel_04_giphy_panel_trending.png` | ✅ | In-app trending + **Open Giphy (PG)** CTA |
| `pixel_05_open_giphy_cta.png` | ✅ | Same panel, CTA emphasized |
| `pixel_06_sdk_dialog_gifs_tab.png` | ✅ | Native Giphy dialog, GIF grid |
| `pixel_07_sdk_stickers_tab.png` | ✅ | Stickers tab |
| `pixel_08_sdk_clips_tab.png` | ✅ | Clips tab (still frame — motion in MP4) |
| `pixel_09_sdk_emoji_tab.png` | ✅ | Emoji tab |
| `pixel_10_after_sdk_dismiss.png` | ✅ | Back to in-app panel |
| `pixel_11_sdk_search_quiet.png` | ✅ | SDK UI after `quiet` input (optional Search tap warned) |
| `pixel_99_final_state.png` | ✅ | End state |

## Features exercised

| Feature | Surface | Verified |
| --- | --- | --- |
| Remote Config Android key | `GiphyFlutterSDK.configure` via RC | ✅ dialog loads content |
| PG rating label on CTA | In-app panel | ✅ “Open Giphy (PG)” |
| In-app HTTP trending | `GiphySearchPanel` native branch | ✅ before SDK |
| Official SDK dialog | `giphy_flutter_sdk` | ✅ |
| GIF / Sticker / Clips / Emoji tabs | `belongGiphySettings` media types | ✅ screenshots |
| SDK search | Second dialog open | ✅ `quiet` (Search tap optional/warned) |
| Feed calm attach | Not in this flow | ⏸ follow-up: pick GIF → post → feed still |

## Re-run

```bash
cd .worktrees/issue-666-giphy-search
flutter build apk --debug --dart-define=FLAVOR=dev -t lib/main_dev.dart
adb -s 58221JEBF20835 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s 58221JEBF20835 shell screenrecord --bit-rate 8000000 --time-limit 300 /sdcard/pixel_giphy_sdk_full.mp4 &
maestro --device 58221JEBF20835 test \
  -e GIPHY_QA_EMAIL=... -e 'GIPHY_QA_PASSWORD=...' \
  .maestro/giphy_pixel9a_android_sdk_full.yaml
# stop record, adb pull → qa_artifacts/giphy/
```

## FAQ

**Why dev APK not Play release?** Same native SDK path; dev flavor skips prod email wall and uses `refuge.dev` package.

**Web / iOS?** Web = HTTP search (lower priority QA). iOS = #743. Web JS picker spike = #751.

## Troubleshooting

| Issue | Fix |
| --- | --- |
| Empty SDK / key error | Confirm RC `giphy_api_key_android` on `belongonthespectrum` |
| Clips silent | ExoPlayer adapter in `gradle.properties`; watch MP4 not PNG |
| Maestro YAML parse error | `optional:` must be under `tapOn:` map, not bare shorthand |

## Appendix

- Parent issue: [#666](https://github.com/neiljaywarner/refuge/issues/666)
- Clips: [#738](https://github.com/neiljaywarner/refuge/issues/738)
- JS web spike: [#751](https://github.com/neiljaywarner/refuge/issues/751)
- PR: [#715](https://github.com/neiljaywarner/refuge/pull/715)
