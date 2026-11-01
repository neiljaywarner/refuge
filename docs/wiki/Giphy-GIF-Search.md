# Giphy GIF search

Belong uses Giphy so members can attach calm, wholesome media to reflections. The experience is designed to feel **complete on the website** and **delightful on the phone** when the native apps ship.

## Official package (Android and iOS)

Phone builds use the **official Giphy Flutter SDK** from [giphy.com](https://pub.dev/publishers/giphy.com/packages) — [`giphy_flutter_sdk`](https://pub.dev/packages/giphy_flutter_sdk) on pub.dev.

As of 31 Oct 2026, pub.dev listed that package at **130 / 160 pub points** and about **115,000 downloads in the previous 30 days**. It is Giphy’s supported integration, not a third-party wrapper.

## Remote Config (all platforms)

| Parameter | Purpose | Default |
| --- | --- | --- |
| `giphy_api_key_android` | Android beta key for the official SDK (GIFs, stickers, emoji, Clips). About **100 requests/hour** for this key alone. | *(console only)* |
| `giphy_api_key_ios` | iOS beta key for the official SDK. Same hourly cap, separate pool. Device check is tracked separately; no iPhone in the current test setup. | *(console only)* |
| `giphy_api_key_web` | Web, PWA, and installed WebAPK beta key. HTTP GIF search only. Separate ~100/hour pool. | *(console only)* |
| `giphy_api_key` | **Legacy Android fallback** for builds that predate the split. Web and iOS never read this parameter. | *(console only)* |
| `giphy_content_rating` | Highest rating to request: `g`, `pg`, or `pg-13`. **`pg`** includes mild superhero-style content and excludes PG-13 and R. Invalid values, including `r`, are treated as `pg`. | `pg` |

Each dashboard key is labeled for one platform (Android, iOS, or Web SDK). The app sends **only that platform's key**. An installed PWA or WebAPK is still the website: `kIsWeb` is true, so it uses `giphy_api_key_web` and the HTTP GIF picker. It does **not** load the Android SDK, Clips, stickers, or emoji.

The app also accepts `--dart-define=GIPHY_API_KEY=...` as a **local developer fallback** when that platform's Remote Config value is empty.

### Beta key limits (what “100 per hour” means)

Giphy’s **free beta** tier caps **about 100 API requests per hour per key**. The three keys do **not** share one pool:

- **Web / PWA / WebAPK** — `giphy_api_key_web` (HTTP search and trending).
- **Android** — `giphy_api_key_android` (official SDK, including Clips).
- **iOS** — `giphy_api_key_ios` (official SDK, including Clips, when an iPhone build exists).

There is **no credit card charge** if a cap is hit — that platform's search pauses until the hour rolls over. Members can still **paste a GIF URL**.

Putting keys in Remote Config is normal for Giphy: they are **not** payment secrets. The app downloads the key for the current platform at runtime. Do not paste keys into chat, screenshots, commits, or the wiki. If traffic on one platform grows, add another key or upgrade that Giphy app — tracked in GitHub **#741**.

## Attach media sheet

Composer **Add Meme / GIF** opens one **Attach media** sheet ([#762](https://github.com/neiljaywarner/refuge/issues/762)). GIF search is the first thing on the sheet. There is no separate Search GIFs chip.

- **Web, PWA, and desktop:** the search field and trending results are visible as soon as the sheet opens. Still previews while you browse; motion starts after you attach. A tap on a trending GIF attaches it.
- **Android and iOS:** **Open Giphy** is the primary action. It opens the official SDK dialog (GIFs, stickers, emoji, clips, animated text). That dialog keeps Giphy’s own branding.
- **More:** Belong memes, paste a link, and photo (camera or gallery) sit under **More**, collapsed until someone asks for them.
- The sheet height follows the space above the keyboard so the results grid stays in the remaining area ([#761](https://github.com/neiljaywarner/refuge/issues/761)).

### Checks

Widget tests cover the sheet, attribution, and the short-phone keyboard case. Device checks stay on the **dev** package `com.belongonthespectrum.refuge.dev`:

```bash
maestro test .maestro/attach_media_giphy_flow.yaml
dart run tool/run_firebase_test_lab.dart \
  --target integration_test/patrol_ftl_attach_media_test.dart
```

The Patrol target uses an in-memory GIF double. It does not call Giphy, log a key, or publish a reflection. The Maestro flow asserts Attach media on a dev build and does not post. Native SDK tabs still come from `belongGiphySettings` / `kNativeGiphyFeatures` ([#763](https://github.com/neiljaywarner/refuge/issues/763)).

### Attribution stays where search lives

Giphy’s [API docs](https://developers.giphy.com/docs/) (Attribution) and [API Terms](https://support.giphy.com/hc/en-us/articles/360028134111-GIPHY-API-Terms-of-Service) require a conspicuous **Powered by GIPHY** mark where the API is used. Approved marks: [brand guidelines](https://support.giphy.com/hc/en-us/articles/360022283772-GIPHY-Brand-Guidelines).

- The **web/PWA picker** shows **Powered by GIPHY** on the Attach media sheet, next to search and results. That line is not moved to About.
- The **native SDK dialog** keeps its own Giphy marks. Belong does not strip them.
- **About** adds one calm line: GIF features are gratefully powered by GIPHY, and GIPHY does not endorse Belong, with a link to [giphy.com](https://giphy.com). Help on About stays Vote & Feedback ([#495](https://github.com/neiljaywarner/refuge/issues/495), [#752](https://github.com/neiljaywarner/refuge/issues/752)).

Paste-a-URL still works if search is off or you already have a link.

## Phone apps: the same sheet, more Giphy

On **Android and iOS**, **Open Giphy** on the Attach media sheet opens Giphy’s official dialog with:

| Feature | Phone (SDK) | Website (API) |
| --- | --- | --- |
| GIFs | Yes | Yes |
| Stickers | Yes | — |
| Emoji | Yes | — |
| Animated text | Yes | — |
| **Clips** (short video with sound) | Yes | — |
| Recents | Yes | — |

### What are Clips?

**Giphy Clips** are short videos — a quote, a reaction, a character moment — often with **sound in the picker**. They are the kind of content that makes Giphy feel like Slack or Instagram, not just a static image search.

Belong’s calm-tech rule for the **feed**: when you attach a Clip, the reflection stores an **https image or GIF URL**, not autoplaying audio in the sanctuary scroll. You can preview sound **while choosing** in the native picker; the shared post stays visually calm for sensitive members.

That split is intentional: the website gives you GIF search that feels finished; the phone app gives you **Clips, stickers, emoji, and animated text** — a fair reason to install from the store later and, if the experience feels good, leave a **5-star review**. We never beg for stars; we earn them by shipping something worth installing.

## Android setup (required for SDK + Clips)

- `MainActivity` must extend **`FlutterFragmentActivity`** (the Giphy dialog does not open from `FlutterActivity`).
- **`GiphyFlutterSDK.videoPlayerAdapter=exoplayeradapter@2.18.1`** in `android/gradle.properties` so Clips are not stubbed out.

iOS uses the SDK’s built-in clips player; the project deployment target already meets the SDK minimum.

## Architecture (for contributors)

- `giphy_surface.dart` — `nativeSdk` on Android/iOS, `webApi` on web/desktop.
- `giphy_remote_settings.dart` — reads Remote Config + dart-define fallback.
- `giphy_sdk_picker.dart` — configures and shows `GiphyDialog` on phones.
- `giphy_search.dart` — HTTP client for the PWA only.

See also **[Organizer Remote Config Guide](Organizer-Remote-Config-Guide)** for parameter descriptions.

## Related work

- GitHub: [#666](https://github.com/neiljaywarner/refuge/issues/666) (Giphy integration), PR [#715](https://github.com/neiljaywarner/refuge/pull/715), [#738](https://github.com/neiljaywarner/refuge/issues/738) (Clips), [#741](https://github.com/neiljaywarner/refuge/issues/741) (more keys later), [#743](https://github.com/neiljaywarner/refuge/issues/743) (iPhone SDK and Clips check — no device yet), [#762](https://github.com/neiljaywarner/refuge/issues/762) (one Attach media sheet), [#761](https://github.com/neiljaywarner/refuge/issues/761) (keyboard height).
- Store beta path: [#44](https://github.com/neiljaywarner/refuge/issues/44) (TestFlight and Play internal/closed beta before [#45](https://github.com/neiljaywarner/refuge/issues/45) / [#46](https://github.com/neiljaywarner/refuge/issues/46)).
